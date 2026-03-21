import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odogo_app/models/enums.dart';
import 'package:odogo_app/views/ride_confirmed_screen.dart';
import '../controllers/auth_controller.dart';
import '../data/iitk_dropoff_locations.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';
import 'trip_confirmation_screen.dart';
import 'schedule_booking_screen.dart';
import 'location_permission_screen.dart';
import '../services/notification_permission_service.dart';
import '../controllers/trip_controller.dart';

class CommuterHomeScreen extends ConsumerStatefulWidget {
  const CommuterHomeScreen({super.key});

  @override
  ConsumerState<CommuterHomeScreen> createState() => _CommuterHomeScreenState();
}

class _CommuterHomeScreenState extends ConsumerState<CommuterHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _MapHomeView(),
    const BookingsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Kickstart the background t=0 monitor
    ref.listen(timeTickerProvider, (previous, next) {
      final now = next.value ?? DateTime.now();
      final trips = ref.read(commuterTripsProvider).value ?? [];

      for (var trip in trips) {
        if (trip.status == TripStatus.scheduled &&
            trip.driverID != null &&
            trip.scheduledTime != null) {
          if (now.isAfter(trip.scheduledTime!) ||
              now.isAtSameMomentAs(trip.scheduledTime!)) {
            ref
                .read(tripControllerProvider.notifier)
                .confirmScheduledRide(trip.tripID);
          }
        }
      }
    });

    // 2. Listen for the exact moment a trip changes status
    ref.listen(commuterTripsProvider, (previous, next) {
      final previousTrips = previous?.value ?? [];
      final nextTrips = next.value ?? [];

      if (previous?.value == null && nextTrips.isNotEmpty) {
        for (var trip in nextTrips) {
          // If Firebase says they are currently in the middle of a ride...
          if (trip.status == TripStatus.confirmed ||
              trip.status == TripStatus.ongoing) {
            // Wait 1 frame for the Home Screen to finish drawing, then teleport them!
            Future.microtask(() {
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // NOTE: Pass pickupPoint/dropoffPoint if you have them, otherwise null is fine!
                    builder: (context) =>
                        RideConfirmedScreen(tripID: trip.tripID),
                  ),
                );
              }
            });
            return; // Stop checking once we find the active ride
          }
        }
      }

      for (var newTrip in nextTrips) {
        final oldTrip = previousTrips.firstWhere(
          (t) => t.tripID == newTrip.tripID,
          orElse: () => newTrip,
        );

        // A. Scheduled Ride hits t=0
        if (oldTrip.status == TripStatus.scheduled &&
            newTrip.status == TripStatus.confirmed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your Scheduled Ride is starting NOW! The driver is on the way.',
              ),
              backgroundColor: Color(0xFF66D2A3),
            ),
          );
          NotificationService().showNotification(
            title: 'Scheduled Ride Alert',
            body:
                'Your Scheduled Ride is starting NOW!. PIN: ${newTrip.ridePIN}',
          );

          LatLng? resolvedPickup;
          LatLng? resolvedDropoff;

          try {
            // Find the matching pickup coordinate from your IITK data
            final pLoc = iitkDropoffLocations.firstWhere(
              (loc) =>
                  loc.name.toLowerCase() ==
                  newTrip.startLocName.replaceAll('Near ', '').toLowerCase(),
            );
            resolvedPickup = LatLng(pLoc.latitude, pLoc.longitude);
          } catch (_) {} // If not found, leaves it as null

          try {
            // Find the matching dropoff coordinate
            final dLoc = iitkDropoffLocations.firstWhere(
              (loc) =>
                  loc.name.toLowerCase() == newTrip.endLocName.toLowerCase(),
            );
            resolvedDropoff = LatLng(dLoc.latitude, dLoc.longitude);
          } catch (_) {} // If not found, leaves it as null

          // C. Auto-route to the Ride Confirmed screen
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RideConfirmedScreen(
                    tripID: newTrip.tripID,
                    pickupPoint: resolvedPickup,
                    dropoffPoint: resolvedDropoff,
                  ),
                ),
              );
            }
          });
        }
        // B. Immediate Ride is Accepted (Pending -> Confirmed)
        else if (oldTrip.status == TripStatus.pending &&
            newTrip.status == TripStatus.confirmed) {
          NotificationService().showNotification(
            title: 'Ride Confirmed!',
            body: 'Your driver is on the way. PIN: ${newTrip.ridePIN}',
          );
          // Auto-routing is already handled perfectly inside your WaitingForDriverScreen!
        }
        // C. Ride Officially Starts (Confirmed -> Ongoing)
        else if (oldTrip.status == TripStatus.confirmed &&
            newTrip.status == TripStatus.ongoing) {
          NotificationService().showNotification(
            title: 'Ride Started',
            body: 'Your trip has officially begun. Have a safe journey!',
          );
          // Auto-routing is already handled perfectly inside your RideConfirmedScreen!
        }
        // D. Ride Successfully Completes (Ongoing -> Completed)
        else if (oldTrip.status == TripStatus.ongoing &&
            newTrip.status == TripStatus.completed) {
          NotificationService().showNotification(
            title: 'Trip Ended',
            body: 'Thank you for riding with OdoGo!',
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_rounded),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION: The Home (Map) Tab UI
// ============================================================================
class _MapHomeView extends ConsumerStatefulWidget {
  const _MapHomeView();

  @override
  ConsumerState<_MapHomeView> createState() => _MapHomeViewState();
}

class _MapHomeViewState extends ConsumerState<_MapHomeView>
    with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  static const LatLng _defaultCenter = LatLng(26.5123, 80.2329);
  static const double _recenterThresholdMeters = 25;
  static const double _bottomOverlayInset = 20;

  LatLng? _currentLocation;
  LatLng? _lastRecenterLocation;
  StreamSubscription<Position>? _locationSubscription;
  final GlobalKey _bottomOverlayKey = GlobalKey();
  double _bottomOverlayHeight = 0;

  bool _useCurrentLocationAsPickup = true;
  DropoffLocation? _selectedPickupLocation;
  String? _customPickupName;

  bool _isShowingPermissionScreen = false;
  bool _isCheckingPermission = false;

  double get _verticalCenterOffsetPx {
    return (_bottomOverlayHeight + _bottomOverlayInset) / 2;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verifyLocationAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController.dispose();
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyLocationAccess();
    }
  }

  Future<void> _verifyLocationAccess() async {
    if (_isShowingPermissionScreen || _isCheckingPermission) return;

    _isCheckingPermission = true;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        _isShowingPermissionScreen = true;
        _locationSubscription?.cancel();

        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LocationPermissionScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );

        _isShowingPermissionScreen = false;

        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          _startLocationStream();
        }
      } else {
        _startLocationStream();
      }
    } finally {
      _isCheckingPermission = false;
    }
  }

  Future<void> _startLocationStream() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever)
      return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    _locationSubscription?.cancel();
    _locationSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) {
            _applyLocationUpdate(LatLng(position.latitude, position.longitude));
          },
          onError: (_) {},
        );
  }

  void _applyLocationUpdate(LatLng location) {
    if (!mounted) return;
    setState(() => _currentLocation = location);

    final shouldRecenter =
        _lastRecenterLocation == null ||
        Geolocator.distanceBetween(
              _lastRecenterLocation!.latitude,
              _lastRecenterLocation!.longitude,
              location.latitude,
              location.longitude,
            ) >=
            _recenterThresholdMeters;

    if (!shouldRecenter) return;

    _lastRecenterLocation = location;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(
          location,
          _mapController.camera.zoom,
          offset: Offset(0, -_verticalCenterOffsetPx),
        );
      } catch (e) {
        // Map isn't fully built yet, ignore
      }
    });
  }

  void _measureBottomOverlayHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _bottomOverlayKey.currentContext;
      if (context == null || !mounted) return;
      final renderObject = context.findRenderObject();
      if (renderObject is! RenderBox) return;
      final measuredHeight = renderObject.size.height;
      if ((measuredHeight - _bottomOverlayHeight).abs() < 1) return;
      setState(() => _bottomOverlayHeight = measuredHeight);
    });
  }

  void _openTripConfirmation({
    required String destinationName,
    DropoffLocation? dropoff,
  }) {
    final currentPickupLabel = _buildPickupLabel();
    // Clean the strings for an accurate comparison
    String cleanPickup = currentPickupLabel.toLowerCase().trim();
    // Safely remove the "near " prefix if it was added by the GPS logic
    if (cleanPickup.startsWith('near ')) {
      cleanPickup = cleanPickup.substring(5).trim();
    }
    String cleanDropoff = destinationName.toLowerCase().trim();

    // Block navigation if they are the exact same place
    if (cleanPickup == cleanDropoff) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup and Dropoff cannot be the same location.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pickupPoint = _resolvedPickupPoint();
    final dropoffPoint = dropoff == null
        ? null
        : LatLng(dropoff.latitude, dropoff.longitude);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripConfirmationScreen(
          destination: destinationName,
          pickupLabel: _buildPickupLabel(),
          pickupPoint: pickupPoint,
          dropoffPoint: dropoffPoint,
        ),
      ),
    );
  }

  LatLng? _resolvedPickupPoint() {
    if (_useCurrentLocationAsPickup) return _currentLocation;
    if (_selectedPickupLocation != null)
      return LatLng(
        _selectedPickupLocation!.latitude,
        _selectedPickupLocation!.longitude,
      );
    return _currentLocation;
  }

  DropoffLocation? _resolveDropoffLocation(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final location in iitkDropoffLocations) {
      if (location.name.toLowerCase() == normalized) return location;
    }
    for (final location in iitkDropoffLocations) {
      if (location.matches(normalized)) return location;
    }
    return null;
  }

  String _buildPickupLabel() {
    if (_customPickupName != null) return _customPickupName!;
    if (!_useCurrentLocationAsPickup && _selectedPickupLocation != null)
      return _selectedPickupLocation!.name;
    final nearest = _nearestCampusLocationName();
    return nearest == null ? 'Near your current location' : 'Near $nearest';
  }

  String? _nearestCampusLocationName() {
    final current = _currentLocation;
    if (current == null || iitkDropoffLocations.isEmpty) return null;

    DropoffLocation nearest = iitkDropoffLocations.first;
    double nearestDistance = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      nearest.latitude,
      nearest.longitude,
    );

    for (final location in iitkDropoffLocations.skip(1)) {
      final distance = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        location.latitude,
        location.longitude,
      );
      if (distance < nearestDistance) {
        nearest = location;
        nearestDistance = distance;
      }
    }
    return nearest.name;
  }

  // --- PICKUP SELECTOR ---
  Future<void> _openPickupSelector() async {
    String localSearchText = '';

    final user = ref.read(currentUserProvider);
    final homeAddress = (user?.home != null && user!.home!.isNotEmpty)
        ? user.home
        : null;
    final workAddress =
        (user?.savedLocations != null &&
            user!.savedLocations!.isNotEmpty &&
            user.savedLocations![0].isNotEmpty)
        ? user.savedLocations![0]
        : null;

    final selected = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            List<DropoffLocation> sheetFiltered = localSearchText.isEmpty
                ? iitkDropoffLocations
                : iitkDropoffLocations
                      .where(
                        (loc) =>
                            loc.name.toLowerCase().contains(
                              localSearchText.toLowerCase(),
                            ) ||
                            loc.matches(localSearchText),
                      )
                      .toList();

            bool showHome =
                homeAddress != null &&
                (localSearchText.isEmpty ||
                    'home'.contains(localSearchText.toLowerCase()) ||
                    homeAddress.toLowerCase().contains(
                      localSearchText.toLowerCase(),
                    ));
            bool showWork =
                workAddress != null &&
                (localSearchText.isEmpty ||
                    'work'.contains(localSearchText.toLowerCase()) ||
                    workAddress.toLowerCase().contains(
                      localSearchText.toLowerCase(),
                    ));

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.65,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Text(
                            'Choose Pickup Location',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: TextField(
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search campus location...',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.black54,
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                              ),
                            ),
                            onChanged: (val) {
                              setSheetState(() => localSearchText = val);
                            },
                          ),
                        ),

                        ListTile(
                          leading: const Icon(
                            Icons.my_location,
                            color: Color(0xFF66D2A3),
                          ),
                          title: const Text(
                            'Use current location',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () => Navigator.pop(sheetContext, null),
                        ),

                        if (showHome)
                          ListTile(
                            leading: const Icon(
                              Icons.home,
                              color: Colors.black54,
                            ),
                            title: const Text(
                              'Home',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              homeAddress!,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            onTap: () =>
                                Navigator.pop(sheetContext, homeAddress),
                          ),

                        if (showWork)
                          ListTile(
                            leading: const Icon(
                              Icons.work,
                              color: Colors.black54,
                            ),
                            title: const Text(
                              'Work',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              workAddress!,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            onTap: () =>
                                Navigator.pop(sheetContext, workAddress),
                          ),

                        // REMOVED custom string input tile here. Added "No Results" message.
                        if (localSearchText.isNotEmpty &&
                            sheetFiltered.isEmpty &&
                            !showHome &&
                            !showWork)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No locations found matching "$localSearchText"',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),

                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            itemCount: sheetFiltered.length,
                            itemBuilder: (context, index) {
                              final location = sheetFiltered[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.place_outlined,
                                  color: Colors.black54,
                                ),
                                title: Text(location.name),
                                onTap: () =>
                                    Navigator.pop(sheetContext, location),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;

    setState(() {
      if (selected == null) {
        _useCurrentLocationAsPickup = true;
        _selectedPickupLocation = null;
        _customPickupName = null;
      } else if (selected is String) {
        _useCurrentLocationAsPickup = false;

        final matchedLoc = _resolveDropoffLocation(selected);
        if (matchedLoc != null) {
          _selectedPickupLocation = matchedLoc;
          _customPickupName = null;
        } else {
          _selectedPickupLocation = null;
          _customPickupName = selected;
        }
      } else if (selected is DropoffLocation) {
        _useCurrentLocationAsPickup = false;
        _selectedPickupLocation = selected;
        _customPickupName = null;
      }
    });
  }

  // --- DROPOFF SELECTOR ---
  Future<void> _openDropoffSelector() async {
    String localSearchText = '';

    final user = ref.read(currentUserProvider);
    final homeAddress = (user?.home != null && user!.home!.isNotEmpty)
        ? user.home
        : null;
    final workAddress =
        (user?.savedLocations != null &&
            user!.savedLocations!.isNotEmpty &&
            user.savedLocations![0].isNotEmpty)
        ? user.savedLocations![0]
        : null;

    final selected = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            List<DropoffLocation> sheetFiltered = localSearchText.isEmpty
                ? iitkDropoffLocations
                : iitkDropoffLocations
                      .where(
                        (loc) =>
                            loc.name.toLowerCase().contains(
                              localSearchText.toLowerCase(),
                            ) ||
                            loc.matches(localSearchText),
                      )
                      .toList();

            bool showHome =
                homeAddress != null &&
                (localSearchText.isEmpty ||
                    'home'.contains(localSearchText.toLowerCase()) ||
                    homeAddress.toLowerCase().contains(
                      localSearchText.toLowerCase(),
                    ));
            bool showWork =
                workAddress != null &&
                (localSearchText.isEmpty ||
                    'work'.contains(localSearchText.toLowerCase()) ||
                    workAddress.toLowerCase().contains(
                      localSearchText.toLowerCase(),
                    ));

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.65,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Text(
                            'Choose Dropoff Location',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: TextField(
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search campus destination...',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.black54,
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                              ),
                            ),
                            onChanged: (val) {
                              setSheetState(() => localSearchText = val);
                            },
                          ),
                        ),

                        if (showHome)
                          ListTile(
                            leading: const Icon(
                              Icons.home,
                              color: Colors.black54,
                            ),
                            title: const Text(
                              'Home',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              homeAddress!,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            onTap: () =>
                                Navigator.pop(sheetContext, homeAddress),
                          ),

                        if (showWork)
                          ListTile(
                            leading: const Icon(
                              Icons.work,
                              color: Colors.black54,
                            ),
                            title: const Text(
                              'Work',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              workAddress!,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            onTap: () =>
                                Navigator.pop(sheetContext, workAddress),
                          ),

                        // REMOVED custom string input tile here. Added "No Results" message.
                        if (localSearchText.isNotEmpty &&
                            sheetFiltered.isEmpty &&
                            !showHome &&
                            !showWork)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No locations found matching "$localSearchText"',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),

                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            itemCount: sheetFiltered.length,
                            itemBuilder: (context, index) {
                              final location = sheetFiltered[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.place_outlined,
                                  color: Colors.black54,
                                ),
                                title: Text(location.name),
                                onTap: () =>
                                    Navigator.pop(sheetContext, location),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || selected == null) return;

    if (selected is String) {
      final matchedDropoff = _resolveDropoffLocation(selected);
      _openTripConfirmation(
        destinationName: matchedDropoff?.name ?? selected,
        dropoff: matchedDropoff,
      );
    } else if (selected is DropoffLocation) {
      _openTripConfirmation(destinationName: selected.name, dropoff: selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    _measureBottomOverlayHeight();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation ?? _defaultCenter,
            initialZoom: 15.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.odogo_app',
              tileBuilder: (context, tileWidget, tile) {
                return ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    -0.2126,
                    -0.7152,
                    -0.0722,
                    0,
                    255,
                    -0.2126,
                    -0.7152,
                    -0.0722,
                    0,
                    255,
                    -0.2126,
                    -0.7152,
                    -0.0722,
                    0,
                    255,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: tileWidget,
                );
              },
            ),
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF66D2A3),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.black,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/odogo_logo_black_bg.jpeg',
                  height: 50,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.local_taxi,
                    color: Colors.greenAccent,
                    size: 40,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScheduleBookingScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month, color: Colors.black),
                  label: const Text(
                    'Schedule\nbookings',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66D2A3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            key: _bottomOverlayKey,
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            width: MediaQuery.of(context).size.width * 0.92,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F6F6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location, color: Color(0xFF66D2A3)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pickup: ${_buildPickupLabel()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _openPickupSelector,
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),

                GestureDetector(
                  onTap: _openDropoffSelector,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F6F6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.redAccent),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Dropoff',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _openDropoffSelector,
                          child: const Text('Search'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

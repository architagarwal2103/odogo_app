import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data/iitk_dropoff_locations.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';
// import 'waiting_for_driver_screen.dart';
import 'trip_confirmation_screen.dart';
import 'schedule_booking_screen.dart';

class CommuterHomeScreen extends StatefulWidget {
  const CommuterHomeScreen({super.key});

  @override
  State<CommuterHomeScreen> createState() => _CommuterHomeScreenState();
}

class _CommuterHomeScreenState extends State<CommuterHomeScreen> {
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
    return Scaffold(
      backgroundColor: Colors.black,
      // This body dynamically changes based on the tab you click
      body: _pages[_selectedIndex], 
      
      // SECTION: Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_rounded), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION: The Home (Map) Tab UI
// ============================================================================
class _MapHomeView extends StatefulWidget {
  const _MapHomeView();

  @override
  State<_MapHomeView> createState() => _MapHomeViewState();
}

class _MapHomeViewState extends State<_MapHomeView> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  static const LatLng _defaultCenter = LatLng(26.5123, 80.2329);
  static const double _recenterThresholdMeters = 25;
  static const double _bottomOverlayInset = 20;
  LatLng? _currentLocation;
  LatLng? _lastRecenterLocation;
  StreamSubscription<Position>? _locationSubscription;
  final GlobalKey _bottomOverlayKey = GlobalKey();
  double _bottomOverlayHeight = 0;
  List<DropoffLocation> _filteredLocations = iitkDropoffLocations.take(8).toList();

  double get _verticalCenterOffsetPx {
    return (_bottomOverlayHeight + _bottomOverlayInset) / 2;
  }

  void _measureBottomOverlayHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _bottomOverlayKey.currentContext;
      if (context == null || !mounted) return;
      final renderObject = context.findRenderObject();
      if (renderObject is! RenderBox) return;
      final measuredHeight = renderObject.size.height;
      if ((measuredHeight - _bottomOverlayHeight).abs() < 1) return;
      setState(() {
        _bottomOverlayHeight = measuredHeight;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _startLocationStream();
  }

  Future<void> _startLocationStream() async {
    // Request permission first — before checking service, so the dialog appears.
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled || !mounted) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) {
        _applyLocationUpdate(LatLng(position.latitude, position.longitude));
      },
      onError: (_) {},
    );
  }

  void _applyLocationUpdate(LatLng location) {
    if (!mounted) return;
    setState(() {
      _currentLocation = location;
    });

    final shouldRecenter = _lastRecenterLocation == null ||
        Geolocator.distanceBetween(
              _lastRecenterLocation!.latitude,
              _lastRecenterLocation!.longitude,
              location.latitude,
              location.longitude,
            ) >=
            _recenterThresholdMeters;

    if (!shouldRecenter) {
      return;
    }

    _lastRecenterLocation = location;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final zoom = _mapController.camera.zoom;
      _mapController.move(
        location,
        zoom,
        offset: Offset(0, -_verticalCenterOffsetPx),
      );
    });
  }

  void _handleSearch(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus(); 

    final matchedDropoff = _resolveDropoffLocation(normalized);
    _openTripConfirmation(
      destinationName: normalized,
      dropoff: matchedDropoff,
    );
  }

  void _openTripConfirmation({
    required String destinationName,
    DropoffLocation? dropoff,
  }) {
    final pickupPoint = _currentLocation;
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

  DropoffLocation? _resolveDropoffLocation(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final location in iitkDropoffLocations) {
      if (location.name.toLowerCase() == normalized) {
        return location;
      }
    }

    for (final location in iitkDropoffLocations) {
      if (location.matches(normalized)) {
        return location;
      }
    }

    return null;
  }

  String _buildPickupLabel() {
    final nearest = _nearestCampusLocationName();
    if (nearest == null) {
      return 'Near your current location';
    }
    return 'Near $nearest';
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

  void _filterLocations(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredLocations = iitkDropoffLocations.take(8).toList();
      } else {
        _filteredLocations = iitkDropoffLocations
            .where((location) => location.matches(query))
            .take(8)
            .toList();
      }
    });
  }

  void _handleHistoryTap(DropoffLocation location) {
    setState(() {
      _searchController.text = location.name;
    });
    _openTripConfirmation(
      destinationName: location.name,
      dropoff: location,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _measureBottomOverlayHeight();

    return Stack(
      children: [
        // SECTION: Functional Dark Themed Map
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
              // This matrix magically inverts the map colors to make it dark mode!
              tileBuilder: (context, tileWidget, tile) {
                return ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    -0.2126, -0.7152, -0.0722, 0, 255,
                    -0.2126, -0.7152, -0.0722, 0, 255,
                    -0.2126, -0.7152, -0.0722, 0, 255,
                    0,       0,       0,       1, 0,
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
                      child: const Icon(Icons.my_location, color: Colors.black, size: 18),
                    ),
                  ),
                ],
              ),
          ],
        ),

        // SECTION: Header Logo and Schedule Button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/odogo_logo_black_bg.jpeg', 
                  height: 50,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_taxi, color: Colors.greenAccent, size: 40),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScheduleBookingScreen()),
                    );
                  },
                  icon: const Icon(Icons.calendar_month, color: Colors.black),
                  label: const Text('Schedule\nbookings', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66D2A3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ),

        // SECTION: Search & History Bottom Card
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            key: _bottomOverlayKey,
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            width: MediaQuery.of(context).size.width * 0.92,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Where to? Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: _filterLocations,
                  onSubmitted: _handleSearch,
                  decoration: InputDecoration(
                    hintText: 'Where to?',
                    hintStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black),
                    prefixIcon: const Icon(Icons.search, color: Colors.black, size: 30),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
                const SizedBox(height: 15),
                if (_filteredLocations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No matching campus location.',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView.builder(
                      itemCount: _filteredLocations.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final location = _filteredLocations[index];
                        return _buildHistoryItem(
                          Icons.place_outlined,
                          location.name,
                          onTap: () => _handleHistoryTap(location),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(IconData icon, String title, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[700]),
            const SizedBox(width: 15),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
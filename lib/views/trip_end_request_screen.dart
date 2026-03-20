import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:odogo_app/controllers/trip_controller.dart';
import 'package:odogo_app/data/iitk_dropoff_locations.dart';
import 'package:odogo_app/services/contact_launcher_service.dart';

class TripEndRequestScreen extends ConsumerStatefulWidget {
  final String tripID;

  const TripEndRequestScreen({super.key, required this.tripID});

  @override
  ConsumerState<TripEndRequestScreen> createState() => _TripEndRequestScreenState();
}

class _TripEndRequestScreenState extends ConsumerState<TripEndRequestScreen> {
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (!mounted || permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled || !mounted) return;

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final activeTripAsync = ref.watch(activeTripStreamProvider(widget.tripID));
    final trip = activeTripAsync.value;
    final driverInfoAsync = ref.watch(userInfoProvider(trip?.driverID ?? ''));
    final driverPhone = driverInfoAsync.value?.phoneNo;
    final dropoffFromTrip = trip == null ? null : DropoffLocation.fromName(trip.endLocName);
    final dropoffPoint = dropoffFromTrip == null ? null : LatLng(dropoffFromTrip.latitude, dropoffFromTrip.longitude);
    final mapCenter = _currentLocation ?? dropoffPoint;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Functional Dark Map
          if (mapCenter != null)
            FlutterMap(
              options: MapOptions(
                initialCenter: mapCenter,
                initialZoom: 16.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.odogo_app',
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
                MarkerLayer(
                  markers: [
                    if (_currentLocation != null)
                      Marker(
                        point: _currentLocation!,
                        child: const Icon(Icons.my_location, color: Color(0xFF66D2A3), size: 36),
                      ),
                    if (dropoffPoint != null)
                      Marker(
                        point: dropoffPoint,
                        child: const Icon(Icons.location_on, color: Colors.redAccent, size: 42),
                      ),
                  ],
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator(color: Color(0xFF66D2A3))),

          // 2. Synced OdoGo Logo Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF66D2A3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.electric_rickshaw, color: Colors.black, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'OdoGo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 0.5,
                      shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Confirmation Card
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'The driver has requested to end the trip',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Primary Confirmation Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(tripControllerProvider.notifier).completeRide(
                          tripID: widget.tripID,
                          isDriver: false, 
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Trip Completed! Thank you for riding with OdoGo.'),
                              backgroundColor: Color(0xFF66D2A3),
                            ),
                          );
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66D2A3),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('CONFIRM & END', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Driver Information Row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0xFF66D2A3),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                // Simply use the new name field, with a safe fallback!
                                trip?.driverName ?? '---', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                              ),
                              const Text(
                                'Vehicle Details TBA', // Placeholder until you add vehicles to DB
                                style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => ContactLauncherService.callNumber(context, driverPhone),
                          icon: const Icon(Icons.phone_outlined, color: Colors.black54),
                        ),
                        IconButton(
                          onPressed: () => ContactLauncherService.smsNumber(context, driverPhone),
                          icon: const Icon(Icons.chat_bubble_outline, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
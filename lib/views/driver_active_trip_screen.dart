import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DriverActiveTripScreen extends StatelessWidget {
  final LatLng pickupLocation;

  const DriverActiveTripScreen({
    super.key,
    this.pickupLocation = const LatLng(26.5140, 80.2340),
  });

  final Color odogoGreen = const Color(0xFF66D2A3);

  void _endTrip(BuildContext context) {
    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip Ended Successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Pop all the way back to the Home Dashboard
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Dark Map with Route to Destination
          FlutterMap(
            options: MapOptions(
              initialCenter: pickupLocation,
              initialZoom: 16.0,
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds.fromPoints([
                  pickupLocation,
                  const LatLng(26.5170, 80.2310),
                ]),
                padding: const EdgeInsets.all(28),
              ),
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
              // Route Line to OAT
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [
                      pickupLocation,
                      const LatLng(26.5150, 80.2320),
                      const LatLng(26.5170, 80.2310),
                    ],
                    color: odogoGreen,
                    strokeWidth: 5.0,
                  ),
                ],
              ),
              // Markers
              MarkerLayer(
                markers: [
                  // Driver Location (Moving along the line)
                  Marker(
                    point: const LatLng(26.5150, 80.2320),
                    width: 56, height: 56,
                    child: Container(
                      decoration: BoxDecoration(color: odogoGreen, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ClipOval(child: Image.asset('assets/images/odogo_logo_black_bg.jpeg', fit: BoxFit.contain)),
                      ),
                    ),
                  ),
                  // Drop-off Location (OAT)
                  Marker(
                    point: const LatLng(26.5170, 80.2310),
                    width: 40, height: 40,
                    child: const Icon(Icons.location_on, color: Colors.redAccent, size: 40),
                  ),
                ],
              ),
            ],
          ),

          // 2. Bottom Status Card (Matches your design exactly)
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black26, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Heading to Drop-off', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: odogoGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text('5 mins', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Drop Off Location Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.location_on, color: Colors.red, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Open Air Theatre(OAT)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('IIT Kanpur Campus', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(height: 32, thickness: 1, color: Colors.black12),
                  
                  // Passenger Detail Row
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: Colors.grey[300], child: const Icon(Icons.person, color: Colors.grey)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Arman', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
                      ),
                      IconButton(icon: Icon(Icons.phone_in_talk, color: Colors.grey[700]), onPressed: () {}),
                      IconButton(icon: Icon(Icons.chat_bubble_outline, color: Colors.grey[700]), onPressed: () {}),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // End Trip Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Fixed Syntax here!
                      ),
                      onPressed: () => _endTrip(context),
                      child: const Text('END TRIP', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TripEndRequestScreen extends StatelessWidget {
  const TripEndRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Functional Dark Map
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(26.5123, 80.2329), // Drop-off location
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
              const MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(26.5123, 80.2329),
                    child: Icon(Icons.location_on, color: Color(0xFF66D2A3), size: 45),
                  ),
                ],
              ),
            ],
          ),

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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Trip Completed! Thank you for riding with OdoGo.')),
                        );
                        Navigator.of(context).popUntil((route) => route.isFirst);
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Arman',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                              ),
                              Text(
                                'UP12WA9363',
                                style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.phone_outlined, color: Colors.black54)),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline, color: Colors.black54)),
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
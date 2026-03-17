import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'driver_active_trip_screen.dart';
import 'driver_cancel_confirmation_screen.dart'; 

class DriverActivePickupScreen extends StatefulWidget {
  const DriverActivePickupScreen({super.key});

  @override
  State<DriverActivePickupScreen> createState() => _DriverActivePickupScreenState();
}

class _DriverActivePickupScreenState extends State<DriverActivePickupScreen> {
  final Color odogoGreen = const Color(0xFF66D2A3);
  final Color etaOrange = const Color(0xFFEC5B13);
  static const LatLng _driverLocation = LatLng(26.5100, 80.2300);
  static const LatLng _fallbackPickupLocation = LatLng(26.5140, 80.2340);
  static const double _avgDriverSpeedMetersPerSecond = 4.5; // ~16.2 km/h
  LatLng _pickupLocation = _fallbackPickupLocation;

  // Focus nodes for the 4 PIN boxes
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());

  @override
  void initState() {
    super.initState();
    _setPickupFromCurrentLocation();
  }

  Future<void> _setPickupFromCurrentLocation() async {
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

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _pickupLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {
      // Keep fallback pickup point if location fetch fails.
    }
  }

  int get _etaMinutesToPickup {
    final distanceMeters = Geolocator.distanceBetween(
      _driverLocation.latitude,
      _driverLocation.longitude,
      _pickupLocation.latitude,
      _pickupLocation.longitude,
    );

    final etaMinutes = (distanceMeters / _avgDriverSpeedMetersPerSecond / 60).ceil();
    return etaMinutes < 1 ? 1 : etaMinutes;
  }

  @override
  void dispose() {
    for (var node in _focusNodes) { node.dispose(); }
    for (var controller in _controllers) { controller.dispose(); }
    super.dispose();
  }

  void _verifyPinAndStartTrip() {
    String pin = _controllers.map((c) => c.text).join();
    if (pin.length == 4) {
      // Hide the keyboard
      FocusScope.of(context).unfocus();

      // Navigate to the Active Trip Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DriverActiveTripScreen(
            pickupLocation: _pickupLocation,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 4-digit PIN.'), backgroundColor: Colors.red),
      );
    }
  }

  // --- UPDATED CANCEL TRIP LOGIC ---
  void _cancelTrip() {
    // Hide the keyboard just in case it's open
    FocusScope.of(context).unfocus();
    
    // Navigate to the confirmation screen instead of instantly canceling
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DriverCancelConfirmationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Dark Map with Route
          FlutterMap(
            options: MapOptions(
              initialCenter: _pickupLocation,
              initialZoom: 16.5,
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds.fromPoints([_driverLocation, _pickupLocation]),
                padding: const EdgeInsets.all(28),
              ),
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all, // Ensures pinch-to-zoom is active
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
              // Fake Route Line
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_driverLocation, _pickupLocation],
                    color: odogoGreen,
                    strokeWidth: 5.0,
                  ),
                ],
              ),
              // Markers
              MarkerLayer(
                markers: [
                  // Driver Location
                  Marker(
                    point: _driverLocation,
                    width: 56, height: 56,
                    child: Container(
                      decoration: BoxDecoration(color: odogoGreen, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ClipOval(child: Image.asset('assets/images/odogo_logo_black_bg.jpeg', fit: BoxFit.contain)),
                      ),
                    ),
                  ),
                  // Pickup Location
                  Marker(
                    point: _pickupLocation,
                    width: 40, height: 40,
                    child: const Icon(Icons.location_on, color: Colors.white, size: 40),
                  ),
                ],
              ),
            ],
          ),

          // 2. Custom Back Button Overlay
          Positioned(
            top: 50, left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black87,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          
          // 3. Bottom UI Card
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('You have confirmed the ride', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                          SizedBox(height: 4),
                          Text('Meet at the pickup point', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: odogoGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text('$_etaMinutesToPickup mins', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // PIN Input Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ENTER PIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(4, (index) => _buildPinBox(index)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Passenger Details Row
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: Colors.grey[300], child: const Icon(Icons.person, color: Colors.grey)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Arman', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
                            SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey),
                              Text(' Pickup Location: OAT', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                            ]),
                          ],
                        ),
                      ),
                      IconButton(icon: Icon(Icons.phone_in_talk, color: Colors.grey[700]), onPressed: () {}),
                      IconButton(icon: Icon(Icons.chat_bubble_outline, color: Colors.grey[700]), onPressed: () {}),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _cancelTrip, // Linked to our new confirmation popup!
                          child: const Text('Cancel Trip', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: odogoGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          onPressed: _verifyPinAndStartTrip,
                          child: const Text('Start Trip', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build functional PIN boxes
  Widget _buildPinBox(int index) {
    return Container(
      width: 55, height: 65,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300, width: 2)),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          inputFormatters: [LengthLimitingTextInputFormatter(1)],
          decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (index < 3) {
                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
              } else {
                FocusScope.of(context).unfocus(); // Close keyboard on last digit
              }
            } else if (value.isEmpty && index > 0) {
              FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
            }
          },
        ),
      ),
    );
  }
}
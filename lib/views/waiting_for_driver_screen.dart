import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:odogo_app/controllers/trip_controller.dart';
import 'package:odogo_app/models/enums.dart';
import 'package:odogo_app/models/trip_model.dart';
import 'commuter_home.dart';
import 'ride_confirmed_screen.dart';
import 'commuter_cancel_confirmation_screen.dart';

class WaitingForDriverScreen extends ConsumerStatefulWidget { 
  final LatLng? dropoffPoint;
  final LatLng? pickupPoint;
  final String tripID;

  const WaitingForDriverScreen({super.key, required this.tripID, this.dropoffPoint, this.pickupPoint});

  @override
  ConsumerState<WaitingForDriverScreen> createState() => _WaitingForDriverScreenState();
}

class _WaitingForDriverScreenState extends ConsumerState<WaitingForDriverScreen> {
  bool _isCancelling = false;
  
  // NEW STATE: Tracks if they are in the queue for the first time, or if they were dropped
  bool _wasDroppedByDriver = false; 

  @override
  void initState() {
    super.initState();
  }

  Future<void> _cancelRide() async {
    if (_isCancelling) return;

    // Navigate to the confirmation screen; it handles cancellation and redirection.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommuterCancelConfirmationScreen(tripID: widget.tripID),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // THE SMART LISTENER
    ref.listen<AsyncValue<TripModel?>>(
      activeTripStreamProvider(widget.tripID),
      (previous, next) {
        final trip = next.value;
        final prevTrip = previous?.value;

        if (trip == null) return;

        // SCENARIO A: Driver Accepts
        if (trip.status == TripStatus.confirmed && prevTrip?.status == TripStatus.pending) {
          // If they finally get a new driver after being dropped, reset the flag
          if (_wasDroppedByDriver) {
            setState(() => _wasDroppedByDriver = false);
          }
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RideConfirmedScreen(
                tripID: widget.tripID, 
                dropoffPoint: widget.dropoffPoint,
                pickupPoint: widget.pickupPoint,
              ),
            ),
          );
        }

        // SCENARIO B: Driver Cancels (Status drops from confirmed BACK to pending)
        if (trip.status == TripStatus.pending && prevTrip?.status == TripStatus.confirmed) {
          // NOTE: Driver cancelled the shared trip, so commuter should be sent to Home now.
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const CommuterHomeScreen()),
            (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Driver cancelled. Returning to home.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 10)]),
          onPressed: _isCancelling ? null : _cancelRide,
        ),
        title: Image.asset(
          'assets/images/odogo_logo_black_bg.jpeg', 
          height: 40,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_taxi, color: Color(0xFF66D2A3), size: 40),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.calendar_month, color: Colors.black, size: 18),
              label: const Text(
                'Schedule\nbookings', 
                style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66D2A3), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(26.5123, 80.2329), 
                    initialZoom: 16.0,
                    interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
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
                  ],
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 40.0), 
                    child: Icon(Icons.location_on, color: Color(0xFF66D2A3), size: 56),
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -5))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TRIP STATUS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                
                // --- THE UI FIX ---
                // Dynamically changes text and color so the user knows they are being re-searched!
                Text(
                  _wasDroppedByDriver ? 'DRIVER CANCELLED.\nRE-SEARCHING...' : 'WAITING FOR DRIVER', 
                  style: TextStyle(
                    fontSize: _wasDroppedByDriver ? 20 : 22, 
                    fontWeight: FontWeight.w900, 
                    color: _wasDroppedByDriver ? Colors.orange.shade800 : Colors.black87
                  )
                ),
                
                const SizedBox(height: 24),
                
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    // Changes loading bar to orange if they got dropped
                    color: _wasDroppedByDriver ? Colors.orange : const Color(0xFF66D2A3),
                  ),
                ),
                
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66D2A3).withOpacity(0.15), 
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF66D2A3).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF66D2A3)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Cancellation Policy: You can cancel at most 2 times in 15 minutes.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isCancelling ? null : _cancelRide,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isCancelling 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2))
                        : const Text('Cancel Ride', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
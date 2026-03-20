import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../controllers/trip_controller.dart';
import '../models/trip_model.dart';
import '../models/enums.dart';

const Color odoGoGreen = Color(0xFF66D2A3);
const Color appBarColor = Colors.black;
const Color scaffoldColor = Colors.white;

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  int _selectedTab = 0; // 0 = Past, 1 = Upcoming

  @override
  Widget build(BuildContext context) {
    final tripsAsyncValue = ref.watch(commuterTripsProvider);

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSegmentedControl(),
          const SizedBox(height: 16),

          Expanded(
            child: tripsAsyncValue.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: odoGoGreen),
              ),
              error: (error, stack) =>
                  Center(child: Text('Error loading bookings: $error')),
              data: (allTrips) {
                if (allTrips.isEmpty) {
                  return const Center(
                    child: Text(
                      'No bookings found.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                // STRICT FILTERING: Only show 'scheduled' in Upcoming, and 'completed' in Past
                final upcomingTrips = allTrips
                    .where((t) => t.status == TripStatus.scheduled)
                    .toList();
                final pastTrips = allTrips
                    .where((t) => t.status == TripStatus.completed)
                    .toList();

                final displayList = _selectedTab == 0
                    ? pastTrips
                    : upcomingTrips;

                displayList.sort((a, b) {
                  final timeA =
                      a.scheduledTime?.toDate() ??
                      a.eta?.toDate() ??
                      DateTime.now();
                  final timeB =
                      b.scheduledTime?.toDate() ??
                      b.eta?.toDate() ??
                      DateTime.now();
                  return timeB.compareTo(timeA); // Descending order
                });

                if (displayList.isEmpty) {
                  return Center(
                    child: Text(
                      _selectedTab == 0
                          ? 'No past bookings.'
                          : 'No upcoming bookings.',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) => CommuterBookingCard(
                    trip: displayList[index],
                    isUpcoming: _selectedTab == 1,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 80,
      backgroundColor: appBarColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/odogo_logo_black_bg.jpeg',
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.electric_rickshaw,
                color: odoGoGreen,
                size: 45,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'OdoGo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [_buildTab('Past', 0), _buildTab('Upcoming', 1)]),
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? odoGoGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// RESTORED COMMUTER UI CARD
class CommuterBookingCard extends ConsumerWidget {
  final TripModel trip;
  final bool isUpcoming;
  const CommuterBookingCard({
    super.key,
    required this.trip,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime displayDate = DateTime.now(); // Fallback
    final int? tripEpoch = int.tryParse(trip.tripID);
    if (tripEpoch != null && tripEpoch > 0) {
      displayDate = DateTime.fromMillisecondsSinceEpoch(tripEpoch);
    }

    // 2. Override with scheduledTime or ETA if they exist
    if (trip.scheduledTime != null) {
      displayDate = trip.scheduledTime!.toDate();
    } else if (trip.eta != null) {
      displayDate = trip.eta!.toDate();
    }

    // 3. Format it beautifully (No "Immediate" text anywhere)
    String formattedDate = DateFormat(
      "d MMMM, yyyy, h:mm a",
    ).format(displayDate);

    // Only fetch driver details if a driver has accepted the scheduled ride
    final driverAsync = trip.driverID != null
        ? ref.watch(userInfoProvider(trip.driverID!))
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[400]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: odoGoGreen, width: 2),
              ),
              child: Icon(
                isUpcoming
                    ? Icons.calendar_month_rounded
                    : Icons.history_rounded,
                color: odoGoGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${trip.startLocName} -> ${trip.endLocName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(height: 4),

                  // Restored Driver / Phone Display based on your exact requested string formats
                  if (trip.driverID == null)
                    const Text(
                      'Driver not found yet',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    )
                  else
                    driverAsync?.when(
                          data: (driverInfo) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Driver: ${driverInfo?.name ?? trip.driverName}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Phone No: ${driverInfo?.phoneNo ?? 'N/A'}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          loading: () => const Text(
                            'Loading driver details...',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          error: (_, __) => Text(
                            'Driver: ${trip.driverName}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ) ??
                        const SizedBox.shrink(),

                  // Ride PIN (Only needed if upcoming)
                  if (isUpcoming) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ride PIN: ${trip.ridePIN}',
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

















// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import '../controllers/auth_controller.dart';
// import '../models/trip_model.dart';
// import '../models/enums.dart'; // To access TripStatus

// // Brand colors
// const Color odoGoGreen = Color(0xFF66D2A3);
// const Color appBarColor = Colors.black;
// const Color scaffoldColor = Colors.white;

// // --- RIVERPOD STREAM PROVIDER ---
// // Fetches all trips where this specific user is the commuter, and maps them to your TripModel
// final commuterTripsProvider = StreamProvider.autoDispose<List<TripModel>>((ref) {
//   final currentUser = ref.watch(currentUserProvider);

//   if (currentUser == null) return Stream.value([]);

//   return FirebaseFirestore.instance
//       .collection('trips')
//       .where('commuterID', isEqualTo: currentUser.userID)
//       .snapshots()
//       .map((snapshot) => snapshot.docs
//           .map((doc) => TripModel.fromJson(doc.data()))
//           .toList());
// });

// class BookingsScreen extends ConsumerStatefulWidget {
//   const BookingsScreen({super.key});

//   @override
//   ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
// }

// class _BookingsScreenState extends ConsumerState<BookingsScreen> {
//   // 0 = Past, 1 = Upcoming
//   int _selectedTab = 0;

//   @override
//   Widget build(BuildContext context) {
//     // Watch the stream provider we created above
//     final tripsAsyncValue = ref.watch(commuterTripsProvider);

//     return Scaffold(
//       backgroundColor: scaffoldColor,
//       appBar: _buildAppBar(),
//       body: Column(
//         children: [
//           _buildSegmentedControl(),
//           const SizedBox(height: 16),

//           Expanded(
//             child: tripsAsyncValue.when(
//               loading: () => const Center(
//                 child: CircularProgressIndicator(color: odoGoGreen)
//               ),
//               error: (error, stack) => Center(
//                 child: Text('Error loading bookings: $error')
//               ),
//               data: (allTrips) {
//                 if (allTrips.isEmpty) {
//                   return const Center(
//                     child: Text('No bookings found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
//                   );
//                 }

//                 // --- FILTERING LOGIC ---
//                 // Sort trips into Upcoming (active) and Past (finished) based on your TripStatus enum
//                 final upcomingTrips = allTrips.where((trip) =>
//                   trip.status == TripStatus.pending ||
//                   trip.status == TripStatus.confirmed ||
//                   trip.status == TripStatus.ongoing
//                 ).toList();

//                 final pastTrips = allTrips.where((trip) =>
//                   trip.status == TripStatus.completed ||
//                   trip.status == TripStatus.cancelled
//                 ).toList();

//                 // Select the correct list based on the tab
//                 final displayList = _selectedTab == 0 ? pastTrips : upcomingTrips;

//                 // Sort the display list so the newest trips appear at the top
//                 // Fallback to eta if scheduledTime is null
//                 displayList.sort((a, b) {
//                   final timeA = a.scheduledTime?.toDate() ?? a.eta?.toDate() ?? DateTime.now();
//                   final timeB = b.scheduledTime?.toDate() ?? b.eta?.toDate() ?? DateTime.now();
//                   return timeB.compareTo(timeA); // Descending order
//                 });

//                 if (displayList.isEmpty) {
//                   return Center(
//                     child: Text(
//                       _selectedTab == 0 ? 'No past bookings.' : 'No upcoming bookings.',
//                       style: const TextStyle(color: Colors.grey, fontSize: 16)
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   itemCount: displayList.length,
//                   itemBuilder: (context, index) {
//                     return _buildBookingCard(displayList[index]);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       toolbarHeight: 80,
//       backgroundColor: appBarColor,
//       elevation: 0,
//       automaticallyImplyLeading: false,
//       title: Padding(
//         padding: const EdgeInsets.only(left: 16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image.asset(
//               'assets/images/odogo_logo_black_bg.jpeg',
//               height: 40,
//               fit: BoxFit.contain,
//               errorBuilder: (context, error, stackTrace) {
//                 return const Icon(Icons.electric_rickshaw, color: odoGoGreen, size: 45);
//               },
//             ),
//             const SizedBox(height: 3),
//             const Text(
//               'OdoGo',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//                 letterSpacing: 1.2,
//               ),
//             ),
//           ],
//         ),
//       ),
//       centerTitle: false,
//     );
//   }

//   Widget _buildSegmentedControl() {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey[900],
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           _buildTab('Past', 0),
//           _buildTab('Upcoming', 1),
//         ],
//       ),
//     );
//   }

//   Widget _buildTab(String title, int index) {
//     bool isSelected = _selectedTab == index;
//     return Expanded(
//       child: GestureDetector(
//         onTap: () {
//           setState(() {
//             _selectedTab = index;
//           });
//         },
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           decoration: BoxDecoration(
//             color: isSelected ? odoGoGreen : Colors.transparent,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Center(
//             child: Text(
//               title,
//               style: TextStyle(
//                 color: isSelected ? Colors.black : Colors.white70,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBookingCard(TripModel trip) {
//     // 1. Format the Date (Uses scheduledTime, falls back to ETA, or shows 'Immediate Ride')
//     String formattedDate = 'Immediate Ride';
//     if (trip.scheduledTime != null) {
//       formattedDate = DateFormat("d MMMM, yyyy, h:mm a").format(trip.scheduledTime!.toDate());
//     } else if (trip.eta != null) {
//       formattedDate = DateFormat("d MMMM, yyyy, h:mm a").format(trip.eta!.toDate());
//     }

//     // 2. Format Status Text (e.g., "TripStatus.completed" -> "Completed")
//     String statusText = trip.status.name.toUpperCase();

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey[400]!, width: 1),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(6),
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(color: odoGoGreen, width: 2),
//               ),
//               child: const Icon(Icons.history_rounded, color: odoGoGreen, size: 24),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Locations mapped directly from TripModel
//                   Text(
//                     '${trip.startLocName} -> ${trip.endLocName}',
//                     style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
//                   ),
//                   const SizedBox(height: 2),

//                   // Formatted Date
//                   Text(
//                     formattedDate,
//                     style: TextStyle(color: Colors.grey[700], fontSize: 14),
//                   ),
//                   const SizedBox(height: 4),

//                   // Status Badge
//                   Text(
//                     'Status: $statusText',
//                     style: TextStyle(
//                       color: trip.status == TripStatus.cancelled ? Colors.red : odoGoGreen,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14,
//                     ),
//                   ),
//                   const SizedBox(height: 4),

//                   // PIN Display (Only show for upcoming active rides)
//                   if (_selectedTab == 1 && trip.status != TripStatus.pending)
//                     Text(
//                       'Ride PIN: ${trip.ridePIN}',
//                       style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
//                     ),
//                   const SizedBox(height: 2),

//                   // NOTE: Because TripModel only holds 'driverID', we cannot display the driver's name,
//                   // phone number, or rickshaw details here yet without fetching the driver's User document.
//                   // For now, we indicate if a driver is assigned or pending.
//                   Text(
//                     'Driver: ${trip.driverName ?? 'Looking for drivers...'}',
//                     style: const TextStyle(color: Colors.black, fontSize: 14),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

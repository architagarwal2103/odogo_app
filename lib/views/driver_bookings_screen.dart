// import 'package:flutter/material.dart';

// // Defining the brand colors consistently
// const Color odoGoGreen = Color(0xFF66D2A3);
// const Color appBarColor = Colors.black;
// const Color scaffoldColor = Colors.white;

// class DriverBookingsScreen extends StatefulWidget {
//   const DriverBookingsScreen({super.key});

//   @override
//   State<DriverBookingsScreen> createState() => _DriverBookingsScreenState();
// }

// class _DriverBookingsScreenState extends State<DriverBookingsScreen> {
//   // Toggle state for booking categories (0 = Past, 1 = Upcoming)
//   int _selectedTab = 0;

//   // Placeholder data matching the driver wireframes
//   final List<DriverBookingData> _pastBookingsData = [
//     const DriverBookingData(
//       location: 'Academic Area Gate 3 -> HC',
//       dateTime: '22 January, 2026, 1:06 P.M.',
//       passengerName: 'Inesh',
//       passengerPhoneNo: '1234567890',
//       address: 'Hall 5 C308',
//     ),
//     const DriverBookingData(
//       location: 'Home -> OAT',
//       dateTime: '20 January, 2026, 6:54 P.M.',
//       passengerName: 'Arman',
//       passengerPhoneNo: '1111111111',
//       address: 'Hall 3 C132',
//     ),
//   ];

//   final List<DriverBookingData> _upcomingBookingsData = [
//     const DriverBookingData(
//       location: 'Academic Area Gate 3 -> HC',
//       dateTime: '2 February, 2026, 1:00 P.M.',
//       passengerName: 'Aiklavya',
//       passengerPhoneNo: '1234567890',
//       address: 'Hall 12 E111',
//     ),
//     const DriverBookingData(
//       location: 'Home -> OAT',
//       dateTime: '20 March, 2026, 7:00 P.M.',
//       passengerName: 'Karthic',
//       passengerPhoneNo: '1111111111',
//       address: 'Hall 12 E111',
//     ),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     // Determine the content based on the selected tab
//     List<DriverBookingData> currentBookings = _selectedTab == 0 ? _pastBookingsData : _upcomingBookingsData;

//     return Scaffold(
//       backgroundColor: scaffoldColor,
//       appBar: _buildAppBar(),
//       body: Column(
//         children: [
//           _buildSegmentedControl(),
//           const SizedBox(height: 16),
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               itemCount: currentBookings.length,
//               itemBuilder: (context, index) => _buildBookingCard(currentBookings[index]),
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

//   Widget _buildBookingCard(DriverBookingData booking) {
//     // Switch icon based on Past/Upcoming
//     IconData cardIcon = _selectedTab == 0 ? Icons.history_rounded : Icons.calendar_month_rounded;

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
//               child: Icon(cardIcon, color: odoGoGreen, size: 24),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     booking.location,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     booking.dateTime,
//                     style: TextStyle(
//                       color: Colors.grey[700],
//                       fontSize: 14,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Passenger: ${booking.passengerName}',
//                     style: const TextStyle(
//                       color: Colors.black,
//                       fontSize: 14,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     'Phone No- ${booking.passengerPhoneNo}',
//                     style: const TextStyle(
//                       color: Colors.black,
//                       fontSize: 14,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     'Address- ${booking.address}',
//                     style: const TextStyle(
//                       color: Colors.black,
//                       fontSize: 14,
//                     ),
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

// // Simple data model for a driver booking
// class DriverBookingData {
//   final String location;
//   final String dateTime;
//   final String passengerName;
//   final String passengerPhoneNo;
//   final String address;

//   const DriverBookingData({
//     required this.location,
//     required this.dateTime,
//     required this.passengerName,
//     required this.passengerPhoneNo,
//     required this.address,
//   });
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../controllers/trip_controller.dart';
import '../models/trip_model.dart';
import '../models/enums.dart';

const Color odoGoGreen = Color(0xFF66D2A3);
const Color appBarColor = Colors.black;
const Color scaffoldColor = Colors.white;

class DriverBookingsScreen extends ConsumerStatefulWidget {
  const DriverBookingsScreen({super.key});

  @override
  ConsumerState<DriverBookingsScreen> createState() =>
      _DriverBookingsScreenState();
}

class _DriverBookingsScreenState extends ConsumerState<DriverBookingsScreen> {
  int _selectedTab = 0; // 0 = Past, 1 = Upcoming

  @override
  Widget build(BuildContext context) {
    final tripsAsyncValue = ref.watch(driverTripsProvider);

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
                  Center(child: Text('Error loading bookings: $error'.replaceFirst('Exception: ', '').trim())),
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
                      a.scheduledTime ??
                      a.eta?.toDate() ??
                      DateTime.now();
                  final timeB =
                      b.scheduledTime ??
                      b.eta?.toDate() ??
                      DateTime.now();
                  return timeB.compareTo(timeA);
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
                  itemBuilder: (context, index) => DriverBookingCard(
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

// RESTORED DRIVER UI CARD
class DriverBookingCard extends ConsumerWidget {
  final TripModel trip;
  final bool isUpcoming;
  const DriverBookingCard({
    super.key,
    required this.trip,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime displayDate = DateTime.now();
    final int? tripEpoch = int.tryParse(trip.tripID);
    if (tripEpoch != null && tripEpoch > 0) {
      displayDate = DateTime.fromMillisecondsSinceEpoch(tripEpoch);
    }

    // 2. Override with scheduledTime or ETA if they exist
    if (trip.scheduledTime != null) {
      displayDate = trip.scheduledTime!;
    } else if (trip.startTime != null) {
      displayDate = trip.startTime!;
    }

    // 3. Format it beautifully
    String formattedDate = DateFormat(
      "d MMMM, yyyy, h:mm a",
    ).format(displayDate);

    final commuterAsync = ref.watch(userInfoProvider(trip.commuterID));

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

                  // Restored Driver-side string formats precisely as your original file had them
                  commuterAsync.when(
                    data: (commuterInfo) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Passenger: ${commuterInfo?.name ?? trip.commuterName}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Phone No- ${commuterInfo?.phoneNo ?? 'N/A'}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Displaying the pickup location or home as Address
                        Text(
                          'Address- ${commuterInfo?.home ?? trip.startLocName}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    loading: () => const Text(
                      'Loading passenger details...',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    error: (_, __) => Text(
                      'Passenger: ${trip.commuterName}',
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

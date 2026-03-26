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
              error: (error, stack) => Center(
                child: Text(
                  'Error loading bookings: $error'
                      .replaceFirst('Exception: ', '')
                      .trim(),
                ),
              ),
              data: (allTrips) {
                if (allTrips.isEmpty) {
                  return const Center(
                    child: Text(
                      'No bookings found.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                // Only show 'scheduled' in Upcoming, and 'completed' in Past
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
                      a.startTime ??
                      a.scheduledTime ??
                      DateTime.fromMillisecondsSinceEpoch(
                        int.tryParse(a.tripID) ?? 0,
                      );
                  final timeB =
                      b.startTime ??
                      b.scheduledTime ??
                      DateTime.fromMillisecondsSinceEpoch(
                        int.tryParse(a.tripID) ?? 0,
                      );
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

// COMMUTER UI CARD
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

    // Override with scheduledTime or ETA if they exist
    if (trip.scheduledTime != null) {
      displayDate = trip.scheduledTime!;
    } else if (trip.startTime != null) {
      displayDate = trip.startTime!;
    }

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

                  if (isUpcoming) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ride PIN: ${trip.ridePIN}',
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          // Call the commuter cancel method
                          ref
                              .read(tripControllerProvider.notifier)
                              .cancelScheduledRideByCommuter(trip);
                        },
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.red,
                          size: 20,
                        ),
                        label: const Text(
                          'Cancel Ride',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

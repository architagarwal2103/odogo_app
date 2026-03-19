// import 'package:flutter/material.dart';

// class ScheduleBookingScreen extends StatefulWidget {
//   const ScheduleBookingScreen({super.key});

//   @override
//   State<ScheduleBookingScreen> createState() => _ScheduleBookingScreenState();
// }

// class _ScheduleBookingScreenState extends State<ScheduleBookingScreen> {
//   DateTime? _selectedDate;
//   TimeOfDay? _selectedTime;

//   final TextEditingController _pickupController = TextEditingController();
//   final TextEditingController _dropoffController = TextEditingController();

//   // Functional Date Picker (Styled to OdoGo Green)
//   Future<void> _pickDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now().add(const Duration(days: 1)), // Default to tomorrow
//       firstDate: DateTime.now(), // Can't schedule in the past
//       lastDate: DateTime.now().add(const Duration(days: 30)), // Up to 30 days in advance
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Color(0xFF66D2A3), // Header background color
//               onPrimary: Colors.black, // Header text color
//               onSurface: Colors.black, // Body text color
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null) {
//       setState(() {
//         _selectedDate = picked;
//       });
//     }
//   }

//   // Functional Time Picker (Styled to OdoGo Green)
//   Future<void> _pickTime() async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Color(0xFF66D2A3),
//               onPrimary: Colors.black,
//               onSurface: Colors.black,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null) {
//       setState(() {
//         _selectedTime = picked;
//       });
//     }
//   }

//   void _confirmSchedule() {
//     if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter pickup and drop-off locations.')),
//       );
//       return;
//     }
//     if (_selectedDate == null || _selectedTime == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a date and time.')),
//       );
//       return;
//     }

//     // Success flow!
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Ride Scheduled Successfully!'),
//         backgroundColor: Color(0xFF66D2A3),
//       ),
//     );

//     // Pops back to the Home Screen
//     Navigator.pop(context);
//   }

//   @override
//   void dispose() {
//     _pickupController.dispose();
//     _dropoffController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text('Schedule a Ride', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // 1. Location Inputs (Uber/Ola style connected dots)
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[100],
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(color: Colors.grey.shade300),
//                     ),
//                     child: Column(
//                       children: [
//                         _buildLocationRow(
//                           icon: Icons.circle,
//                           iconColor: const Color(0xFF66D2A3),
//                           hint: 'Pickup Location (e.g. Hall 12)',
//                           controller: _pickupController,
//                         ),
//                         Align(
//                           alignment: Alignment.centerLeft,
//                           child: Container(
//                             // The icon is size 14, so a left margin of 6 pixels perfectly centers
//                             // this 2-pixel wide line right beneath it (6 + 1 = 7).
//                             margin: const EdgeInsets.only(left: 6, top: 4, bottom: 4),
//                             height: 24,
//                             width: 2,
//                             color: Colors.grey.shade300,
//                           ),
//                         ),
//                         _buildLocationRow(
//                           icon: Icons.square,
//                           iconColor: Colors.black,
//                           hint: 'Where to? (e.g. Academic Area)',
//                           controller: _dropoffController,
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   const Text('WHEN DO YOU WANT TO LEAVE?', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
//                   const SizedBox(height: 12),

//                   // 2. Date and Time Selectors
//                   Row(
//                     children: [
//                       Expanded(child: _buildDateTimePicker(
//                         icon: Icons.calendar_today,
//                         label: 'Date',
//                         value: _selectedDate == null
//                             ? 'Select Date'
//                             : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
//                         onTap: _pickDate,
//                       )),
//                       const SizedBox(width: 16),
//                       Expanded(child: _buildDateTimePicker(
//                         icon: Icons.access_time,
//                         label: 'Time',
//                         value: _selectedTime == null
//                             ? 'Select Time'
//                             : _selectedTime!.format(context),
//                         onTap: _pickTime,
//                       )),
//                     ],
//                   ),

//                   const SizedBox(height: 32),

//                   // 3. Info Card
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF66D2A3).withOpacity(0.15),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: const Color(0xFF66D2A3).withOpacity(0.3)),
//                     ),
//                     child: const Row(
//                       children: [
//                         Icon(Icons.info_outline, color: Color(0xFF66D2A3)),
//                         SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             'Your driver will arrive within a 5-minute window of your scheduled time.',
//                             style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // 4. Bottom Confirm Button
//           Container(
//             padding: const EdgeInsets.all(24),
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
//             ),
//             child: SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _confirmSchedule,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF66D2A3),
//                   foregroundColor: Colors.black,
//                   padding: const EdgeInsets.symmetric(vertical: 18),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   elevation: 0,
//                 ),
//                 child: const Text('Schedule Ride', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Helper Widget for Pickup/Dropoff inputs
//   Widget _buildLocationRow({required IconData icon, required Color iconColor, required String hint, required TextEditingController controller}) {
//     return Row(
//       children: [
//         Icon(icon, color: iconColor, size: 14),
//         const SizedBox(width: 16),
//         Expanded(
//           child: TextField(
//             controller: controller,
//             decoration: InputDecoration(
//               hintText: hint,
//               hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
//               border: InputBorder.none,
//               isDense: true,
//               contentPadding: EdgeInsets.zero,
//             ),
//             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//           ),
//         ),
//       ],
//     );
//   }

//   // Helper Widget for Date/Time picker buttons
//   Widget _buildDateTimePicker({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.grey.shade300),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(icon, size: 16, color: Colors.grey),
//                 const SizedBox(width: 8),
//                 Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../controllers/auth_controller.dart';
import '../controllers/trip_controller.dart';
import '../models/enums.dart';
import '../models/trip_model.dart';

class ScheduleBookingScreen extends ConsumerStatefulWidget {
  const ScheduleBookingScreen({super.key});

  @override
  ConsumerState<ScheduleBookingScreen> createState() =>
      _ScheduleBookingScreenState();
}

class _ScheduleBookingScreenState extends ConsumerState<ScheduleBookingScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();

  // Functional Date Picker (Styled to OdoGo Green)
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(
        const Duration(days: 1),
      ), // Default to tomorrow
      firstDate: DateTime.now(), // Can't schedule in the past
      lastDate: DateTime.now().add(
        const Duration(days: 30),
      ), // Up to 30 days in advance
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF66D2A3), // Header background color
              onPrimary: Colors.black, // Header text color
              onSurface: Colors.black, // Body text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Functional Time Picker (Styled to OdoGo Green)
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF66D2A3),
              onPrimary: Colors.black,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Backend-wired confirmation method
  Future<void> _confirmSchedule() async {
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter pickup and drop-off locations.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date and time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    // 1. Combine Date and Time into a single DateTime object
    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // 2. Generate a 4-digit Ride PIN for the commuter
    final String ridePin = (Random().nextInt(9000) + 1000).toString();

    // 3. Construct the Scheduled Trip Model
    final newTrip = TripModel(
      tripID: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
      status: TripStatus
          .scheduled, // Saves as 'scheduled' so it stays hidden until the broadcast window
      commuterID: user.userID,
      startLocName: _pickupController.text.trim(),
      endLocName: _dropoffController.text.trim(),
      ridePIN: ridePin,
      driverEnd: false,
      commuterEnd: false,
      scheduledTime: Timestamp.fromDate(scheduledDateTime),
    );

    // 4. Send to Firestore via the Controller
    await ref.read(tripControllerProvider.notifier).scheduleRide(newTrip);

    if (!mounted) return;
    setState(() => _isLoading = false);

    // 5. Handle success or error
    final tripState = ref.read(tripControllerProvider);
    if (tripState is AsyncError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${tripState.error}'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride Scheduled Successfully!'),
          backgroundColor: Color(0xFF66D2A3),
        ),
      );
      Navigator.pop(context); // Return to home screen
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Schedule a Ride',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Location Inputs (Uber/Ola style connected dots)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        _buildLocationRow(
                          icon: Icons.circle,
                          iconColor: const Color(0xFF66D2A3),
                          hint: 'Pickup Location (e.g. Hall 12)',
                          controller: _pickupController,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(
                              left: 6,
                              top: 4,
                              bottom: 4,
                            ),
                            height: 24,
                            width: 2,
                            color: Colors.grey.shade300,
                          ),
                        ),
                        _buildLocationRow(
                          icon: Icons.square,
                          iconColor: Colors.black,
                          hint: 'Where to? (e.g. Academic Area)',
                          controller: _dropoffController,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'WHEN DO YOU WANT TO LEAVE?',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Date and Time Selectors
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimePicker(
                          icon: Icons.calendar_today,
                          label: 'Date',
                          value: _selectedDate == null
                              ? 'Select Date'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateTimePicker(
                          icon: Icons.access_time,
                          label: 'Time',
                          value: _selectedTime == null
                              ? 'Select Time'
                              : _selectedTime!.format(context),
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 3. Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF66D2A3).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF66D2A3).withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF66D2A3)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your driver will arrive within a 5-minute window of your scheduled time.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Bottom Confirm Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF66D2A3),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Schedule Ride',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget for Pickup/Dropoff inputs
  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String hint,
    required TextEditingController controller,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 14),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }

  // Helper Widget for Date/Time picker buttons
  Widget _buildDateTimePicker({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

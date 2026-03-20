// import 'package:flutter/material.dart';

// class EditDateOfBirthScreen extends StatefulWidget {
//   const EditDateOfBirthScreen({super.key});

//   @override
//   State<EditDateOfBirthScreen> createState() => _EditDateOfBirthScreenState();
// }

// class _EditDateOfBirthScreenState extends State<EditDateOfBirthScreen> {
//   // Controller to display the selected date
//   final TextEditingController _dobController = TextEditingController();

//   @override
//   void dispose() {
//     _dobController.dispose();
//     super.dispose();
//   }

//   // Function to pop up the native calendar picker
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime(2000, 1, 1), // Default starting point
//       firstDate: DateTime(1900), // Earliest possible birth year
//       lastDate: DateTime.now(), // Cannot be born in the future
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Color(0xFF66D2A3), // OdoGo Green highlights
//               onPrimary: Colors.black, // Text on the green header
//               onSurface: Colors.black, // Standard text color
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null) {
//       setState(() {
//         // Formats the selected date to DD/MM/YYYY
//         _dobController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
//       });
//     }
//   }

//   void _saveDateOfBirth() {
//     print("Saving DOB: ${_dobController.text}");

//     // Show a quick success popup
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Date of birth updated successfully!'),
//         backgroundColor: Colors.green,
//       ),
//     );

//     // Return to the Profile Page
//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         // The essential Back Button
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text('Inesh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         actions: const [
//           Padding(
//             padding: EdgeInsets.only(right: 16.0),
//             child: CircleAvatar(
//               radius: 16,
//               backgroundColor: Color(0xFF66D2A3),
//               child: Icon(Icons.person, color: Colors.white, size: 20),
//             ),
//           )
//         ],
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(Icons.cake, color: Colors.grey[800], size: 32),
//                   const SizedBox(width: 12),
//                   const Text('Date of Birth', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//                 ],
//               ),
//               const SizedBox(height: 32),
//               TextField(
//                 controller: _dobController,
//                 readOnly: true, // Prevents the keyboard from popping up
//                 onTap: () => _selectDate(context), // Triggers the calendar instead
//                 decoration: InputDecoration(
//                   hintText: 'DD/MM/YYYY',
//                   filled: true,
//                   fillColor: Colors.grey[200],
//                   suffixIcon: const Icon(Icons.calendar_today, color: Colors.black54),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide.none,
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                 ),
//                 style: const TextStyle(fontSize: 18),
//               ),
//               const Spacer(), // Pushes the button to the bottom
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF333333),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                   onPressed: _saveDateOfBirth,
//                   child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added
import '../controllers/auth_controller.dart'; // Added
import '../controllers/user_controller.dart'; // Added

class EditDateOfBirthScreen extends ConsumerStatefulWidget {
  // Changed
  const EditDateOfBirthScreen({super.key});

  @override
  ConsumerState<EditDateOfBirthScreen> createState() =>
      _EditDateOfBirthScreenState();
}

class _EditDateOfBirthScreenState extends ConsumerState<EditDateOfBirthScreen> {
  final TextEditingController _dobController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // PRE-FILL EXISTING DOB
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _selectedDate = user.dob.toDate();
      _dobController.text =
          "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}";
    }
  }

  @override
  void dispose() {
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF66D2A3),
            onPrimary: Colors.black,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _saveDateOfBirth() async {
    if (_selectedDate == null) return;

    setState(() => _isLoading = true);

    // SAVE TO DATABASE
    await ref.read(userControllerProvider.notifier).updateDoB(_selectedDate!);

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Date of birth updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider); // To show name in AppBar

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          user?.name ?? 'Profile',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cake, color: Colors.grey[800], size: 32),
                  const SizedBox(width: 12),
                  const Text(
                    'Date of Birth',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _dobController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: InputDecoration(
                  hintText: 'DD/MM/YYYY',
                  filled: true,
                  fillColor: Colors.grey[200],
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    color: Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: const TextStyle(fontSize: 18),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _saveDateOfBirth,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

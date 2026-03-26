// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // REQUIRED for input formatters
// import 'profile_otp_verification_screen.dart'; // <-- ADDED THE OTP IMPORT

// class PhoneNumberEditScreen extends StatefulWidget {
//   const PhoneNumberEditScreen({super.key});

//   @override
//   State<PhoneNumberEditScreen> createState() => _PhoneNumberEditScreenState();
// }

// class _PhoneNumberEditScreenState extends State<PhoneNumberEditScreen> {
//   // Controller to capture the typed phone number
//   final TextEditingController _phoneController = TextEditingController();

//   @override
//   void dispose() {
//     _phoneController.dispose();
//     super.dispose();
//   }

//   // --- CHANGED FROM _savePhoneNumber TO _sendOtp ---
//   void _sendOtp() {
//     final phoneInput = _phoneController.text;

//     // Strict Validation: Must be exactly 10 digits
//     if (phoneInput.length != 10) {
//       // Show an error popup
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please enter exactly 10 digits.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return; // Stop the function here so it doesn't navigate
//     }

//     // Hide the keyboard
//     FocusScope.of(context).unfocus();

//     // Push to the OTP screen and pass the entered phone number with the +91!
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ProfileOtpVerificationScreen(
//           contactInfo: '+91 $phoneInput',
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         // The essential Back Button!
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text('Inesh', style: TextStyle(color: Colors.white)),
//         actions: const [
//           Padding(
//             padding: EdgeInsets.only(right: 16.0),
//             child: CircleAvatar(
//               radius: 16,
//               backgroundColor: Color(0xFF66D2A3), // OdoGo Green
//               child: Icon(Icons.person, color: Colors.white, size: 20),
//             ),
//           )
//         ],
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Main Content
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.smartphone, size: 64, color: Colors.black),
//                     const SizedBox(height: 16),
//                     Text('Phone Number', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
//                     const SizedBox(height: 32),

//                     // Upgraded TextField
//                     TextField(
//                       controller: _phoneController,
//                       keyboardType: TextInputType.phone,
//                       maxLength: 10, // Hard limit to 10 characters
//                       inputFormatters: [
//                         FilteringTextInputFormatter.digitsOnly, // Blocks letters and symbols
//                       ],
//                       decoration: InputDecoration(
//                         filled: true,
//                         fillColor: Colors.grey[100],
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
//                         hintText: 'Enter phone number',
//                         prefixText: '+91 ', // Automatically adds the country code visually
//                         prefixStyle: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
//                         counterText: "", // Hides the '0/10' character counter for a cleaner look
//                       ),
//                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
//                     ),

//                     const SizedBox(height: 48),
//                     ElevatedButton(
//                       onPressed: _sendOtp, // <-- CALLS THE NEW OTP FUNCTION
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF333333),
//                         minimumSize: const Size.fromHeight(56),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       ),
//                       child: const Text('Send OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), // <-- CHANGED TEXT
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odogo_app/controllers/auth_controller.dart';
import 'profile_otp_verification_screen.dart';

class PhoneNumberEditScreen extends ConsumerStatefulWidget {
  const PhoneNumberEditScreen({super.key});

  @override
  ConsumerState<PhoneNumberEditScreen> createState() =>
      _PhoneNumberEditScreenState();
}

class _PhoneNumberEditScreenState extends ConsumerState<PhoneNumberEditScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill the controller with the user's current phone number
    final user = ref.read(currentUserProvider);
    if (user != null) {
      // Safely strip '+91' if it somehow got saved in the DB, to prevent UI duplication
      _phoneController.text = user.phoneNo.replaceAll('+91', '').trim();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    final phoneInput = _phoneController.text;

    if (phoneInput.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter exactly 10 digits.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    // Route to OTP screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProfileOtpVerificationScreen(contactInfo: '+91 $phoneInput'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the current user for the AppBar name
    final user = ref.watch(currentUserProvider);

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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF66D2A3),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.smartphone, size: 64, color: Colors.black),
                    const SizedBox(height: 16),
                    Text(
                      'Phone Number',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Enter phone number',
                        prefixText: '+91 ',
                        prefixStyle: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        counterText: "",
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF333333),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Verify Phone Number',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for Timestamp!
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../models/enums.dart';

class SignUpPage extends ConsumerStatefulWidget {
  final bool isDriver;

  const SignUpPage({super.key, required this.isDriver});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _handleContinue() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter your full name.');
      return;
    }

    final nameRegex = RegExp(r"^[a-zA-Z\s]+$");
    if (!nameRegex.hasMatch(name)) {
      _showError('Name can only contain letters and spaces.');
      return;
    }

    if (name.length < 2) {
      _showError('Name is too short.');
      return;
    }

    if (phone.isEmpty) {
      _showError('Please enter your phone number.');
      return;
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      _showError('Please enter a valid 10-digit phone number.');
      return;
    }

    if (_selectedGender == null) {
      _showError('Please select your gender.');
      return;
    }

    if (_selectedDate == null) {
      _showError('Please select your date of birth.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 1. Grab the email from the current Auth State
    final authState = ref.read(authControllerProvider);
    if (authState is! AuthNeedsProfileSetup) {
      _showError("Authentication state error. Please try logging in again.");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final userEmail = authState.email;

    // 2. Construct your exact UserModel
    final newUser = UserModel(
      userID: userEmail, // Using email as the unique ID
      emailID: userEmail,
      phoneNo: phone,
      gender: _selectedGender!,
      // Convert Flutter DateTime to Firebase Timestamp
      dob: Timestamp.fromDate(_selectedDate!),
      role: widget.isDriver ? UserRole.driver : UserRole.commuter,

      // If it's a driver, default them to unverified initially
      verificationStatus: widget.isDriver ? false : null,
      name: name,
      // Automatically sets new drivers to offline, and leaves commuters as null
      mode: widget.isDriver ? DriverMode.offline : null,
    );

    // 3. Save to Firebase and update Riverpod State!
    await ref
        .read(authControllerProvider.notifier)
        .completeProfileSetup(newUser);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    // 4. Check if it worked
    final newState = ref.read(authControllerProvider);
    if (newState is AuthError) {
      _showError(newState.message);
    } else {
      // SUCCESS!
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Welcome to OdoGo.'),
          backgroundColor: Color(0xFF66D2A3),
        ),
      );

      // --- DRIVER ROUTING EDGE CASE ---
      // If they are a driver, GoRouter is going to instantly teleport them to '/driver-home'
      // because the state is now AuthAuthenticated.
      // If you want them to upload docs FIRST, you should push them to that screen here,
      // OR better yet, let them go to the driver home screen and pop up a "Please upload docs"
      // modal based on their `verificationStatus == false`.
      // if (widget.isDriver) {
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //       builder: (context) => const DriverDocumentUploadScreen(),
      //     ),
      //   );
      // }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          // Logs out and kicks them to the login screen
          onPressed: () =>
              ref.read(authControllerProvider.notifier).abortSignup(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/images/odogo_logo.png', height: 80),
              ),
              const SizedBox(height: 10),
              const Text(
                'OdoGo',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                widget.isDriver
                    ? 'Driver Registration'
                    : 'Commuter Registration',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Enter Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: 'Enter Phone Number',
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: 'Gender',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                ),
                initialValue: _selectedGender,
                items: ['Male', 'Female', 'Other', 'Prefer not to say']
                    .map(
                      (label) =>
                          DropdownMenuItem(value: label, child: Text(label)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedGender = value),
              ),
              const SizedBox(height: 15),

              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Date of Birth'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDate == null
                              ? Colors.black54
                              : Colors.black87,
                        ),
                      ),
                      const Icon(Icons.calendar_month, color: Colors.black54),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

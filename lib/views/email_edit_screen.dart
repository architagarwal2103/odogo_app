import 'package:flutter/material.dart';
import '../services/email_link_auth_service.dart';
import 'profile_otp_verification_screen.dart';

class EmailEditScreen extends StatefulWidget {
  const EmailEditScreen({super.key});

  @override
  State<EmailEditScreen> createState() => _EmailEditScreenState();
}

class _EmailEditScreenState extends State<EmailEditScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSendingOtp = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Helper function to keep the validation logic clean
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _saveEmail() async {
    final email = _controller.text.trim();

    // 1. Check if empty
    if (email.isEmpty) {
      _showError('Please enter an email address.');
      return;
    }

    // 2. Check for accidental spaces
    if (email.contains(' ')) {
      _showError('Email cannot contain spaces.');
      return;
    }

    // 3. Check for the @ symbol
    if (!email.contains('@')) {
      _showError('Email must contain an "@" symbol.');
      return;
    }

    // 4. Strict check for allowed domains
    if (!email.endsWith('.com') && !email.endsWith('.ac.in')) {
      _showError('Email must end with .com or .ac.in');
      return;
    }

    // 5. Final Regex check to ensure the prefix and domain format are structurally valid
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(com|ac\.in)$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email format.');
      return;
    }

    // If it passes all checks, hide the keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isSendingOtp = true;
    });

    try {
      await EmailOtpAuthService.instance.sendOtp(email: email);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      _showError(message.isEmpty ? 'Could not send OTP. Please try again.' : message);
      setState(() {
        _isSendingOtp = false;
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSendingOtp = false;
    });

    // Push to the OTP screen and pass the securely validated email!
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileOtpVerificationScreen(
          contactInfo: email,
          verificationEmail: email,
        ),
      ),
    );
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
        title: const Text('Inesh', style: TextStyle(color: Colors.white)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF66D2A3), // OdoGo Green
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.email_outlined, size: 40, color: Colors.black87),
                  SizedBox(width: 12),
                  Text(
                    'Email', 
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.emailAddress, 
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  hintText: 'email@example.com',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                ),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: _isSendingOtp ? null : _saveEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isSendingOtp ? 'Sending OTP...' : 'Send OTP',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
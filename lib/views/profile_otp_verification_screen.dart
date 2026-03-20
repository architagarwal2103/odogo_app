import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/email_link_auth_service.dart';

class ProfileOtpVerificationScreen extends StatefulWidget {
  final String contactInfo; // This will hold the new email or phone number
  final String? verificationEmail;

  const ProfileOtpVerificationScreen({
    super.key,
    required this.contactInfo,
    this.verificationEmail,
  });

  @override
  State<ProfileOtpVerificationScreen> createState() => _ProfileOtpVerificationScreenState();
}

class _ProfileOtpVerificationScreenState extends State<ProfileOtpVerificationScreen> {
  final Color odogoGreen = const Color(0xFF66D2A3);
  static const bool _bypassOtpFromEnv = bool.fromEnvironment('BYPASS_OTP', defaultValue: false);
  static const String _debugBypassCode = '0000';
  bool _isLoading = false;

  bool get _isOtpBypassEnabled => !kReleaseMode && _bypassOtpFromEnv;

  // Focus nodes and controllers for the 4 PIN boxes
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());

  @override
  void dispose() {
    for (var node in _focusNodes) { node.dispose(); }
    for (var controller in _controllers) { controller.dispose(); }
    super.dispose();
  }

  Future<void> _verifyAndSave() async {
    String otp = _controllers.map((c) => c.text).join();

    if (otp.length != 4 || !RegExp(r'^[0-9]{4}$').hasMatch(otp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 4-digit code.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (widget.verificationEmail != null) {
      setState(() {
        _isLoading = true;
      });

      final verified = EmailOtpAuthService.instance.verifyOtp(
        email: widget.verificationEmail!,
        otp: otp,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (!verified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid or expired OTP. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      if (_isOtpBypassEnabled && otp != _debugBypassCode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP for test mode. Use 0000.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    FocusScope.of(context).unfocus(); // Hide keyboard

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification successful! Profile updated.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Pop twice: First closes this OTP screen, Second closes the Edit screen
    // This drops them perfectly back onto the main Profile tab!
    Navigator.of(context)..pop()..pop();
  }

  Future<void> _resendOtp() async {
    if (widget.verificationEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('New code sent!'), backgroundColor: odogoGreen),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await EmailOtpAuthService.instance.sendOtp(email: widget.verificationEmail!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('New OTP sent!'), backgroundColor: odogoGreen),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.isEmpty ? 'Could not resend OTP. Please try again.' : message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        title: const Text('Verification', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        // 1. ADD THIS WRAPPER
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Enter Verification Code',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Text(
                  'We have sent a 4-digit code to:\n${widget.contactInfo}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 40),

                // The 4-Digit OTP Input Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) => _buildOtpBox(index)),
                ),
                
                const SizedBox(height: 40),

                // Verify Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, 
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isLoading ? 'Please wait...' : 'Verify & Save',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                
                const SizedBox(height: 24),

                if (_isOtpBypassEnabled)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Test mode: use OTP 0000',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                
                // Resend Code Option
                Center(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _resendOtp,
                    child: Text(
                      'Didn\'t receive a code? Resend',
                      style: TextStyle(color: odogoGreen, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // The premium auto-shifting PIN box UI
  Widget _buildOtpBox(int index) {
    return Container(
      width: 65, 
      height: 75,
      decoration: BoxDecoration(
        color: Colors.grey[100], 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Colors.grey.shade300, width: 2)
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed to wipe the database
import '../controllers/auth_controller.dart';
import '../services/email_link_auth_service.dart';

class AccountDeletionOtpScreen extends ConsumerStatefulWidget {
  final String contactInfo;

  const AccountDeletionOtpScreen({super.key, required this.contactInfo});

  @override
  ConsumerState<AccountDeletionOtpScreen> createState() =>
      _AccountDeletionOtpScreenState();
}

class _AccountDeletionOtpScreenState
    extends ConsumerState<AccountDeletionOtpScreen> {
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  bool _isLoading = false;

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyAndDelete() async {
    String otp = _controllers.map((c) => c.text).join();

    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 4-digit code.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. STEALTH MODE: Verify OTP quietly
      final verified = EmailOtpAuthService.instance.verifyOtp(
        email: widget.contactInfo,
        otp: otp,
      );

      if (!verified) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid or expired OTP.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2. Erase the user from Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.contactInfo)
          .delete();

      if (!mounted) return;

      // 3. Show success message BEFORE wiping the state
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account permanently deleted.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );

      // 4. Pull the plug.
      // This wipes the hard drive and triggers GoRouter to cleanly slide you back to the Landing Page.
      ref.read(authControllerProvider.notifier).logout();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF221610),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Final Verification',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        // 1. ADD THIS WRAPPER
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.security, size: 64, color: Color(0xFF2ECC71)),
                const SizedBox(height: 24),
                const Text(
                  'Verify Deletion',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter the 4-digit code sent to:\n${widget.contactInfo}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.redAccent,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) => _buildOtpBox(index)),
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyAndDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'CONFIRM DELETION',
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
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 65,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          inputFormatters: [LengthLimitingTextInputFormatter(1)],
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (index < 3) {
                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
              } else {
                FocusScope.of(context).unfocus();
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

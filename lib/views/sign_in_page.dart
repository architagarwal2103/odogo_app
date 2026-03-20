import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:go_router/go_router.dart';
import '../controllers/auth_controller.dart'; 

class SignInPage extends ConsumerStatefulWidget {
  final bool isDriver;
  final bool isSignUp;

  const SignInPage({super.key, required this.isDriver, required this.isSignUp});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _handleContinue() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('Please enter an email address.');
      return;
    }
    if (email.contains(' ')) {
      _showError('Email cannot contain spaces.');
      return;
    }
    if (!email.contains('@')) {
      _showError('Email must contain an "@" symbol.');
      return;
    }
    if (!email.endsWith('.com') && !email.endsWith('.ac.in')) {
      _showError('Email must end with .com or .ac.in');
      return;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(com|ac\.in)$',
    );
    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email format.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Tell the controller to send the OTP
      await ref.read(authControllerProvider.notifier).sendOtp(email);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // 2. FORCE THE ROUTE USING .push() 
      // This maintains the navigation stack properly
      context.push(
        '/otp',
        extra: {
          'isDriver': widget.isDriver,
          'isSignUp': widget.isSignUp,
          'email': email,
        },
      );
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      // Show explicit red error if it fails
      _showError(e.toString()); 
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
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/images/odogo_logo.png', height: 80),
              ),
              const SizedBox(height: 10),
              const Text(
                'OdoGo',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.isSignUp
                    ? (widget.isDriver ? 'Driver Sign Up' : 'Commuter Sign Up')
                    : (widget.isDriver ? 'Driver Sign In' : 'Commuter Sign In'),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                ),
              ),
              const SizedBox(height: 20),

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
                    : const Text('Continue', style: TextStyle(fontSize: 18)),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
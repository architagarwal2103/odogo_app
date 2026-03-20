import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // We use this boolean to toggle between Commuter and Driver views
  bool isDriverView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder for the OdoGo Auto Rickshaw Logo
              Image.asset(
                'assets/images/odogo_logo.png',
                height: 100, // Adjust size as needed
              ),
              const SizedBox(height: 10),
              const Text(
                'OdoGo',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              // THE NEW DYNAMIC SUBTITLE
              Text(
                isDriverView ? 'DRIVER' : 'COMMUTER',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                  letterSpacing: 2.0,
                ),
              ),

              const SizedBox(height: 50),

              // Sign In Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: () {
                    context.go(
                      '/sign-in',
                      extra: {'isDriver': isDriverView, 'isSignUp': false},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Sign in', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),

              // Sign Up Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: () {
                    context.go(
                      '/sign-in',
                      extra: {'isDriver': isDriverView, 'isSignUp': true},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Sign up', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 40),

              // The Toggle Text at the bottom
              GestureDetector(
                onTap: () {
                  setState(() {
                    isDriverView = !isDriverView;
                  });
                },
                child: Text(
                  isDriverView ? 'Want to be a user?' : 'Want to be a driver?',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

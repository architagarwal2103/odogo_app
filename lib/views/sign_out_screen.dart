import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Added Riverpod
import '../controllers/auth_controller.dart'; // 2. Import your AuthController (adjust path if needed)

// 3. Changed from StatelessWidget to ConsumerWidget
class SignOutScreen extends ConsumerWidget {
  const SignOutScreen({super.key});

  @override
  // 4. Added WidgetRef ref to the build method
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          user?.name ?? 'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.power_settings_new, size: 36, color: Colors.black),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you Sure?',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 5. Passed 'ref' into the helper method
                  Expanded(
                    child: _buildButton(
                      context,
                      ref,
                      'NO',
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildButton(
                      context,
                      ref,
                      'YES',
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 6. Updated helper method to accept WidgetRef
  Widget _buildButton(
    BuildContext context,
    WidgetRef ref,
    String text, {
    required Color color,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: () {
        if (text == 'YES') {
          // 7. THE FIX: Tell the Controller to wipe the hard drive.
          // GoRouter will automatically see the state change and instantly teleport the user to the Landing Page!
          ref.read(authControllerProvider.notifier).logout();
        } else {
          Navigator.pop(context);
        }
      },
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

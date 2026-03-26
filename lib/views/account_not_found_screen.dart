import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odogo_app/controllers/auth_controller.dart';

class AccountNotFoundScreen extends ConsumerWidget {
  final bool isDriver;
  final String email;

  const AccountNotFoundScreen({
    super.key,
    required this.isDriver,
    required this.email,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleLabel = isDriver ? 'Driver' : 'Commuter';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () =>
              ref.read(authControllerProvider.notifier).abortSignup(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/images/odogo_logo.png', height: 84),
              ),
              const SizedBox(height: 28),
              const Text(
                'Account Not Found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No account exists yet for:\n$email\n\nPlease add your $roleLabel details to continue.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E4E4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.black54),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This is expected for first-time sign in. Next step will create your profile.',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go('/setup', extra: isDriver),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF66D2A3),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Add Info',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

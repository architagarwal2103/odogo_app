import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odogo_app/controllers/auth_controller.dart';
import 'package:odogo_app/models/enums.dart';
import 'package:odogo_app/views/account_not_found_screen.dart';
import 'package:odogo_app/views/commuter_home.dart';
import 'package:odogo_app/views/driver_active_pickup_screen.dart';
import 'package:odogo_app/views/driver_document_upload_screen.dart';
import 'package:odogo_app/views/driver_home_screen.dart';
import 'package:odogo_app/views/landing_page.dart';
import 'package:odogo_app/views/otp_page.dart';
import 'package:odogo_app/views/sign_in_page.dart';
import 'package:odogo_app/views/sign_up_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ValueNotifier<AuthState>(
    ref.read(authControllerProvider),
  );

  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    routerNotifier.value = next;
  });

  ref.onDispose(() {
    routerNotifier.dispose();
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: routerNotifier,

    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final path = state.uri.path;

      if (authState is AuthLoading) {
        return null;
      }

      final isUnauthRoute =
          path.startsWith('/login') ||
          path.startsWith('/sign-in') ||
          path.startsWith('/otp');

      if (authState is AuthInitial ||
          authState is AuthError ||
          authState is AuthOtpSent) {
        if (path.startsWith('/splash')) return '/login';

        if (isUnauthRoute) return null;

        return '/login';
      }

      if (authState is AuthAuthenticated) {
        final user = authState.user;
        final isDriver = user.role == UserRole.driver;

        if (path.startsWith('/otp')) return null;

        if (path.startsWith('/active-pickup')) return null;

        final needsDocs = isDriver && user.vehicle == null;
        if (needsDocs) {
          return path.startsWith('/driver-docs') ? null : '/driver-docs';
        }

        // Forces GoRouter to switch screens if a fallback account has a different role
        if (isDriver && path.startsWith('/commuter-home'))
          return '/driver-home';
        if (!isDriver && path.startsWith('/driver-home'))
          return '/commuter-home';

        if (isUnauthRoute ||
            path.startsWith('/splash') ||
            path.startsWith('/setup') ||
            path.startsWith('/account-not-found') ||
            path.startsWith('/driver-docs')) {
          return isDriver ? '/driver-home' : '/commuter-home';
        }
      }
      if (authState is AuthNeedsProfileSetup) {
        return (path.startsWith('/setup') ||
                path.startsWith('/account-not-found'))
            ? null
            : '/account-not-found';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator(color: Colors.black)),
        ),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LandingPage()),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return SignInPage(
            isDriver: args['isDriver'] ?? false,
            isSignUp: args['isSignUp'] ?? false,
          );
        },
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return OtpPage(
            isDriver: args['isDriver'] ?? false,
            isSignUp: args['isSignUp'] ?? false,
            email: args['email'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/account-not-found',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return AccountNotFoundScreen(
            isDriver: args['isDriver'] ?? false,
            email: args['email'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/commuter-home',
        builder: (context, state) => const CommuterHomeScreen(),
      ),
      GoRoute(
        path: '/driver-home',
        builder: (context, state) => const DriverHomeScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) {
          final isDriver = state.extra as bool? ?? false;
          return SignUpPage(isDriver: isDriver);
        },
      ),
      GoRoute(
        path: '/driver-docs',
        builder: (context, state) => const DriverDocumentUploadScreen(),
      ),
      GoRoute(
        path: '/active-pickup',
        builder: (context, state) {
          final tripID = state.extra as String? ?? '';
          return DriverActivePickupScreen(tripID: tripID);
        },
      ),
    ],
  );
});

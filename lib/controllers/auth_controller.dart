import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/email_link_auth_service.dart'; // Adjust if needed
import '../repositories/user_repository.dart';
import '../models/user_model.dart';

// --- Auth States ---
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {
  final String email;
  AuthOtpSent(this.email);
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
}

class AuthNeedsProfileSetup extends AuthState {
  final String email;
  AuthNeedsProfileSetup(this.email);
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// --- Providers ---
final userRepositoryProvider = Provider((ref) => UserRepository());

// [MODIFIED FOR TESTING 1/3]: Added this provider so we can mock the email service
final emailAuthServiceProvider = Provider((ref) => EmailOtpAuthService.instance);

// 1. UPDATED to NotifierProvider
final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});

// A helper provider so other controllers/UI can easily grab the logged-in user
final currentUserProvider = Provider<UserModel?>((ref) {
  final state = ref.watch(authControllerProvider);
  if (state is AuthAuthenticated) {
    return state.user;
  }
  return null;
});

// --- Controller ---
// 2. UPDATED to Notifier
class AuthController extends Notifier<AuthState> {
  // [MODIFIED FOR TESTING 2/3]: Changed from hardcoded instance to reading the provider
  EmailOtpAuthService get _authService => ref.read(emailAuthServiceProvider);

  // 3. Notifiers use a build() method to set the initial state
  @override
  AuthState build() {
    // Fire off the session check immediately after building
    Future.microtask(() => _checkSavedSession());
    return AuthInitial();
  }

  // 4. We can access 'ref' directly inside a Notifier to read the repo!
  UserRepository get _userRepo => ref.read(userRepositoryProvider);

  Future<void> _checkSavedSession() async {
    state = AuthLoading();
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('odogo_user_email');

      print(
        "DEBUG: Checking saved session. Found email: $savedEmail",
      ); // <--- This will tell us if it saved!

      if (savedEmail != null) {
        final userModel = await _userRepo.getUserByEmail(savedEmail);
        if (userModel != null) {
          state = AuthAuthenticated(userModel);
        } else {
          state = AuthNeedsProfileSetup(savedEmail);
        }
      } else {
        state = AuthInitial();
      }
    } catch (e) {
      print(
        "DEBUG: _checkSavedSession failed! Error: $e",
      ); // <--- Catches Firestore rule errors
      state = AuthInitial(); // Fallback to login screen safely
    }
  }

  Future<void> sendOtp(String email) async {
    state = AuthLoading();
    try {
      await _authService.sendOtp(email: email);
      state = AuthOtpSent(email);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

   // Future<void> verifyOtp(String email, String otp) async {
  //   state = AuthLoading();
  //   try {
  //     final isValid = _authService.verifyOtp(email: email, otp: otp);

  //     if (!isValid) {
  //       state = AuthError("Invalid or expired OTP. Please try again.");
  //       return;
  //     }

  //     // Save to local storage so they don't have to login next time
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setString('odogo_user_email', email);

  //     final userModel = await _userRepo.getUserByEmail(email);

  //     if (userModel != null) {
  //       state = AuthAuthenticated(userModel);
  //     } else {
  //       state = AuthNeedsProfileSetup(email);
  //     }
  //   } catch (e) {
  //     state = AuthError(e.toString());
  //   }
  // }

  // Modify your existing verifyOtp method to save the email to the linked list
  Future<void> verifyOtp(String email, String otp) async {
    state = AuthLoading();
    try {
      final isValid = _authService.verifyOtp(email: email, otp: otp);

      if (!isValid) {
        state = AuthError("Invalid or expired OTP. Please try again.");
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      // Standardize the email to prevent duplicates/ghosts
      final cleanEmail = email.trim().toLowerCase();

      await prefs.setString('odogo_user_email', cleanEmail);

      // SAFELY load the list as a mutable copy
      List<String> linked = List<String>.from(
        prefs.getStringList('odogo_linked_accounts') ?? [],
      );

      // Add only if it doesn't strictly match an existing one
      if (!linked.any((e) => e.trim().toLowerCase() == cleanEmail)) {
        linked.add(cleanEmail);
        await prefs.setStringList('odogo_linked_accounts', linked);
      }

      final userModel = await _userRepo.getUserByEmail(cleanEmail);

      if (userModel != null) {
        state = AuthAuthenticated(userModel);
      } else {
        state = AuthNeedsProfileSetup(cleanEmail);
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  // Add this new method to AuthController
  Future<void> completeProfileSetup(UserModel newUser) async {
    state = AuthLoading();
    try {
      // 1. Save the new user to Firestore
      await _userRepo.createUser(newUser);

      // 2. Officially log them in so the Router takes them to the Map!
      state = AuthAuthenticated(newUser);
    } catch (e) {
      state = AuthError("Failed to save profile: $e");
    }
  }

  // Future<void> logout() async {
  //   // 1. Wipe the saved session from the phone's hard drive
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('odogo_user_email');

  //   // 2. Reset the app state so GoRouter kicks the user to /login
  //   state = AuthInitial();
  // }
  // When a user logs out, remove them from the linked list
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Get the active email BEFORE we wipe it
    final activeEmail = prefs.getString('odogo_user_email');
    List<String> linked = List<String>.from(
      prefs.getStringList('odogo_linked_accounts') ?? [],
    );

    if (activeEmail != null) {
      // 2. Strictly hunt down and destroy the ghost account from the list
      linked.removeWhere(
        (e) => e.trim().toLowerCase() == activeEmail.trim().toLowerCase(),
      );
      await prefs.setStringList('odogo_linked_accounts', linked);
    }

    // 3. NEW ROUTING LOGIC: Check if there are other accounts left!
    if (linked.isNotEmpty) {
      // If other accounts exist, silently switch to the most recent one.
      // GoRouter will automatically teleport them to that account's Home Screen!
      await switchAccount(linked.last);
    } else {
      // If this was the last account on the device, completely wipe the session and go to Login.
      await prefs.remove('odogo_user_email');
      state = AuthInitial();
    }
  }

  // --- ADD THIS BRAND NEW METHOD ---
  Future<void> startAddingNewAccount() async {
    // 1. We change the state to AuthInitial.
    // GoRouter will instantly teleport the user to the Landing/Login Page.
    state = AuthInitial();

    // MAGIC: Notice we DID NOT wipe SharedPreferences!
    // If the user is on the Login Screen and closes the app, the next time
    // they open it, _checkSavedSession will find their old email and safely
    // log them back into their previous account's Home Screen.
  }

  Future<void> deleteAccount(String email, String otp) async {
    state = AuthLoading();
    try {
      final verified = _authService.verifyOtp( // Also uses the getter now
        email: email,
        otp: otp,
      );
      if (!verified) {
        state = AuthError("Invalid or expired OTP. Please try again.");
        return;
      }

      // [MODIFIED FOR TESTING 3/3]: Replaced direct Firestore call with Repo call
      await _userRepo.deleteUser(email);

      final prefs = await SharedPreferences.getInstance();

      // SAFELY load and destroy the ghost account from the device
      List<String> linked = List<String>.from(
        prefs.getStringList('odogo_linked_accounts') ?? [],
      );
      linked.removeWhere(
        (e) => e.trim().toLowerCase() == email.trim().toLowerCase(),
      );
      await prefs.setStringList('odogo_linked_accounts', linked);

      // 3. NEW ROUTING LOGIC: Apply the same smart routing for account deletion
      if (linked.isNotEmpty) {
        await switchAccount(linked.last);
      } else {
        await prefs.remove('odogo_user_email');
        state = AuthInitial();
      }
    } catch (e) {
      state = AuthError("Failed to delete account: $e");
    }
  }

  // Call this whenever the user updates their profile so the app's global state always has the freshest data.
  Future<void> refreshUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('odogo_user_email');

    if (savedEmail != null) {
      final updatedUser = await _userRepo.getUserByEmail(savedEmail);
      if (updatedUser != null) {
        state = AuthAuthenticated(updatedUser);
      }
    }
  }

  /// Retrieves the list of accounts currently logged into this physical device
  Future<List<String>> getLinkedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    // Return the list, or an empty list if none exist
    return prefs.getStringList('odogo_linked_accounts') ?? [];
  }

  /// Switches the active account and triggers a UI rebuild
  Future<void> switchAccount(String newEmail) async {
    state = AuthLoading();
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Change the active account identifier on the hard drive
      await prefs.setString('odogo_user_email', newEmail);

      // 2. Fetch the newly selected user's profile from Firestore
      final userModel = await _userRepo.getUserByEmail(newEmail);

      // 3. Update the global app state.
      // GoRouter will automatically refresh the screen with the new user!
      if (userModel != null) {
        state = AuthAuthenticated(userModel);
      } else {
        state = AuthNeedsProfileSetup(newEmail);
      }
    } catch (e) {
      state = AuthError("Failed to switch account: $e");
    }
  }

  Future<void> abortSignup() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Get the email of the incomplete account
    final activeEmail = prefs.getString('odogo_user_email');

    if (activeEmail != null) {
      // 2. Remove it from linked accounts so it doesn't become a ghost account
      List<String> linked = List<String>.from(
        prefs.getStringList('odogo_linked_accounts') ?? [],
      );
      linked.removeWhere(
        (e) => e.trim().toLowerCase() == activeEmail.trim().toLowerCase(),
      );
      await prefs.setStringList('odogo_linked_accounts', linked);
    }

    // 3. Wipe the active session
    await prefs.remove('odogo_user_email');

    // 4. Drop them at the Landing Page WITHOUT auto-switching to previous accounts
    state = AuthInitial();
  }
}
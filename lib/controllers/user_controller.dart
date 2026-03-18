import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odogo_app/models/enums.dart';
import 'package:odogo_app/models/user_model.dart';
import 'package:odogo_app/models/vehicle_model.dart';
import 'package:odogo_app/repositories/user_repository.dart';
import 'auth_controller.dart'; // To get the current user's ID

// 1. A provider to easily access the repository
final userRepositoryProvider = Provider((ref) => UserRepository());

// 2. A StreamProvider that constantly watches the logged-in user's document.
// If the database changes (e.g., they register a vehicle), the UI updates instantly.
final liveUserProvider = StreamProvider<UserModel?>((ref) {
  final authUser = ref.watch(currentUserProvider);
  if (authUser == null) return const Stream.empty();
  
  return ref.watch(userRepositoryProvider).streamUser(authUser.userID);
});

// 3. The Controller to handle profile updates
final userControllerProvider = NotifierProvider<UserController, AsyncValue<void>>(() {
  return UserController();
});

class UserController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  UserRepository get _repository => ref.read(userRepositoryProvider);

  /// A generic helper to get the current UID safely
  String _getUid() {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception("User not logged in");
    return user.userID;
  }

  /// Replaces the old vehicle_controller logic
  Future<void> registerVehicle(VehicleModel vehicle) async {
    state = const AsyncValue.loading();
    try {
      // Just update the 'vehicle' field in the user's document
      await _repository.updateUser(_getUid(), {
        'vehicle': vehicle.toJson(),
      });
      await ref.read(authControllerProvider.notifier).refreshUser();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Example: Updating the driver's online/offline status
  Future<void> updateDriverMode(DriverMode mode) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateUser(_getUid(), {
        'mode': mode.name,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Example: Updating the commuter's room number
  Future<void> updateRoomNumber(String room) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateUser(_getUid(), {
        'roomNo': room,
      });
      await ref.read(authControllerProvider.notifier).refreshUser();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Allows the user to edit their display name from the profile settings screen
  Future<void> updateName(String newName) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateUser(_getUid(), {
        'name': newName,
      });
      await ref.read(authControllerProvider.notifier).refreshUser();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
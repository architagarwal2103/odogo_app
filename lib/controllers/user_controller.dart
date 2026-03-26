import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odogo_app/models/enums.dart';
import 'package:odogo_app/models/user_model.dart';
import 'package:odogo_app/models/vehicle_model.dart';
import 'package:odogo_app/repositories/user_repository.dart';
import 'package:odogo_app/services/storage_service.dart';
import 'auth_controller.dart';

final liveUserProvider = StreamProvider<UserModel?>((ref) {
  final authUser = ref.watch(currentUserProvider);
  if (authUser == null) return const Stream.empty();

  return ref.watch(userRepositoryProvider).streamUser(authUser.userID);
});

// Controller to handle profile updates
final userControllerProvider =
    NotifierProvider<UserController, AsyncValue<void>>(() {
      return UserController();
    });

class UserController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  UserRepository get _repository => ref.read(userRepositoryProvider);
  // SmsOtpAuthService get _phoneService => SmsOtpAuthService.instance;

  // helper to get the current UID safely
  String _getUid() {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception("User not logged in");
    return user.userID;
  }

  Future<void> registerVehicle(VehicleModel vehicle) async {
    state = const AsyncValue.loading();
    try {
      // Just update the 'vehicle' field in the user's document
      await _repository.updateUser(_getUid(), {'vehicle': vehicle.toJson()});
      await ref.read(authControllerProvider.notifier).refreshUser();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Updating the driver's online/offline status
  Future<void> updateDriverMode(DriverMode mode) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateUser(_getUid(), {'mode': mode.name});
      await ref.read(authControllerProvider.notifier).refreshUser();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Updating the commuter's home address
  Future<void> updateHome(String home) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateUser(_getUid(), {'home': home});
      await ref.read(authControllerProvider.notifier).refreshUser();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  //Allows the user to edit their display name from the profile settings screen
  Future<void> updateName(String newName) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateUser(_getUid(), {'name': newName});
      await ref.read(authControllerProvider.notifier).refreshUser();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateGender(String gender) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateUser(_getUid(), {'gender': gender});
      await ref.read(authControllerProvider.notifier).refreshUser();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateWorkAddress(String address) async {
    state = const AsyncValue.loading();
    try {
      // We will store the Work Address in the first index of savedLocations
      final user = ref.read(currentUserProvider);
      List<String> locations = List.from(user?.savedLocations ?? []);

      if (locations.isEmpty) {
        locations.add(address);
      } else {
        locations[0] = address;
      }

      await _repository.updateUser(_getUid(), {'savedLocations': locations});
      await ref.read(authControllerProvider.notifier).refreshUser();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateDoB(DateTime dob) async {
    state = const AsyncValue.loading();
    try {
      // Converts Flutter DateTime into a Firebase Timestamp
      await _repository.updateUser(_getUid(), {'dob': Timestamp.fromDate(dob)});
      await ref.read(authControllerProvider.notifier).refreshUser();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Change phone number functionality
  /// Step 1: Fires the SMS to the new phone number
  // Future<void> initiatePhoneUpdate(String newPhone) async {
  //   state = const AsyncValue.loading();
  //   try {
  //     await _phoneService.sendOtp(phoneNumber: newPhone);
  //     // We return success here so the UI knows it's safe to push the OTP Screen
  //     state = const AsyncValue.data(null);
  //   } catch (e, st) {
  //     state = AsyncValue.error(e, st);
  //   }
  // }

  // /// Step 2: Verifies the code and permanently saves the new number
  // Future<void> verifyAndSavePhone(String newPhone, String otp) async {
  //   state = const AsyncValue.loading();
  //   try {
  //     final isValid = _phoneService.verifyOtp(phoneNumber: newPhone, otp: otp);
  //     if (!isValid) {
  //       throw Exception("Invalid OTP. Please check the code and try again.");
  //     }

  //     // If Firebase Auth accepts it, save it to our Firestore database
  //     await _repository.updateUser(_getUid(), {'phoneNo': newPhone});

  //     // Sync the local app memory
  //     await ref.read(authControllerProvider.notifier).refreshUser();

  //     state = const AsyncValue.data(null);
  //   } catch (e, st) {
  //     state = AsyncValue.error(e, st);
  //   }
  // }  // currently commented because we need to set up an API key for otp service. I have the code (not yet pushed) for the serice but not yet made API key

  // --- TEMPORARY BYPASS METHOD ---

  Future<void> updateUserPhone(String newPhone) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateUser(_getUid(), {'phoneNo': newPhone});
      await ref.read(authControllerProvider.notifier).refreshUser();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // Document upload functionality
  Future<void> uploadAndSaveDocument(String docType, bool isVehicleDoc) async {
    state = const AsyncValue.loading();
    try {
      final uid = _getUid();

      // Open the phone's file picker (allow images & PDFs)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result == null || result.files.single.path == null) {
        // User canceled the picker
        state = const AsyncValue.data(null);
        return;
      }

      File file = File(result.files.single.path!);

      // Upload the physical file to Firebase Storage
      final downloadUrl = await StorageService.instance.uploadDocument(
        uid: uid,
        documentType: docType,
        file: file,
      );

      // Save the URL to the correct place in Firestore
      if (isVehicleDoc) {
        // For RC, PUC, Insurance (Embedded in VehicleModel)
        // We have to update the specific key inside the embedded map
        await _repository.updateUser(uid, {'vehicle.$docType': downloadUrl});
      } else {
        // For Aadhar or License (Directly on UserModel)
        await _repository.updateUser(uid, {docType: downloadUrl});
      }

      // Refresh the global user state so the UI updates
      await ref.read(authControllerProvider.notifier).refreshUser();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

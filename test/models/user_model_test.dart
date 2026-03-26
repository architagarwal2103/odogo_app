import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odogo_app/models/enums.dart';
import 'package:odogo_app/models/user_model.dart';

void main() {
  group('UserModel Serialization Tests', () {
    final now = Timestamp.now();

    final testJson = {
      'userID': 'test_uid',
      'emailID': 'test@test.com',
      'name': 'Aditya',
      'phoneNo': '9876543210',
      'gender': 'Male',
      'dob': now,
      'role': 'commuter',
      'savedLocations': ['Home', 'Work'],
      'home': 'Home Address',
    };

    test('fromJson correctly parses valid JSON map', () {
      // --- ACT ---
      final user = UserModel.fromJson(testJson);

      // --- ASSERT ---
      expect(user.userID, 'test_uid');
      expect(user.name, 'Aditya');
      expect(user.role, UserRole.commuter);
      expect(user.savedLocations?.length, 2);
      expect(user.savedLocations?[0], 'Home');
    });

    test('toJson correctly converts UserModel back to Map', () {
      // --- ARRANGE ---
      final user = UserModel.fromJson(testJson);

      // --- ACT ---
      final jsonOutput = user.toJson();

      // --- ASSERT ---
      expect(jsonOutput['userID'], 'test_uid');
      expect(jsonOutput['role'], 'commuter'); // Enums should be saved as strings
      expect(jsonOutput['savedLocations'], ['Home', 'Work']);
    });
  });
}
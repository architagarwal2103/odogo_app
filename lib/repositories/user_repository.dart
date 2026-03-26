import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odogo_app/models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _users => _firestore.collection('users');

  // Fetches a user by their Firebase Auth UID; returns null if the user doesn't exist in the database yet.
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e'.replaceFirst('Exception: ', '').trim());
      throw Exception('Failed to fetch user profile.');
    }
  }

  // Fetches a user by their email address.
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final snapshot = await _users
          .where('emailID', isEqualTo: email)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromJson(
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print(
        'Error fetching user by email: $e'
            .replaceFirst('Exception: ', '')
            .trim(),
      );
      throw Exception('Failed to fetch user profile.');
    }
  }

  // Creates a new user document in Firestore.
  Future<void> createUser(UserModel user) async {
    try {
      await _users.doc(user.userID).set(user.toJson());
    } catch (e) {
      print('Error creating user: $e'.replaceFirst('Exception: ', '').trim());
      throw Exception('Failed to create user profile.');
    }
  }

  // Updates specific fields for an existing user.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _users.doc(uid).update(data);
    } catch (e) {
      print('Error updating user: $e'.replaceFirst('Exception: ', '').trim());
      throw Exception('Failed to update user profile.');
    }
  }

  /// Deletes a user document from Firestore.
  Future<void> deleteUser(String uid) async {
    try {
      await _users.doc(uid).delete();
    } catch (e) {
      print('Error deleting user: $e'.replaceFirst('Exception: ', '').trim());
      throw Exception('Failed to delete user profile.');
    }
  }

  /// Streams the user's data so the UI updates automatically
  /// if their profile changes (e.g., verificationStatus changes to true).
  Stream<UserModel?> streamUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService._privateConstructor();
  static final StorageService instance = StorageService._privateConstructor();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a file and returns the public download URL
  Future<String> uploadDocument({
    required String uid,
    required String documentType, // e.g., 'aadhar', 'rc_doc'
    required File file,
  }) async {
    try {
      // 1. Create a clean folder structure in Firebase Storage
      // Path will look like: users/12345ABC/documents/aadhar.pdf
      final extension = file.path.split('.').last;
      final ref = _storage.ref().child('users/$uid/documents/${documentType}_${DateTime.now().millisecondsSinceEpoch}.$extension');

      // 2. Upload the file
      final uploadTask = await ref.putFile(file);

      // 3. Wait for the upload to finish and grab the URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
      
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }
}
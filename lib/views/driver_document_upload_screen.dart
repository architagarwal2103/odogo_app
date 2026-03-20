import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Added Riverpod
import '../controllers/auth_controller.dart';
import '../models/vehicle_model.dart';

// 2. Upgraded to ConsumerStatefulWidget
class DriverDocumentUploadScreen extends ConsumerStatefulWidget {
  const DriverDocumentUploadScreen({super.key});

  @override
  ConsumerState<DriverDocumentUploadScreen> createState() =>
      _DriverDocumentUploadScreenState();
}

class _DriverDocumentUploadScreenState
    extends ConsumerState<DriverDocumentUploadScreen> {
  final Set<String> _uploadedDocs = {};
  bool _isSubmitting = false;

  final List<String> _requiredDocs = [
    'Aadhaar Card',
    'Driving License',
    'Registration Certificate',
    'Pollution Certificate',
    'Insurance Certificate',
  ];

  void _toggleUpload(String title) {
    setState(() {
      if (_uploadedDocs.contains(title)) {
        _uploadedDocs.remove(title);
      } else {
        _uploadedDocs.add(title);
      }
    });
  }

  Future<void> _submitDocuments() async {
    if (_uploadedDocs.length < _requiredDocs.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload all required documents first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception("User not found");

      // THE BACKEND LINK:
      // In reality, you would upload the files to Firebase Storage here and get the URLs back.
      // For now, we populate your VehicleModel with placeholder URLs.
      final vehicleData = VehicleModel(
        registrationNum:
            'PENDING-REG-NUM', // You could add a TextField for this later!
        rcDoc: 'https://firebase.storage.com/.../rc.pdf',
        pucDoc: 'https://firebase.storage.com/.../puc.pdf',
        insuranceDoc: 'https://firebase.storage.com/.../insurance.pdf',
      );

      // Update the user's document in Firestore
      await ref.read(userRepositoryProvider).updateUser(user.userID, {
        'aadharCard': 'https://firebase.storage.com/.../aadhar.pdf',
        'license': 'https://firebase.storage.com/.../license.pdf',
        'vehicle': vehicleData.toJson(),
        'verificationStatus': false, // Keeps them pending admin approval
      });

      // Refresh the active state so the app knows we have a vehicle now
      await ref.read(authControllerProvider.notifier).refreshUser();

      // We DO NOT use Navigator.push here.
      // GoRouter will see the refreshed user has vehicle data and teleport them to the Home Screen!
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading docs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool allDocsUploaded = _uploadedDocs.length == _requiredDocs.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        // Removed the back button so they can't escape until they upload!
        automaticallyImplyLeading: false,
        title: const Text(
          'Driver Registration',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Text(
              'Upload the required\ndocuments here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap a document below to upload',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                itemCount: _requiredDocs.length,
                itemBuilder: (context, index) {
                  return _buildUploadItem(_requiredDocs[index]);
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (allDocsUploaded && !_isSubmitting)
                      ? _submitDocuments
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66D2A3),
                    disabledBackgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    disabledForegroundColor: Colors.grey[500],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'Submit Documents',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadItem(String title) {
    bool isUploaded = _uploadedDocs.contains(title);

    return GestureDetector(
      onTap: () => _toggleUpload(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: isUploaded
              ? const Color(0xFF66D2A3).withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUploaded ? const Color(0xFF66D2A3) : Colors.grey[300]!,
            width: isUploaded ? 2.0 : 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isUploaded ? Colors.black : Colors.grey[800],
                fontSize: 16,
                fontWeight: isUploaded ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            Icon(
              isUploaded ? Icons.check_circle : Icons.upload_file,
              color: isUploaded ? const Color(0xFF66D2A3) : Colors.grey[400],
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}





// The below code requires firebase blaze plan to run. Else app will hang

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../controllers/auth_controller.dart';
// import '../controllers/user_controller.dart'; // IMPORTANT: Added to access upload logic
// import '../models/vehicle_model.dart';

// class DriverDocumentUploadScreen extends ConsumerStatefulWidget {
//   const DriverDocumentUploadScreen({super.key});

//   @override
//   ConsumerState<DriverDocumentUploadScreen> createState() =>
//       _DriverDocumentUploadScreenState();
// }

// class _DriverDocumentUploadScreenState
//     extends ConsumerState<DriverDocumentUploadScreen> {
//   // We removed _uploadedDocs! Riverpod will track this for us.
//   bool _isSubmitting = false;

//   // We map your UI titles to their exact database keys and vehicle status
//   final List<Map<String, dynamic>> _documentMap = [
//     {'title': 'Aadhaar Card', 'key': 'aadharCard', 'isVehicle': false},
//     {'title': 'Driving License', 'key': 'license', 'isVehicle': false},
//     {'title': 'Registration Certificate', 'key': 'rcDoc', 'isVehicle': true},
//     {'title': 'Pollution Certificate', 'key': 'pucDoc', 'isVehicle': true},
//     {'title': 'Insurance Certificate', 'key': 'insuranceDoc', 'isVehicle': true},
//   ];

//   Future<void> _submitDocuments() async {
//     setState(() => _isSubmitting = true);

//     try {
//       final user = ref.read(currentUserProvider);
//       if (user == null) throw Exception("User not found");

//       // THE BACKEND LINK:
//       // Because uploadAndSaveDocument() ALREADY saved the URLs to Firestore
//       // when the user tapped each row, we just need to finalize their profile!
      
//       await ref.read(userRepositoryProvider).updateUser(user.userID, {
//         'vehicle.registrationNum': 'PENDING', // Ensures VehicleModel parses safely
//         'verificationStatus': false, // False = Pending Admin Approval
//       });

//       // Refresh the active state so the Router knows we are done
//       await ref.read(authControllerProvider.notifier).refreshUser();

//       // GoRouter will see verificationStatus is false and route them appropriately!
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error finalizing registration: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _isSubmitting = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // 1. Watch the user and controller state
//     final currentUser = ref.watch(currentUserProvider);
//     final userState = ref.watch(userControllerProvider);
//     final isUploadingAny = userState is AsyncLoading;

//     // 2. Check which documents have actual URLs in the database
//     bool hasAadhar = currentUser?.aadharCard != null;
//     bool hasLicense = currentUser?.license != null;
//     bool hasRc = currentUser?.vehicle?.rcDoc != null;
//     bool hasPuc = currentUser?.vehicle?.pucDoc != null;
//     bool hasInsurance = currentUser?.vehicle?.insuranceDoc != null;

//     bool allDocsUploaded = hasAadhar && hasLicense && hasRc && hasPuc && hasInsurance;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         automaticallyImplyLeading: false,
//         title: const Text(
//           'Driver Registration',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             const SizedBox(height: 32),
//             const Text(
//               'Upload the required\ndocuments here',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.w800,
//                 color: Colors.black,
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Tap a document below to upload',
//               style: TextStyle(
//                 color: Colors.grey,
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),

//             Expanded(
//               child: ListView.builder(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24,
//                   vertical: 32,
//                 ),
//                 itemCount: _documentMap.length,
//                 itemBuilder: (context, index) {
//                   final docInfo = _documentMap[index];
                  
//                   // Determine if this specific document is uploaded based on the DB
//                   bool isUploaded = false;
//                   if (docInfo['key'] == 'aadharCard') isUploaded = hasAadhar;
//                   if (docInfo['key'] == 'license') isUploaded = hasLicense;
//                   if (docInfo['key'] == 'rcDoc') isUploaded = hasRc;
//                   if (docInfo['key'] == 'pucDoc') isUploaded = hasPuc;
//                   if (docInfo['key'] == 'insuranceDoc') isUploaded = hasInsurance;

//                   return _buildUploadItem(
//                     title: docInfo['title'],
//                     dbKey: docInfo['key'],
//                     isVehicleDoc: docInfo['isVehicle'],
//                     isUploaded: isUploaded,
//                     isUploadingAny: isUploadingAny,
//                   );
//                 },
//               ),
//             ),

//             Padding(
//               padding: const EdgeInsets.all(24.0),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton(
//                   // Disable if not all uploaded, or if something is currently uploading
//                   onPressed: (allDocsUploaded && !_isSubmitting && !isUploadingAny)
//                       ? _submitDocuments
//                       : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF66D2A3),
//                     disabledBackgroundColor: Colors.grey[200],
//                     foregroundColor: Colors.black,
//                     disabledForegroundColor: Colors.grey[500],
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     elevation: 0,
//                   ),
//                   child: _isSubmitting
//                       ? const CircularProgressIndicator(color: Colors.black)
//                       : const Text(
//                           'Submit Documents',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Updated signature to accept backend data
//   Widget _buildUploadItem({
//     required String title,
//     required String dbKey,
//     required bool isVehicleDoc,
//     required bool isUploaded,
//     required bool isUploadingAny,
//   }) {
//     return GestureDetector(
//       // THE TAP LINK: Call the UserController to trigger the file picker & upload
//       onTap: (isUploaded || isUploadingAny) 
//           ? null // Prevent tapping if already uploaded or if something else is uploading
//           : () {
//               ref.read(userControllerProvider.notifier)
//                  .uploadAndSaveDocument(dbKey, isVehicleDoc);
//             },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         margin: const EdgeInsets.only(bottom: 16),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//         decoration: BoxDecoration(
//           color: isUploaded
//               ? const Color(0xFF66D2A3).withOpacity(0.1)
//               : Colors.grey[50],
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: isUploaded ? const Color(0xFF66D2A3) : Colors.grey[300]!,
//             width: isUploaded ? 2.0 : 1.5,
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               title,
//               style: TextStyle(
//                 color: isUploaded ? Colors.black : Colors.grey[800],
//                 fontSize: 16,
//                 fontWeight: isUploaded ? FontWeight.bold : FontWeight.w600,
//               ),
//             ),
//             Icon(
//               isUploaded ? Icons.check_circle : Icons.upload_file,
//               color: isUploaded ? const Color(0xFF66D2A3) : Colors.grey[400],
//               size: 26,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
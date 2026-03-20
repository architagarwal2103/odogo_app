import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. ADDED: Import Riverpod to access state
import '../controllers/auth_controller.dart'; // 2. ADDED: Import Auth Controller to get user data

// 3. CHANGED: Converted from StatelessWidget to ConsumerWidget
class DriverDocumentsScreen extends ConsumerWidget {
  const DriverDocumentsScreen({super.key});

  final Color odogoGreen = const Color(0xFF66D2A3);

  @override
  // 4. CHANGED: Added WidgetRef to the build method
  Widget build(BuildContext context, WidgetRef ref) {
    // 5. ADDED: Fetch the current logged-in user from Riverpod
    final user = ref.watch(currentUserProvider);
    final vehicle = user?.vehicle;

    // 6. CHANGED: Moved the documents list inside build() so it can access the dynamic 'user' data.
    // Mapped the specific backend URLs to each document type.
    final List<Map<String, dynamic>> documents = [
      {
        'title': 'Aadhar Card',
        'icon': Icons.badge_outlined,
        'url': user?.aadharCard,
      },
      {
        'title': 'Driving License',
        'icon': Icons.contact_mail_outlined,
        'url': user?.license,
      },
      {
        'title': 'Registration Certificate (RC)',
        'icon': Icons.assignment_outlined,
        'url': vehicle?.rcDoc,
      },
      {
        'title': 'Pollution Certificate (PUC)',
        'icon': Icons.eco_outlined,
        'url': vehicle?.pucDoc,
      },
      {
        'title': 'Insurance Certificate',
        'icon': Icons.security_outlined,
        'url': vehicle?.insuranceDoc,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // 7. CHANGED: Dynamically display the user's actual name from the backend instead of 'Inesh'
        title: Text(
          user?.name ?? 'Profile',
          style: const TextStyle(color: Colors.white),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF66D2A3), // OdoGo Green
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Body Header
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 40,
                    color: Colors.black87,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Documents',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // The Document List
            // 8. CHANGED: Passed the dynamic documents list to the builder method
            Expanded(child: _buildDocumentList(documents)),
          ],
        ),
      ),
    );
  }

  // 9. CHANGED: Accept the documents list as a parameter
  Widget _buildDocumentList(List<Map<String, dynamic>> documents) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        final url = doc['url'] as String?;

        return Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(doc['icon'], color: Colors.black87),
              ),
              title: Text(
                doc['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.visibility, color: odogoGreen),
                    tooltip: 'View Document',
                    onPressed: () {
                      // 10. ADDED: View Document Logic
                      if (url != null && url.isNotEmpty) {
                        // Displays the URL in a dialog.
                        // (If you add the 'url_launcher' package later, you can replace this showDialog with launchUrl(Uri.parse(url)))
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(doc['title']),
                            content: Text('Document Link:\n$url'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Handle missing documents
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Document not uploaded yet.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    tooltip: 'Update Document',
                    onPressed: () {
                      print("Updating ${doc['title']}");
                      // Here you can route them to an update/upload screen
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 24, thickness: 1, color: Colors.black12),
          ],
        );
      },
    );
  }
}

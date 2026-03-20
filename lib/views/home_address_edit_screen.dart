// import 'package:flutter/material.dart';

// class HomeAddressEditScreen extends StatefulWidget {
//   const HomeAddressEditScreen({super.key});

//   @override
//   State<HomeAddressEditScreen> createState() => _HomeAddressEditScreenState();
// }

// class _HomeAddressEditScreenState extends State<HomeAddressEditScreen> {
//   // Controller to capture the home address, pre-filled with your example
//   final TextEditingController _addressController = TextEditingController(text: 'Hall 12');

//   @override
//   void dispose() {
//     _addressController.dispose();
//     super.dispose();
//   }

//   void _saveAddress() {
//     print("Saving new home address: ${_addressController.text}");

//     // Show a quick success popup
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Home address updated successfully!'),
//         backgroundColor: Colors.green,
//       ),
//     );

//     // Return to the Profile Page
//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         // The essential Back Button!
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text('Inesh', style: TextStyle(color: Colors.white)),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16.0),
//             child: CircleAvatar(
//               radius: 16,
//               backgroundColor: const Color(0xFF66D2A3), // OdoGo Green
//               child: const Icon(Icons.person, color: Colors.white, size: 20),
//             ),
//           )
//         ],
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Row(
//                 children: [
//                   Icon(Icons.home_outlined, size: 40, color: Colors.black87),
//                   SizedBox(width: 12),
//                   Text(
//                     'Home Address',
//                     style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 40),
//               TextField(
//                 controller: _addressController,
//                 decoration: InputDecoration(
//                   filled: true,
//                   fillColor: Colors.grey[200],
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide.none,
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                   hintText: 'Enter your hostel or hall number',
//                 ),
//                 style: const TextStyle(fontSize: 18),
//               ),
//               const SizedBox(height: 40),

//               // Full-width button to match the other settings screens
//               ElevatedButton(
//                 onPressed: _saveAddress,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF333333),
//                   minimumSize: const Size.fromHeight(56),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//                 child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_controller.dart';
import '../data/iitk_dropoff_locations.dart'; 

class HomeAddressEditScreen extends ConsumerStatefulWidget {
  const HomeAddressEditScreen({super.key});
  @override
  ConsumerState<HomeAddressEditScreen> createState() =>
      _HomeAddressEditScreenState();
}

class _HomeAddressEditScreenState extends ConsumerState<HomeAddressEditScreen> {
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null && user.roomNo != null) {
      _addressController.text = user.roomNo!;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a home address first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await ref
        .read(userControllerProvider.notifier)
        .updateRoomNumber(_addressController.text.trim());
        
    if (!mounted) return;
    
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Home address updated!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  // --- THE UNIFIED BOTTOM SHEET SELECTOR ---
  Future<void> _openAddressSelector() async {
    String localSearchText = '';
    
    final selected = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, // Required for the black banner trick
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            
            // Reusing your alias filtering logic
            List<DropoffLocation> sheetFiltered = localSearchText.isEmpty 
              ? iitkDropoffLocations 
              : iitkDropoffLocations.where((loc) => 
                  loc.name.toLowerCase().contains(localSearchText.toLowerCase()) || 
                  loc.matches(localSearchText) 
                ).toList();

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), 
              child: Container(
                // THE BLACK BANNER BACKGROUND
                decoration: const BoxDecoration(
                  color: Colors.black, 
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    // THE WHITE SHEET FOREGROUND
                    height: MediaQuery.of(context).size.height * 0.65,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Text('Set Home Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: TextField(
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search hostel or hall...', // Updated hint text
                              prefixIcon: const Icon(Icons.search, color: Colors.black54),
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            ),
                            onChanged: (val) {
                              setSheetState(() => localSearchText = val);
                            },
                          ),
                        ),
                        
                        // REMOVED custom string input tile here. Added "No Results" message.
                        if (localSearchText.isNotEmpty && sheetFiltered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No locations found matching "$localSearchText"',
                                style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ),

                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            itemCount: sheetFiltered.length,
                            itemBuilder: (context, index) {
                              final location = sheetFiltered[index];
                              return ListTile(
                                leading: const Icon(Icons.home_outlined, color: Colors.black54), // Updated icon for Home
                                title: Text(location.name),
                                onTap: () => Navigator.pop(sheetContext, location), 
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      },
    );

    if (!mounted || selected == null) return;
    
    setState(() {
      if (selected is String) {
        _addressController.text = selected;
      } else if (selected is DropoffLocation) {
        _addressController.text = selected.name;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          user?.name ?? 'Profile',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.home_outlined, size: 32, color: Colors.black), // Matched sizing to Work Address
                  SizedBox(width: 12),
                  Text(
                    'Home Address',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // --- THE NEW STYLED SELECTOR BUTTON ---
              GestureDetector(
                onTap: _openAddressSelector,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _addressController.text.isEmpty ? 'Search campus locations...' : _addressController.text,
                          style: TextStyle(
                            fontSize: 16,
                            color: _addressController.text.isEmpty ? Colors.grey[600] : Colors.black87,
                            fontWeight: _addressController.text.isEmpty ? FontWeight.normal : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SAVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
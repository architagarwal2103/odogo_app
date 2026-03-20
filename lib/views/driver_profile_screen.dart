import 'package:flutter/material.dart';
import 'personal_details_screen.dart'; 
import 'driver_documents_profile_page.dart';
// import 'location_sharing_screen.dart';
import 'commute_alerts_screen.dart';
import 'switch_account_screen.dart';
import 'account_deletion_screen.dart';
import 'sign_out_screen.dart';
import 'edit_name_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';

class BoundedBouncingScrollPhysics extends BouncingScrollPhysics {
  const BoundedBouncingScrollPhysics({super.parent});

  final double maxOverscroll = 25.0;

  @override
  BoundedBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return BoundedBouncingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value < position.minScrollExtent - maxOverscroll) {
      return value - (position.minScrollExtent - maxOverscroll);
    }
    if (value > position.maxScrollExtent + maxOverscroll) {
      return value - (position.maxScrollExtent + maxOverscroll);
    }
    return super.applyBoundaryConditions(position, value);
  }
}

class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // <-- Added WidgetRef
    // FETCH LIVE USER DATA
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.black,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFF66D2A3),
                    child: Icon(Icons.person, color: Colors.white, size: 35),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      user?.name ?? 'Loading...', // <-- DYNAMIC NAME HERE
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Color(0xFF66D2A3),
                        size: 20,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditNameScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // --- SCROLLABLE LIST SECTION ---
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollBehavior().copyWith(overscroll: false),
                child: SingleChildScrollView(
                  physics: const BoundedBouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // 1. THE NEW PERSONAL DETAILS BUTTON
                      _buildTile(
                        context,
                        Icons.badge_outlined,
                        'Personal Details',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PersonalDetailsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(
                        height: 30,
                        thickness: 1,
                        color: Colors.black12,
                      ),

                      // 2. DRIVER SPECIFIC: DOCUMENTS
                      _buildTile(
                        context,
                        Icons.description_outlined,
                        'Documents',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DriverDocumentsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(
                        height: 30,
                        thickness: 1,
                        color: Colors.black12,
                      ),

                      // 3. THE REST OF THE MENU
                      // _buildTile(
                      //   context,
                      //   Icons.location_on_outlined,
                      //   'Location Sharing',
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) =>
                      //             const LocationSharingScreen(),
                      //       ),
                      //     );
                      //   },
                      // ),
                      // const Divider(
                      //   height: 30,
                      //   thickness: 1,
                      //   color: Colors.black12,
                      // ),

                      _buildTile(
                        context,
                        Icons.notifications_none,
                        'Commute Alerts',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CommuteAlertsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(
                        height: 30,
                        thickness: 1,
                        color: Colors.black12,
                      ),

                      _buildTile(
                        context,
                        Icons.swap_horiz,
                        'Switch Account',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SwitchAccountScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(
                        height: 30,
                        thickness: 1,
                        color: Colors.black12,
                      ),

                      _buildTile(
                        context,
                        Icons.power_settings_new,
                        'Sign out',
                        isDestructive: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignOutScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(
                        height: 30,
                        thickness: 1,
                        color: Colors.black12,
                      ),

                      _buildTile(
                        context,
                        Icons.delete_outline,
                        'Account Deletion',
                        isDestructive: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AccountDeletionScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    IconData icon,
    String title, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      onTap: onTap,
    );
  }
}

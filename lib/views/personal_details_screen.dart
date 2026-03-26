import 'package:flutter/material.dart';
import 'phone_number_edit_screen.dart';
import 'gender_selection_screen.dart';
import 'email_edit_screen.dart';
import 'edit_date_of_birth_screen.dart';

class _BoundedBouncingScrollPhysics extends BouncingScrollPhysics {
  const _BoundedBouncingScrollPhysics({super.parent});

  final double maxOverscroll = 25.0;

  @override
  _BoundedBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _BoundedBouncingScrollPhysics(parent: buildParent(ancestor));
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

class PersonalDetailsScreen extends StatelessWidget {
  const PersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Personal Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: ScrollBehavior().copyWith(overscroll: false),
          child: SingleChildScrollView(
            physics: const _BoundedBouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 10),

                _buildTile(
                  context,
                  Icons.phone,
                  'Phone Number',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PhoneNumberEditScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 30, thickness: 1, color: Colors.black12),

                _buildTile(
                  context,
                  Icons.email_outlined,
                  'Email',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmailEditScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 30, thickness: 1, color: Colors.black12),

                _buildTile(
                  context,
                  Icons.person_outline,
                  'Gender',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GenderSelectionScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 30, thickness: 1, color: Colors.black12),

                _buildTile(
                  context,
                  Icons.calendar_today,
                  'Date of Birth',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditDateOfBirthScreen(),
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
    );
  }

  Widget _buildTile(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      onTap: onTap,
    );
  }
}

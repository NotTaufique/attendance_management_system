import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'view_teachers_screen.dart';
import 'view_students_screen.dart';
import 'add_teacher_screen.dart';
import 'add_student_screen.dart';

class AdminDashboard extends StatelessWidget {
  AdminDashboard({super.key});
  final _storage = FlutterSecureStorage();
  Future<void> _logout(BuildContext context) async {
    // Clear stored credentials
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'password');

    // Clear remember me preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', false);

    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    // Navigate back to login screen
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // AMOLED background
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.lato(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Full-width View/Edit Teachers Button
            _buildFullWidthCard(
              title: 'View/Edit Teachers',
              iconData: Icons.school,
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewTeachersScreen(),
                    ),
                  ),
            ),
            SizedBox(height: 20),

            // Full-width View/Edit Students Button
            _buildFullWidthCard(
              title: 'View/Edit Students',
              iconData: Icons.people,
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewStudentsScreen(),
                    ),
                  ),
            ),
            SizedBox(height: 20),

            // Full-width Add Teacher/Student Button
            _buildFullWidthCard(
              title: 'Add Teacher/Student',
              iconData: Icons.person_add,
              onPressed: () => _showAddUserDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidthCard({
    required String title,
    required IconData iconData,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity, // Full width
      child: Card(
        color: Color(0xFF161B22),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ), // Padding inside the card
          leading: Icon(iconData, color: Colors.blueAccent, size: 28),
          title: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: onPressed,
        ),
      ),
    );
  }

  Widget _buildDialogOption(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context); // Close the dialog
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Correctly passing BuildContext
        return AlertDialog(
          title: Text('Add User', style: TextStyle(color: Colors.blueAccent)),
          backgroundColor: Color(0xFF161B22),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogOption(
                context,
                'Teacher',
                Icons.person,
                AddTeacherScreen(),
              ),
              _buildDialogOption(
                context,
                'Student',
                Icons.people,
                AddStudentScreen(),
              ),
            ],
          ),
        );
      },
    );
  }
}

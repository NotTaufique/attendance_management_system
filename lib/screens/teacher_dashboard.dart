import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'class_students_screen.dart'; // Import the ClassStudentsScreen

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  List<String> assignedClasses = []; // List of classes assigned to the teacher
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAssignedClasses(); // Fetch assigned classes when screen loads
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.toLowerCase());
  }

  Future<void> fetchAssignedClasses() async {
    final user =
        FirebaseAuth.instance.currentUser; // Get currently logged-in user
    if (user == null) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          assignedClasses = List<String>.from(
            snapshot['assignedClasses'] ?? [],
          );
        });
      }
    } catch (e) {
      print('Error fetching assigned classes: $e');
    }
  }

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
          'Teacher Dashboard',
          style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              _logout(
                context,
              ); // Call the asynchronous function inside a synchronous callback
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for a class...',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Displaying Class Tiles
            Expanded(
              child: ListView.builder(
                itemCount: assignedClasses.length,
                itemBuilder: (context, index) {
                  final className = assignedClasses[index];
                  if (_searchQuery.isNotEmpty &&
                      !className.toLowerCase().contains(_searchQuery)) {
                    return SizedBox.shrink(); // Skip this tile if it doesn't match the search query
                  }
                  return Card(
                    color: Color(0xFF161B22),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        className,
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.arrow_forward,
                          color: Colors.blueAccent,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ClassStudentsScreen(
                                    className: className,
                                  ), // Pass class name to ClassStudentsScreen
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

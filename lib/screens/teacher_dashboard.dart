import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'class_students_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import flutter_spinkit

class TeacherDashboard extends StatefulWidget {
  final List<Map<String, dynamic>> assignedClasses;

  const TeacherDashboard({Key? key, required this.assignedClasses}) : super(key: key);

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> assignedClasses = [];
  bool isLoading = false; // Added loading state
  String teacherName = '';

  @override
  void initState() {
    super.initState();
    assignedClasses = widget.assignedClasses; // Initialize from the widget
    _searchController.addListener(_onSearchChanged);
    loadTeacherName();
  }

  Future<void> loadTeacherName() async {
    setState(() {
      isLoading = true; // Set loading to true
    });
    try {
      // Fetch the currently logged-in user
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Fetch the user document from Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          // Store the teacher's name from the document data
          setState(() {
            teacherName = userData?['name'] as String? ?? 'Teacher';
          });
        }
      }
    } catch (e) {
      print('Error loading teacher name: $e');
    } finally {
      setState(() {
        isLoading = false; // Set loading to false after the name is loaded
      });
    }
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.toLowerCase());
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back button
        title: Text(
          isLoading ? 'Loading...' : 'Welcome, $teacherName!', // Dynamic title with teacher's name
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
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              _logout(context);
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for a class...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading // Show loading indicator while fetching data
                  ? Center(
                      child: SpinKitFadingCircle(color: Colors.blueAccent, size: 50),
                    )
                  : ListView.builder(
                      itemCount: assignedClasses.length,
                      itemBuilder: (context, index) {
                        final classData = assignedClasses[index];
                        final className = classData['class'] as String; // Get class name
                        final subjectName = classData['subject'] as String; // Get subject name

                        if (_searchQuery.isNotEmpty && !className.toLowerCase().contains(_searchQuery)) {
                          return const SizedBox.shrink();
                        }

                        return Card(
                          color: const Color(0xFF161B22),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              className,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Subject: ${classData['subject']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.arrow_forward,
                                color: Colors.blueAccent,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ClassStudentsScreen(
                                      className: className,
                                      subjectName: subjectName, // Pass the subject name here
                                    ),
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_teacher_screen.dart'; // Import the Edit Teacher Screen

class ViewTeachersScreen extends StatefulWidget {
  const ViewTeachersScreen({super.key});

  @override
  _ViewTeachersScreenState createState() => _ViewTeachersScreenState();
}

class _ViewTeachersScreenState extends State<ViewTeachersScreen> {
  List<Map<String, dynamic>> teachers = []; // List to store teacher data

  @override
  void initState() {
    super.initState();
    fetchTeachers(); // Fetch teachers when the screen initializes
  }

  /// Fetch all teachers from Firestore where role == "teacher"
  Future<void> fetchTeachers() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'teacher') // Query for teachers only
              .get();

      print('Fetched Teachers Count: ${snapshot.docs.length}'); // Debug

      if (snapshot.docs.isEmpty) {
        print('No teachers found in Firestore.');
      }

      setState(() {
        teachers =
            snapshot.docs.map((doc) {
              return {
                'uid': doc.id.toString(), // UID of the teacher
                'name':
                    doc['name'] ??
                    'No Name', // Use name or fallback to "No Name"
                'email':
                    doc['email'] ??
                    'No Email', // Use email or fallback to "No Email"
              };
            }).toList();
      });
    } catch (e) {
      print('Error fetching teachers: $e'); // Debug
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // AMOLED background
      appBar: AppBar(
        title: Text(
          'Available Teachers',
          style: GoogleFonts.lato(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child:
            teachers.isEmpty
                ? Center(
                  child: Text(
                    'No Teachers Found',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                ) // Display if no teachers are available
                : ListView.builder(
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    final teacher = teachers[index];
                    return Card(
                      color: Color(0xFF161B22), // Dark card background
                      margin: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 16,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text(
                            teacher['name'][0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          teacher['name'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          teacher['email'],
                          style: TextStyle(color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => EditTeacherScreen(
                                      teacherId: teacher['uid'],
                                      currentName: teacher['name'],
                                      currentEmail: teacher['email'],
                                      currentClasses: [],
                                    ),
                              ),
                            ).then((_) => fetchTeachers());
                          },
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}

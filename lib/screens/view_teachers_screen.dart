import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_teacher_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ViewTeachersScreen extends StatefulWidget {
  const ViewTeachersScreen({Key? key}) : super(key: key);

  @override
  _ViewTeachersScreenState createState() => _ViewTeachersScreenState();
}

class _ViewTeachersScreenState extends State<ViewTeachersScreen> {
  List<Map<String, dynamic>> teachers = [];
  bool isLoading = true; // Added loading state

  @override
  void initState() {
    super.initState();
    fetchTeachers();
  }

  Future<void> fetchTeachers() async {
    setState(() {
      isLoading = true; // Set loading to true
    });
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();

      setState(() {
        teachers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'uid': doc.id.toString(),
            'name': data['name'] ?? 'No Name',
            'email': data['email'] ?? 'No Email',
            'subjects': List<Map<String, dynamic>>.from(data['subjects'] ?? []),
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching teachers: $e');
    } finally {
      setState(() {
        isLoading = false; // Set loading to false after data is fetched
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
        child: isLoading
            ? Center(
                child: SpinKitFadingCircle(color: Colors.blueAccent, size: 50), // Loading animation
              )
            : teachers.isEmpty
                ? const Center(
                    child: Text(
                      'No Teachers Found',
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: teachers.length,
                    itemBuilder: (context, index) {
                      final teacher = teachers[index];

                      return Card(
                        color: const Color(0xFF161B22),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              teacher['name'][0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                teacher['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditTeacherScreen(
                                        teacherId: teacher['uid'],
                                        currentName: teacher['name'], // ✅ Passing Name
                                      ),
                                    ),
                                  ).then((_) => fetchTeachers()); // Refresh
                                },
                              ),
                            ],
                          ),
                          children: (teacher['subjects'] as List<dynamic>).isEmpty
                              ? [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 10.0,
                                      horizontal: 20.0,
                                    ),
                                    child: Text(
                                      'No assigned classes',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ]
                              : (teacher['subjects'] as List<dynamic>).map((cls) {
                                  return ListTile(
                                    title: Text(
                                      '${cls['class']} - ${cls['subject']}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  );
                                }).toList(),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

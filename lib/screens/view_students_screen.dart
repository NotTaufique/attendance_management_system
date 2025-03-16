import 'package:attendance_management_system/screens/edit_student_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewStudentsScreen extends StatefulWidget {
  const ViewStudentsScreen({super.key});

  @override
  _ViewStudentsScreenState createState() => _ViewStudentsScreenState();
}

class _ViewStudentsScreenState extends State<ViewStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.toLowerCase());
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Manage Students',
          style: GoogleFonts.lato(color: Colors.blueAccent),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search students...',
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
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('students').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                // Filter students based on search query
                final filteredStudents =
                    snapshot.data!.docs.where((doc) {
                      final studentName = doc['name'].toString().toLowerCase();
                      final rollNo = doc['rollNo'].toString().toLowerCase();
                      return studentName.contains(_searchQuery) ||
                          rollNo.contains(_searchQuery);
                    }).toList();

                // Sort students by roll number in ascending order
                filteredStudents.sort((a, b) {
                  final rollNoA =
                      int.tryParse(a['rollNo'].toString()) ??
                      double.infinity.toInt();
                  final rollNoB =
                      int.tryParse(b['rollNo'].toString()) ??
                      double.infinity.toInt();
                  return rollNoA.compareTo(rollNoB);
                });

                // Group students by class
                final Map<String, List<DocumentSnapshot>> classGroups = {};
                for (var doc in filteredStudents) {
                  final className = doc['class'] ?? 'Unassigned';
                  classGroups.putIfAbsent(className, () => []).add(doc);
                }

                return ListView.builder(
                  itemCount: classGroups.length,
                  itemBuilder: (context, index) {
                    final entry = classGroups.entries.elementAt(index);
                    return _buildClassExpansion(entry.key, entry.value);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassExpansion(
    String className,
    List<DocumentSnapshot> students,
  ) {
    return ExpansionTile(
      title: Text(
        className,
        style: TextStyle(color: Colors.blueAccent, fontSize: 18),
      ),
      backgroundColor: Color(0xFF161B22).withOpacity(0.3),
      collapsedBackgroundColor: Color(0xFF161B22),
      children: [...students.map((doc) => _buildStudentTile(doc))],
    );
  }

  Widget _buildStudentTile(DocumentSnapshot doc) {
    final student = doc.data() as Map<String, dynamic>;
    return ListTile(
      title: Text(
        '${student['rollNo']}. ${student['name']}',
        style: TextStyle(color: Colors.white),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blueAccent),
            onPressed: () => _editStudent(doc),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _deleteStudent(doc.id),
          ),
        ],
      ),
    );
  }

  void _editStudent(DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditStudentScreen(studentData: doc),
      ),
    );
  }

  Future<void> _deleteStudent(String studentId) async {
    await FirebaseFirestore.instance
        .collection('students')
        .doc(studentId)
        .delete();
  }
}

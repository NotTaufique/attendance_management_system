import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class EditStudentScreen extends StatefulWidget {
  final DocumentSnapshot studentData;

  const EditStudentScreen({super.key, required this.studentData});

  @override
  _EditStudentScreenState createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  late TextEditingController _nameController;
  late TextEditingController _rollNoController;
  String? _selectedClass;

  // List of available classes
  final List<String> availableClasses = [
    "Fe A",
    "Fe B",
    "Fe C",
    "Fe D",
    "SE Comps",
    "TE Comps",
    "BE Comps",
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.studentData['name']);
    _rollNoController = TextEditingController(
      text: widget.studentData['rollNo'].toString(),
    );
    _selectedClass = widget.studentData['class'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // AMOLED background
      appBar: AppBar(
        title: Text(
          'Edit Student',
          style: GoogleFonts.lato(color: Colors.blueAccent),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Name TextField
            TextField(
              controller: _nameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 10),

            // Roll Number TextField
            TextField(
              controller: _rollNoController,
              style: TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Roll Number',
                labelStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 10),

            // Class Dropdown
            DropdownButtonFormField<String>(
              value: _selectedClass,
              items:
                  availableClasses.map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(color: Colors.white)),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedClass = newValue;
                });
              },
              dropdownColor: Color(0xFF161B22),
              decoration: InputDecoration(
                labelText: 'Class',
                labelStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Save Changes Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _saveChanges(context),
              child: Text(
                'Save Changes',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentData.id)
          .update({
            'name': _nameController.text,
            'rollNo': int.parse(_rollNoController.text),
            'class': _selectedClass,
          });
      Navigator.pop(context);
    } catch (e) {
      print('Error updating student:$e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update student')));
    }
  }
}

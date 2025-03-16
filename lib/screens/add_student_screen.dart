import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  _AddStudentScreenState createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _nameController = TextEditingController(); // Student Name
  final _rollNoController = TextEditingController(); // Student Roll Number
  String? selectedClass; // Store selected class

  final List<String> availableClasses = [
    "Fe A",
    "Fe B",
    "Fe C",
    "Fe D",
    "SE Comps",
    "TE Comps",
    "BE Comps",
  ]; // List of available classes

  Future<void> addStudent() async {
    if (selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a class to assign')),
      );
      return;
    }

    try {
      // Add student details to Firestore
      await FirebaseFirestore.instance.collection('students').add({
        'name': _nameController.text.trim(),
        'rollNo': int.parse(_rollNoController.text.trim()), // Store roll number
        'class': selectedClass, // Store the selected class
        'attendance': {}, // Initialize with empty attendance map
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Student added successfully!')));
      _nameController.clear();
      _rollNoController.clear();
      setState(() {
        selectedClass = null; // Reset dropdown selection
      });
    } catch (e) {
      print('Error adding student: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add student.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // AMOLED background
      appBar: AppBar(
        title: Text(
          'Add Student',
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Student Name',
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
            TextField(
              controller: _rollNoController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Student Roll Number',
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
            Text(
              'Assign Class',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            DropdownButtonFormField<String>(
              value: selectedClass,
              items:
                  availableClasses.map((className) {
                    return DropdownMenuItem<String>(
                      value: className, // Use class name as value
                      child: Text(
                        className,
                        style: TextStyle(color: Colors.white),
                      ), // Display class name
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedClass = value; // Update the selected class
                });
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                labelText: 'Select Class',
                labelStyle: TextStyle(color: Colors.grey),
              ),
              dropdownColor: Color(
                0xFF161B22,
              ), // Background color of the dropdown menu
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: addStudent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("Add Student", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

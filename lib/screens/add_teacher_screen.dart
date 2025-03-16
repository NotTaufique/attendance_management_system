import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  _AddTeacherScreenState createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  final List<String> availableClasses = [
    "Fe A",
    "Fe B",
    "Fe C",
    "Fe D",
    "SE Comps",
    "TE Comps",
    "BE Comps"
  ]; // List of available classes

  List<String> selectedClasses = []; // Classes selected by the Admin

  Future<void> addTeacher() async {
    try {
      // Create teacher in Firebase Authentication
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Save teacher details in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': _emailController.text.trim(),
            'name': _nameController.text.trim(),
            'role': 'teacher',
            'assignedClasses': selectedClasses, // Save assigned classes
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Teacher added successfully!')));
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      setState(() {
        selectedClasses = []; // Reset selected classes
      });
    } catch (e) {
      print('Error adding teacher: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add teacher.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // AMOLED background
      appBar: AppBar(
        title: Text(
          'Add Teacher',
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
            TextField(
              controller: _emailController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
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
              controller: _passwordController,
              obscureText: true,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
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
              'Assign Classes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: availableClasses.length,
                itemBuilder: (context, index) {
                  final className = availableClasses[index];
                  return CheckboxListTile(
                    title: Text(
                      className,
                      style: TextStyle(color: Colors.white),
                    ),
                    value: selectedClasses.contains(className),
                    onChanged: (isSelected) {
                      setState(() {
                        if (isSelected == true) {
                          selectedClasses.add(className);
                        } else {
                          selectedClasses.remove(className);
                        }
                      });
                    },
                    activeColor: Colors.blueAccent, // Color for checked state
                    checkColor: Colors.white, // Color for checkmark
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: addTeacher,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("Add Teacher", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

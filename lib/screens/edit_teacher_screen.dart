import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTeacherScreen extends StatefulWidget {
  final String teacherId;
  final String currentName;
  final String currentEmail;
  final List<String> currentClasses;

  const EditTeacherScreen({
    Key? key,
    required this.teacherId,
    required this.currentName,
    required this.currentEmail,
    required this.currentClasses,
  }) : super(key: key);

  @override
  _EditTeacherScreenState createState() => _EditTeacherScreenState();
}

class _EditTeacherScreenState extends State<EditTeacherScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  final List<String> availableClasses = [
    "Fe A",
    "Fe B",
    "Fe C",
    "Fe D",
    "SE Comps",
    "TE Comps",
    "BE Comps",
  ];

  List<String> selectedClasses = [];
  List<String> assignedClasses = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _emailController.text = widget.currentEmail;
    fetchAssignedClasses(); // Fetch assigned classes
  }

  Future<void> fetchAssignedClasses() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.teacherId) // Correct document ID
              .get();

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        setState(() {
          assignedClasses = List<String>.from(data['assignedClasses'] ?? []);
          selectedClasses = List.from(assignedClasses); // Sync selectedClasses
        });
      }
    } catch (e) {
      print('Error fetching assigned classes: $e');
    }
  }

  Future<void> updateTeacher() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.teacherId)
          .update({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'assignedClasses': selectedClasses,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher details updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error updating teacher: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update teacher details.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Edit Teacher Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
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
                      style: const TextStyle(color: Colors.white),
                    ),
                    value: selectedClasses.contains(className),
                    onChanged:
                        (isChecked) => setState(() {
                          if (isChecked!) {
                            selectedClasses.add(className);
                          } else {
                            selectedClasses.remove(className);
                          }
                        }),
                    activeColor: Colors.blueAccent,
                    checkColor: Colors.white,
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: updateTeacher,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Update Teacher",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

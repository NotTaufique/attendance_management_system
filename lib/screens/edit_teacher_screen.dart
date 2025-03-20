import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class EditTeacherScreen extends StatefulWidget {
  final String teacherId;
  final String currentName;

  const EditTeacherScreen({
    super.key,
    required this.teacherId,
    required this.currentName,
  });

  @override
  _EditTeacherScreenState createState() => _EditTeacherScreenState();
}

class _EditTeacherScreenState extends State<EditTeacherScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final List<Map<String, dynamic>> _subjectControllers = [];
  final bool _isLoading = false;

  final List<String> classOptions = [
    "FE A",
    "FE B",
    "FE C",
    "FE D",
    "SE Comps",
    "TE Comps",
    "BE Comps",
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection('users').doc(widget.teacherId).get();

      if (doc.exists) {
        Map data = doc.data() as Map;
        _emailController.text = data['email'] ?? '';

        _subjectControllers.clear();
        for (var subject in data['subjects']) {
          _subjectControllers.add({
            'class': subject['class'],
            'subject': TextEditingController(text: subject['subject']),
          });
        }

        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading teacher data: $e');
    }
  }

  void _addSubjectField() {
    setState(() {
      _subjectControllers.add({'class': '', 'subject': TextEditingController()});
    });
  }

  void _removeSubjectField(int index) {
    setState(() {
      _subjectControllers.removeAt(index);
    });
  }

  Future<void> _saveTeacher() async {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      _showError('Name and Email cannot be empty.');
      return;
    }

    final Set<String> assignedClasses = {};

    for (var controller in _subjectControllers) {
      final className = controller['class'];
      final subject = controller['subject'].text.trim();

      if (className.isEmpty || subject.isEmpty) {
        _showError('Please fill all subject fields.');
        return;
      }

      if (assignedClasses.contains(className)) {
        _showError('Each class can be assigned only once.');
        return;
      }
      assignedClasses.add(className);
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.teacherId).update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'subjects': _subjectControllers
            .map((e) => {'class': e['class'], 'subject': e['subject'].text.trim()})
            .toList(),
      });

      // If password field is not empty, update Firebase Authentication password
      if (_passwordController.text.trim().isNotEmpty) {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updatePassword(_passwordController.text.trim());
        }
      }

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error updating teacher: $e');
      _showError('Failed to update teacher.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Edit Teacher', style: GoogleFonts.lato(color: Colors.blueAccent)),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Name TextField
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Name'),
            ),
            const SizedBox(height: 10),

            // Email TextField
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Email'),
            ),
            const SizedBox(height: 10),

            // Password TextField
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('New Password (Optional)'),
            ),
            const SizedBox(height: 20),

            // Subject Assignments
            Expanded(
              child: ListView.builder(
                itemCount: _subjectControllers.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _subjectControllers[index]['class'].isNotEmpty
                                  ? _subjectControllers[index]['class']
                                  : null,
                              items: classOptions.map((String classOption) {
                                return DropdownMenuItem<String>(
                                  value: classOption,
                                  child: Text(classOption, style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _subjectControllers[index]['class'] = value!;
                                });
                              },
                              dropdownColor: const Color(0xFF161B22),
                              decoration: _inputDecoration('Class'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _subjectControllers[index]['subject'],
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Subject'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeSubjectField(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              ),
            ),

            // Buttons in the same row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: _buttonStyle(Colors.greenAccent),
                    onPressed: _addSubjectField,
                    child: const Text('Add Subject', style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: _buttonStyle(Colors.blueAccent),
                    onPressed: _saveTeacher,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Changes', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF161B22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTeacherScreen extends StatefulWidget {
  final String? teacherId;

  const AddTeacherScreen({super.key, this.teacherId});

  @override
  _AddTeacherScreenState createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  List<Map<String, dynamic>> _subjectControllers = [];
  bool _isLoading = false;
  bool _isEditing = false;

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
    if (widget.teacherId != null) {
      _isEditing = true;
      _loadTeacherData(widget.teacherId!);
    }
  }

  Future<void> _loadTeacherData(String teacherId) async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection('users').doc(teacherId).get();
      if (doc.exists) {
        Map data = doc.data() as Map;

        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';

        _subjectControllers = List<Map<String, dynamic>>.from(
          data['subjects'].map(
            (subject) => {
              'class': subject['class'],
              'subject': TextEditingController(text: subject['subject']),
            },
          ),
        );

        setState(() {});
      } else {
        debugPrint("⚠️ Teacher document not found.");
      }
    } catch (e) {
      debugPrint('🔥 Error loading teacher data: $e');
    }
  }

  void _addSubjectField() {
    setState(() {
      _subjectControllers.add({
        'class': '',
        'subject': TextEditingController(),
      });
    });
  }

  void _removeSubjectField(int index) {
    setState(() {
      _subjectControllers.removeAt(index);
    });
  }

  Future<void> _saveTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final classSubjects = <String, String>{};

    for (var controller in _subjectControllers) {
      final className = controller['class'];
      final subject = controller['subject'].text.trim();

      if (className.isEmpty || subject.isEmpty) {
        _showError('Please fill all subject fields.');
        setState(() => _isLoading = false);
        return;
      }

      if (classSubjects.containsKey(className)) {
        _showError('Class "$className" is already assigned a subject.');
        setState(() => _isLoading = false);
        return;
      }
      classSubjects[className] = subject;
    }

    try {
      final usersCollection = FirebaseFirestore.instance.collection('users');

      if (_isEditing) {
        await usersCollection.doc(widget.teacherId).update({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'subjects': classSubjects.entries
              .map((e) => {'class': e.key, 'subject': e.value})
              .toList(),
        });
        debugPrint('✅ Teacher updated successfully.');
      } else {
        final newUser = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await usersCollection.doc(newUser.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'teacher',
          'subjects': classSubjects.entries
              .map((e) => {'class': e.key, 'subject': e.value})
              .toList(),
        });

        debugPrint('✅ New teacher added successfully.');
      }
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      debugPrint('🔥 Firebase Auth Error: ${e.code}, ${e.message}');
      _showError(e.message ?? 'An error occurred.');
    } catch (e) {
      debugPrint('💥 General Error: $e');
      _showError('Failed to save teacher.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Teacher' : 'Add Teacher'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                keyboardType: TextInputType.emailAddress,
              ),
              if (!_isEditing)
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  obscureText: true,
                ),
              const SizedBox(height: 20),
              const Text(
                'Subject Assignments:',
                style: TextStyle(fontSize: 18),
              ),
              ..._subjectControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controllers = entry.value;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: classOptions.contains(controllers['class'])
                                ? controllers['class']
                                : null,
                            hint: const Text('Select Class'),
                            decoration: const InputDecoration(
                              labelText: 'Class',
                            ),
                            items: classOptions.map((String classOption) {
                              return DropdownMenuItem<String>(
                                value: classOption,
                                child: Text(classOption),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => controllers['class'] = value!);
                            },
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: controllers['subject'],
                            decoration: const InputDecoration(
                              labelText: 'Subject',
                            ),
                            validator: (value) => value!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => _removeSubjectField(index),
                        ),
                      ],
                    ),
                    const Divider(),
                  ],
                );
              }),
              ElevatedButton(
                onPressed: _addSubjectField,
                child: const Text('Add Another Subject'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTeacher,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Teacher'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

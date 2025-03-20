import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'admin_dashboard.dart';
import 'teacher_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _rememberMe = false;
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
    });

    if (_rememberMe) {
      _emailController.text = await _storage.read(key: 'email') ?? '';
      _passwordController.text = await _storage.read(key: 'password') ?? '';
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await _storage.write(key: 'email', value: _emailController.text.trim());
      await _storage.write(
        key: 'password',
        value: _passwordController.text.trim(),
      );
      await prefs.setBool('rememberMe', true);
    } else {
      await _storage.delete(key: 'email');
      await _storage.delete(key: 'password');
      await prefs.setBool('rememberMe', false);
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      await _saveCredentials();

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final role = userData?['role'] as String? ?? '';

        debugPrint('✅ Login successful - User Role: $role');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userRole', role);

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminDashboard()),
          );
        } else if (role == 'teacher') {
          final assignedClasses =
              (userData?['subjects'] as List<dynamic>?)
                  ?.map((subject) => subject as Map<String, dynamic>)
                  .toList() ??
              [];

          debugPrint('📚 Assigned Classes: $assignedClasses');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      TeacherDashboard(assignedClasses: assignedClasses),
            ),
          );
        } else {
          _showError('Unknown role assigned. Contact administrator.');
        }
      } else {
        _showError('User does not exist in Firestore. Contact administrator.');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '🔥 Firebase Auth Error: Code: ${e.code}, Message: ${e.message}',
      );
      if (e.code == 'wrong-password' || e.code == 'user-not-found') {
        _showError('Invalid email or password. Please try again.');
      } else if (e.code == 'network-request-failed') {
        _showError('Network error. Check your internet connection.');
      } else if (e.code == 'too-many-requests') {
        _showError('Too many login attempts. Please try again later.');
      } else {
        _showError('Error: ${e.message}');
      }
    } catch (e) {
      debugPrint('💥 General Exception: ${e.toString()}');
      _showError('Unexpected error occurred. Try again later.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Theem Tracker',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  _emailController,
                  'Email',
                  Icons.email_outlined,
                  false,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  _passwordController,
                  'Password',
                  Icons.lock_outline,
                  true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isPassword,
  ) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_passwordVisible : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                )
                : null,
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

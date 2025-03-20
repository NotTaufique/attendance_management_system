import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:attendance_management_system/screens/login_screen.dart';
import 'package:attendance_management_system/screens/admin_dashboard.dart';
import 'package:attendance_management_system/screens/teacher_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final storage = FlutterSecureStorage();

  // Check if 'rememberMe' is true
  bool rememberMe = prefs.getBool('rememberMe') ?? false;

  String initialRoute = '/login'; // Default route

  if (rememberMe) {
    // Check for saved credentials
    String? email = await storage.read(key: 'email');
    String? password = await storage.read(key: 'password');

    if (email != null && password != null) {
      // Check user role and set initial route
      String userRole = prefs.getString('userRole') ?? '';
      if (userRole == 'admin') {
        initialRoute = '/admin';
      } else if (userRole == 'teacher') {
        initialRoute = '/teacher';
      }
    }
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: initialRoute,
      routes: {
        '/': (context) => LoginScreen(),
        '/admin': (context) => AdminDashboard(),
        '/teacher': (context) => TeacherDashboard(assignedClasses: []),
      },
    );
  }
}

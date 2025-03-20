import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'view_teachers_screen.dart';
import 'view_students_screen.dart';
import 'add_teacher_screen.dart';
import 'add_student_screen.dart';
import 'report_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _storage = FlutterSecureStorage();
  int totalStudents = 0;
  int totalTeachers = 0;
  int totalLectures = 0;
  bool isLoading = true;
  List<FlSpot> attendanceData = const [
    FlSpot(0, 75),
    FlSpot(1, 80),
    FlSpot(2, 90),
    FlSpot(3, 85),
    FlSpot(4, 95),
    FlSpot(5, 70),
    FlSpot(6, 80),
  ];

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    try {
      // Fetch total students
      QuerySnapshot studentsSnapshot = await FirebaseFirestore.instance.collection('students').get();
      totalStudents = studentsSnapshot.docs.length;

      // Fetch total teachers from users collection with role 'teacher'
      QuerySnapshot teachersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();
      totalTeachers = teachersSnapshot.docs.length;

      // Fetch total lectures
      QuerySnapshot lecturesSnapshot = await FirebaseFirestore.instance.collection('attendance').get();
      totalLectures = lecturesSnapshot.docs.length;

      // Fetch real data for the graph (example data, adjust according to your data structure)
      attendanceData = await getRealAttendanceData();
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Function to fetch real data for the attendance graph (example)
  Future<List<FlSpot>> getRealAttendanceData() async {
    // Implement your logic to fetch the real attendance data from Firebase
    // This is a placeholder implementation that returns sample data
    // Replace this logic with your own data retrieval process
    List<FlSpot> realData = [];
    for (int i = 0; i < 7; i++) {
      // Generate random attendance percentages for each day of the week
      double attendancePercentage = (70 + (i * 5) % 30).toDouble(); // Example data
      realData.add(FlSpot(i.toDouble(), attendancePercentage));
    }
    return realData;
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'password');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', false);
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _buildStatCard(
          Icons.people_alt_outlined,
          'Students',
          totalStudents.toString(),
          Colors.blueAccent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ViewStudentsScreen()),
          ),
        ),
        _buildStatCard(
          Icons.school_outlined,
          'Teachers',
          totalTeachers.toString(),
          Colors.greenAccent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ViewTeachersScreen()),
          ),
        ),
        _buildStatCard(
          Icons.library_books_outlined,
          'Lectures',
          totalLectures.toString(),
          Colors.orangeAccent,
        ),
        _buildStatCard(
          Icons.analytics_outlined,
          'Generate Reports',
          '',
          Colors.purpleAccent,
          onTap: () async {
            String? selectedClass = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Select Class'),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: [
                        "FE A",
                        "FE B",
                        "FE C",
                        "FE D",
                        "SE Comps",
                        "TE Comps",
                        "BE Comps",
                      ]
                          .map((className) => GestureDetector(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(className),
                                ),
                                onTap: () => Navigator.of(context).pop(className),
                              ))
                          .toList(),
                    ),
                  ),
                );
              },
            );
            if (selectedClass != null) {
              DateTime? startDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 30)),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                selectableDayPredicate: (DateTime val) => val.weekday != 6 && val.weekday != 7,
                builder: (BuildContext context, Widget? child) {
                  return Theme(
                    data: ThemeData.dark(),
                    child: child!,
                  );
                },
              );
              if (startDate != null) {
                DateTime? endDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: startDate,
                  lastDate: DateTime.now(),
                  selectableDayPredicate: (DateTime val) => val.weekday != 6 && val.weekday != 7,
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      data: ThemeData.dark(),
                      child: child!,
                    );
                  },
                );
                if (endDate != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportScreen(
                        selectedClass: selectedClass,
                        startDate: startDate,
                        endDate: endDate,
                      ),
                    ),
                  );
                }
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String title,
    String value,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 34),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (value.isNotEmpty) const SizedBox(height: 6),
            if (value.isNotEmpty)
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white24, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final days = [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun',
                ];
                return Text(
                  days[value.toInt()],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white24),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: attendanceData,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blueAccent.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphCard() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade900, Colors.grey.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Attendance Overview',
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _buildLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Welcome, Admin!',
          style: GoogleFonts.lato(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Stats Grid
            SizedBox(height: 280, child: _buildStatsGrid()),
            // Graph Section
            _buildGraphCard(),
            // Add Buttons Section
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    'Add Student',
                    Icons.person_add,
                    Colors.blueAccent,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddStudentScreen(),
                      ),
                    ),
                  ),
                  _buildActionButton(
                    'Add Teacher',
                    Icons.person_add_alt_1,
                    Colors.greenAccent,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddTeacherScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
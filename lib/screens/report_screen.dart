import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import flutter_spinkit

class ReportScreen extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String selectedClass;

  const ReportScreen({
    super.key,
    required this.selectedClass,
    required this.startDate,
    required this.endDate,
  });

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<Map> attendanceData = [];
  String searchQuery = '';
  bool isLoading = true; // Added loading state

  Future<List<Map>> fetchAttendanceData() async {
    final firestore = FirebaseFirestore.instance;
    Query query = firestore.collection('attendance').where('class', isEqualTo: widget.selectedClass);

    if (widget.startDate != null && widget.endDate != null) {
      query = query
          .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(widget.startDate!))
          .where('date', isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(widget.endDate!));
    }

    final snapshot = await query.get();

    Map<String, Map<String, int>> studentSubjectAttendance = {};
    Map<String, int> subjectTotalLectures = {};
    Map<String, String> studentNames = {};
    Map<String, String> studentRollNos = {};
    Set<String> countedDates = {};

    for (var doc in snapshot.docs) {
      DateTime date = DateTime.parse(doc['date']);
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) continue;

      String studentId = doc['studentId'];
      String subject = doc['subject'] ?? 'Unknown Subject';
      String status = doc['status'];

      String uniqueKey = '$subject-${DateFormat('yyyy-MM-dd').format(date)}';
      if (!countedDates.contains(uniqueKey)) {
        subjectTotalLectures[subject] = (subjectTotalLectures[subject] ?? 0) + 1;
        countedDates.add(uniqueKey);
      }

      if (!studentNames.containsKey(studentId)) {
        DocumentSnapshot studentDoc =
            await firestore.collection('students').doc(studentId).get();
        studentNames[studentId] = studentDoc['name'] ?? 'Unknown Student';
        studentRollNos[studentId] = studentDoc['rollNo'].toString();
      }

      studentSubjectAttendance.putIfAbsent(studentId, () => {});
      if (status == 'Present') {
        studentSubjectAttendance[studentId]!.putIfAbsent(subject, () => 0);
        studentSubjectAttendance[studentId]![subject] =
            studentSubjectAttendance[studentId]![subject]! + 1;
      }
    }

    List<Map> attendanceList = [];

    // Create a list of attendance data
    studentNames.forEach((studentId, studentName) {
      Map<String, String> subjectWiseAttendance = {};
      int totalAttended = 0;
      int totalLectures = 0;

      subjectTotalLectures.forEach((subject, total) {
        int attended = studentSubjectAttendance[studentId]?[subject] ?? 0;
        double percentage = (total > 0) ? (attended / total) * 100 : 0;

        subjectWiseAttendance[subject] = '$attended/$total';
        totalAttended += attended;
        totalLectures += total;
      });

      double overallAttendancePercentage =
          (totalLectures > 0) ? (totalAttended / totalLectures) * 100 : 0;
      if (overallAttendancePercentage > 100) overallAttendancePercentage = 100;

      attendanceList.add({
        'studentName': studentName,
        'studentId': studentId,
        'studentRollNo': studentRollNos[studentId],
        'attendancePercentage': overallAttendancePercentage,
        'subjectAttendance': subjectWiseAttendance,
      });
    });

    // Sort attendance data by roll number
    attendanceList.sort((a, b) => a['studentRollNo'].compareTo(b['studentRollNo']));

    return attendanceList;
  }

  void showStudentDetails(BuildContext context, Map attendanceRecord) {
    String studentName = attendanceRecord['studentName'];
    String studentRollNo = attendanceRecord['studentRollNo'];
    double attendancePercentage = attendanceRecord['attendancePercentage'];
    Map subjectAttendance = attendanceRecord['subjectAttendance'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF21262D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return VStack([
          "Student Details".text.xl2.white.bold.make().p16(),
          Divider(color: Colors.white.withOpacity(0.5)),
          HStack([
            "Name: ".text.white.bold.make(),
            "$studentName".text.white.make().expand(),
          ]).p8(),
          HStack([
            "Roll No: ".text.white.bold.make(),
            "$studentRollNo".text.white.make().expand(),
          ]).p8(),
          HStack([
            "Overall Attendance: ".text.white.bold.make(),
            "${attendancePercentage.toStringAsFixed(2)}%".text.blue400.bold.make().expand(),
          ]).p8(),
          Divider(color: Colors.white.withOpacity(0.5)),
          "Subject-wise Attendance".text.xl.white.bold.make().p8(),
          ...subjectAttendance.entries.map((entry) {
            return HStack([
              "${entry.key}: ".text.white.bold.make(),
              "${entry.value}".text.white.make().expand(),
            ]).p8();
          }).toList(),
        ]).scrollVertical();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchAttendanceData().then((data) {
      setState(() {
        attendanceData = data; // Store fetched data
        isLoading = false; // Set loading to false after data is fetched
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: 'Attendance Reports'.text.xl.white.bold.make(),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase(); // Update search query
                });
              },
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or roll number',
                hintStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ).pOnly(bottom: 16),

            // List of Students
            Expanded(
              child: Builder(
                builder: (context) {
                  if (isLoading) {
                    return Center(
                      child: SpinKitFadingCircle(
                        color: Colors.blueAccent,
                        size: 50.0,
                      ),
                    );
                  } else if (attendanceData.isEmpty) {
                    return Center(
                      child: "No students found.".text.gray500.xl.make(),
                    );
                  } else {
                    return ListView.builder(
                      itemCount: attendanceData.length,
                      itemBuilder: (context, index) {
                        var attendanceRecord = attendanceData[index];

                        // Filter based on search query
                        if (!attendanceRecord['studentName'].toLowerCase().contains(searchQuery) &&
                            !attendanceRecord['studentRollNo'].toString().contains(searchQuery)) {
                          return SizedBox.shrink(); // Skip this item
                        }

                        return Card(
                          color: const Color(0xFF21262D),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Text(
                                attendanceRecord['studentRollNo'],
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              attendanceRecord['studentName'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${attendanceRecord['attendancePercentage'].toStringAsFixed(2)}% Attendance',
                              style: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing:
                                Icon(Icons.info_outline, color: Colors.lightBlueAccent), // Info icon at the end
                            onTap: () => showStudentDetails(context, attendanceRecord),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

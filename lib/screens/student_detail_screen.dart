import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentName;
  final String studentId;
  final String selectedClass;
  final DateTime? startDate;
  final DateTime? endDate;

  const StudentDetailScreen({
    super.key,
    required this.studentName,
    required this.studentId,
    required this.selectedClass,
    required this.startDate,
    required this.endDate,
  });

  @override
  _StudentDetailScreenState createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  Future<Map<String, String>> fetchSubjectAttendanceData() async {
    final firestore = FirebaseFirestore.instance;
    Query query = firestore.collection('attendance')
      .where('class', isEqualTo: widget.selectedClass)
      .where('studentId', isEqualTo: widget.studentId);

    if (widget.startDate != null && widget.endDate != null) {
      query = query
          .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(widget.startDate!))
          .where('date', isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(widget.endDate!));
    }

    final snapshot = await query.get();

    Map<String, int> subjectAttendanceCount = {};
    Map<String, int> subjectTotalLectures = {};
    Set<String> countedDates = {}; // Ensures lectures are counted only once per day per subject

    for (var doc in snapshot.docs) {
      DateTime date = DateTime.parse(doc['date']);
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) continue;

      String subject = doc['subject'] ?? 'Unknown Subject';
      String status = doc['status'];

      String uniqueKey = '$subject-${DateFormat('yyyy-MM-dd').format(date)}';
      if (!countedDates.contains(uniqueKey)) {
        subjectTotalLectures[subject] = (subjectTotalLectures[subject] ?? 0) + 1;
        countedDates.add(uniqueKey);
      }

      if (status == 'Present') {
        subjectAttendanceCount[subject] = (subjectAttendanceCount[subject] ?? 0) + 1;
      }
    }

    return subjectAttendanceCount.map((subject, attended) {
      int total = subjectTotalLectures[subject] ?? 1; // Avoid division by zero
      return MapEntry(subject, '$attended/$total');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Details for ${widget.studentName}'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<Map<String, String>>(
        future: fetchSubjectAttendanceData(),
        builder: (context, AsyncSnapshot<Map<String, String>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching data: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          final subjectReport = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView.builder(
              itemCount: subjectReport.length,
              itemBuilder: (context, index) {
                String subject = subjectReport.keys.elementAt(index);
                String attendance = subjectReport[subject]!;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      '$subject: $attendance',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

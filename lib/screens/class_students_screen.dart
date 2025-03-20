import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:async';

// Constants
const String STUDENTS_COLLECTION = 'students';
const String ATTENDANCE_COLLECTION = 'attendance';
const String CLASS_FIELD = 'class';
const String TEACHER_ID_FIELD = 'teacherId';
const String DATE_FIELD = 'date';
const String STUDENT_ID_FIELD = 'studentId';
const String STATUS_FIELD = 'status';
const String NAME_FIELD = 'name';
const String ROLL_NO_FIELD = 'rollNo';
const String SUBJECT_FIELD = 'subject'; // Added subject field

class ClassStudentsScreen extends StatefulWidget {
  final String className;
  final String subjectName;
  const ClassStudentsScreen({Key? key, required this.className, required this.subjectName}) : super(key: key);
  @override
  _ClassStudentsScreenState createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends State<ClassStudentsScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  Map<String, dynamic> _attendanceStatus = {};
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;
  List<DateTime> _eventDates = [];
  final DateFormat _dateFormat = DateFormat('EEE, MMM d, yyyy');
  final DateFormat _dateFormatFirebase = DateFormat('yyyy-MM-dd');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late DateTime _lastSelectableDay; // Store the latest date

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    _lastSelectableDay = DateTime(now.year, now.month, now.day);
    _selectedDay = DateTime(now.year, now.month, now.day); // Initialize selected day to today
    _focusedDay = now;
    _searchController.addListener(_onSearchChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _teacherId => FirebaseAuth.instance.currentUser?.uid ?? "unknown_teacher";
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadInitialData() async {
    await _loadStudents();
    await _loadEventDates();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(STUDENTS_COLLECTION)
          .where(CLASS_FIELD, isEqualTo: widget.className)
          .get();
      List<Map<String, dynamic>> students = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc[NAME_FIELD],
          'rollNo': doc[ROLL_NO_FIELD],
        };
      }).toList();
      students.sort((a, b) => (a[ROLL_NO_FIELD] as int).compareTo(b[ROLL_NO_FIELD] as int));
      setState(() {
        _students = students;
      });
      await _loadAttendanceForDate(_selectedDay);
    } catch (e) {
      _showError('Failed to load students: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEventDates() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(ATTENDANCE_COLLECTION)
          .where(CLASS_FIELD, isEqualTo: widget.className)
          .where(TEACHER_ID_FIELD, isEqualTo: _teacherId)
          .where(SUBJECT_FIELD, isEqualTo: widget.subjectName)
          .get();
      final dates = snapshot.docs.map((doc) => _dateFormatFirebase.parse(doc[DATE_FIELD])).toSet();
      setState(() => _eventDates = dates.toList());
    } catch (e) {
      _showError('Failed to load attendance dates: $e');
    }
  }

  Future<void> _loadAttendanceForDate(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      final formattedDate = _dateFormatFirebase.format(date);
      final snapshot = await FirebaseFirestore.instance
          .collection(ATTENDANCE_COLLECTION)
          .where(CLASS_FIELD, isEqualTo: widget.className)
          .where(TEACHER_ID_FIELD, isEqualTo: _teacherId)
          .where(DATE_FIELD, isEqualTo: formattedDate)
          .where(SUBJECT_FIELD, isEqualTo: widget.subjectName) // Load attendance for selected subject
          .get();
      setState(() {
        _attendanceStatus = {
          for (var doc in snapshot.docs) doc[STUDENT_ID_FIELD]: doc[STATUS_FIELD],
        };
        _selectedDay = date; // Ensure selected day is updated
        _focusedDay = date; // Ensure focused day is updated
      });
    } catch (e) {
      _showError('Failed to load attendance: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Confirm Save',
      content: 'Save attendance for ${_dateFormat.format(_selectedDay)}?',
      confirmText: 'Save',
    );
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final formattedDate = _dateFormatFirebase.format(_selectedDay);
      _attendanceStatus.forEach((studentId, status) {
        if (status != 'Present' && status != 'Absent') {
          throw Exception('Invalid attendance status: $status');
        }
        final docId = '${widget.className}_${_teacherId}_${studentId}_$formattedDate';
        final docRef = FirebaseFirestore.instance.collection(ATTENDANCE_COLLECTION).doc(docId);
        batch.set(docRef, {
          TEACHER_ID_FIELD: _teacherId,
          STUDENT_ID_FIELD: studentId,
          CLASS_FIELD: widget.className,
          DATE_FIELD: formattedDate,
          STATUS_FIELD: status,
          SUBJECT_FIELD: widget.subjectName,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
      await batch.commit();
      await _loadEventDates();
      _showSuccess('Attendance saved successfully!');
    } catch (e) {
      _showError('Failed to save attendance: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showCalendarOverlay(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) {
          return Scaffold(
            backgroundColor: Colors.black.withOpacity(0.8),
            body: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dateFormat.format(_focusedDay),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.now().add(const Duration(days:365*2)),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                              _loadAttendanceForDate(selectedDay);
                              Navigator.pop(context);
                            },
                            eventLoader: (day) {
                              if (_eventDates.any((date) => isSameDay(date, day))) {
                                return ['Attendance'];
                              }
                              return [];
                            },
                            calendarBuilders: CalendarBuilders(
                              todayBuilder: (context, day, focusedDay) {
                                return Container(
                                  margin: const EdgeInsets.all(4.0),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      day.day.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              selectedBuilder: (context, day, selectedDay) {
                                return Container(
                                  margin: const EdgeInsets.all(4.0),
                                  decoration: BoxDecoration(
                                    color: isSameDay(day, _selectedDay)
                                        ? Colors.blueAccent
                                        : Colors.transparent, // Set blue accent only for selected date
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      day.day.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            calendarStyle: const CalendarStyle(
                              markerDecoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              defaultTextStyle: TextStyle(color: Colors.white),
                              weekendTextStyle: TextStyle(color: Colors.white),
                              outsideTextStyle: TextStyle(color: Colors.grey),
                              selectedTextStyle: TextStyle(color: Colors.white),
                              todayTextStyle: TextStyle(color: Colors.white),
                              cellMargin: EdgeInsets.all(4.0),
                              disabledTextStyle: TextStyle(color: Colors.grey),
                            ),
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: TextStyle(color: Colors.white),
                              leftChevronIcon: Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                              ),
                              rightChevronIcon: Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                              ),
                            ),
                            daysOfWeekStyle: const DaysOfWeekStyle(
                              weekdayStyle: TextStyle(color: Colors.white),
                              weekendStyle: TextStyle(color: Colors.red),
                            ),
                            availableCalendarFormats: const {
                              CalendarFormat.month: 'Month',
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final className = widget.className; // Store className in a local variable
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            className, // Use the local variable here
            style: GoogleFonts.lato(color: Colors.blueAccent),
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                widget.subjectName,
                style: GoogleFonts.lato(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or roll number',
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _markAll('Present'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  "Mark All Present",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () => _markAll('Absent'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  "Mark All Absent",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          Expanded(child: _buildStudentList()),
          // Buttons Row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _saveAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    "Save Attendance",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _showCalendarOverlay(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    "Open Calendar",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Selected Date Sticky Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            color: Colors.grey[800],
            child: Center(
              child: Text(
                'Selected Date: ${_dateFormat.format(_selectedDay)}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    final filteredStudents = _students.where((student) {
      final nameMatches = student[NAME_FIELD].toLowerCase().contains(_searchQuery);
      final rollMatches = student[ROLL_NO_FIELD].toString().contains(_searchQuery);
      return nameMatches || rollMatches;
    }).toList();
    return ListView.builder(
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        final status = _attendanceStatus[student['id']] ?? 'Absent';
        return Card(
          color: Colors.black,
          child: ListTile(
            title: Text(
              student[NAME_FIELD],
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              "Roll No: ${student[ROLL_NO_FIELD]}",
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _attendanceStatus[student['id']] = 'Present';
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: status == 'Present' ? Colors.green : Colors.grey[800],
                  ),
                  child: const Text('P', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _attendanceStatus[student['id']] = 'Absent';
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: status == 'Absent' ? Colors.red : Colors.grey[800],
                  ),
                  child: const Text('A', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _markAll(String status) {
    setState(() {
      for (var student in _students) {
        _attendanceStatus[student['id']] = status;
      }
    });
  }
}

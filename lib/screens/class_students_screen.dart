import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class ClassStudentsScreen extends StatefulWidget {
  final String className;

  const ClassStudentsScreen({Key? key, required this.className})
    : super(key: key);

  @override
  _ClassStudentsScreenState createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends State<ClassStudentsScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  Map<String, String> _attendanceStatus = {};
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;
  List<DateTime> _eventDates = [];
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _searchController.addListener(_onSearchChanged);
    _loadInitialData();
  }

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
      final snapshot =
          await FirebaseFirestore.instance
              .collection('students')
              .where('class', isEqualTo: widget.className)
              .get();

      // Convert documents to list and sort by roll number
      List<Map<String, dynamic>> students =
          snapshot.docs.map((doc) {
            return {'id': doc.id, 'name': doc['name'], 'rollNo': doc['rollNo']};
          }).toList();

      students.sort(
        (a, b) => (a['rollNo'] as int).compareTo(b['rollNo'] as int),
      );

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
      final snapshot =
          await FirebaseFirestore.instance
              .collection('attendance')
              .where('class', isEqualTo: widget.className)
              .get();

      final dates =
          snapshot.docs.map((doc) {
            return _dateFormat.parse(doc['date']);
          }).toSet();

      setState(() => _eventDates = dates.toList());
    } catch (e) {
      _showError('Failed to load attendance dates: $e');
    }
  }

  Future<void> _loadAttendanceForDate(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      final formattedDate = _dateFormat.format(date);
      final snapshot =
          await FirebaseFirestore.instance
              .collection('attendance')
              .where('class', isEqualTo: widget.className)
              .where('date', isEqualTo: formattedDate)
              .get();

      setState(() {
        _attendanceStatus = {
          for (var doc in snapshot.docs) doc['studentId']: doc['status'],
        };
      });
    } catch (e) {
      _showError('Failed to load attendance: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Confirm Save',
              style: TextStyle(color: Colors.blueAccent),
            ),
            content: Text(
              'Save attendance for ${_dateFormat.format(_selectedDay)}?',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF161B22),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Save', style: TextStyle(color: Colors.blueAccent)),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final formattedDate = _dateFormat.format(_selectedDay);

      _attendanceStatus.forEach((studentId, status) {
        final docId = '${widget.className}_${studentId}_$formattedDate';
        final docRef = FirebaseFirestore.instance
            .collection('attendance')
            .doc(docId);
        batch.set(docRef, {
          'studentId': studentId,
          'class': widget.className,
          'date': formattedDate,
          'status': status,
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

  Future<void> _clearAttendanceForDate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Confirm Clear Attendance',
              style: TextStyle(color: Colors.blueAccent),
            ),
            content: Text(
              'Are you sure you want to clear all attendance records for ${_dateFormat.format(_selectedDay)}?',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF161B22),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Clear',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final formattedDate = _dateFormat.format(_selectedDay);
      final snapshot =
          await FirebaseFirestore.instance
              .collection('attendance')
              .where('class', isEqualTo: widget.className)
              .where('date', isEqualTo: formattedDate)
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      await _loadAttendanceForDate(_selectedDay);
      await _loadEventDates();
      _showSuccess('Attendance cleared successfully!');
    } catch (e) {
      _showError('Failed to clear attendance: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleBulkAction(String status) {
    setState(() {
      _attendanceStatus = {
        for (var student in _students) student['id']: status,
      };
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  int get presentCount =>
      _attendanceStatus.values.where((v) => v == 'Present').length;
  int get totalStudents => _students.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.className,
          style: GoogleFonts.lato(color: Colors.blueAccent),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search students...',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Display Summary
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '$presentCount / $totalStudents Present',
              style: TextStyle(color: Colors.blueAccent, fontSize: 16),
            ),
          ),

          // Bulk Actions
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _handleBulkAction('Present'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    'Mark All Present',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _handleBulkAction('Absent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: Text(
                    'Mark All Absent',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Student List
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final studentId = student['id'];
                        final studentName = student['name'];
                        final studentRollNo = student['rollNo'];

                        // Filter student based on search query
                        if (_searchQuery.isNotEmpty &&
                            !studentName.toLowerCase().contains(_searchQuery) &&
                            !studentRollNo.toString().toLowerCase().contains(
                              _searchQuery,
                            )) {
                          return SizedBox.shrink(); // Skip this tile if it doesn't match the search query
                        }

                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade900),
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              '$studentRollNo. $studentName',
                              style: TextStyle(color: Colors.white),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Present Button
                                IconButton(
                                  icon: Icon(
                                    Icons.check_circle,
                                    color:
                                        _attendanceStatus[studentId] ==
                                                'Present'
                                            ? Colors.green
                                            : Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _attendanceStatus[studentId] = 'Present';
                                    });
                                  },
                                ),
                                // Absent Button
                                IconButton(
                                  icon: Icon(
                                    Icons.cancel,
                                    color:
                                        _attendanceStatus[studentId] == 'Absent'
                                            ? Colors.redAccent
                                            : Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _attendanceStatus[studentId] = 'Absent';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),

          // Sticky and Collapsible Calendar
          Container(
            color: Color(0xFF161B22), // Same background as other components
            child: ExpansionTile(
              title: Text(
                DateFormat(
                  'MMMM d, yyyy',
                ).format(_selectedDay), // Format selected date
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF161B22),
              children: <Widget>[
                TableCalendar(
                  firstDay: DateTime.utc(2010, 1, 1),
                  lastDay: DateTime.now(),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _loadAttendanceForDate(selectedDay);
                    print('Selected date: $_selectedDay');
                  },
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: TextStyle(color: Colors.white),
                    weekendTextStyle: TextStyle(color: Colors.red),
                    outsideTextStyle: TextStyle(color: Colors.grey),
                    selectedDecoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.blueGrey,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonTextStyle: TextStyle(color: Colors.white),
                    titleTextStyle: TextStyle(color: Colors.white),
                    formatButtonDecoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                    ),
                  ),
                  eventLoader: (day) {
                    return _eventDates
                        .where((date) => isSameDay(date, day))
                        .toList();
                  },
                ),
              ],
            ),
          ),

          // Save and Clear Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Attendance',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _clearAttendanceForDate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Clear Attendance',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

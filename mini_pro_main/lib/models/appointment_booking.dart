import 'package:flutter/material.dart';
import 'package:mini_pro_main/models/doctors.dart';
//import 'package:mini_pro_main/screens/home_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'timeslotpg.dart';

class DoctorCard extends StatefulWidget {
  final Doctor doctor;

  DoctorCard({required this.doctor});

  @override
  _DoctorCardState createState() => _DoctorCardState();
}

class _DoctorCardState extends State<DoctorCard> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, dynamic>? _doctorInfo;

  @override
  void initState() {
    super.initState();
    _fetchDoctorInfo();
  }

  Future<bool> _hasScheduleForSelectedDay(DateTime selectedDate) async {
    try {
      // Get the doctor's document ID from the 'doctors' collection
      final doctorSnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .where('name', isEqualTo: widget.doctor.name)
          .get();

      if (doctorSnapshot.docs.isNotEmpty) {
        final doctorId = doctorSnapshot.docs.first.id;

        // Query the 'schedules' subcollection for the given doctorId and selectedDate
        final scheduleSnapshot = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorId)
            .collection('schedules')
            .where('date', isEqualTo: Timestamp.fromDate(selectedDate))
            .get();

        return scheduleSnapshot.docs.isNotEmpty;
      }
    } catch (e) {
      // Handle any exceptions
      print('Error fetching doctor schedule: $e');
    }

    return false;
  }

  Future<void> _fetchDoctorInfo() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .where('name', isEqualTo: widget.doctor.name)
          .get();
      final data = snapshot.docs.first.data();
      setState(() {
        _doctorInfo = data;
      });
    } catch (e) {
      // Handle any exceptions
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              // Handle more options
            },
          ),
        ],
      ),
      body: _doctorInfo == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // Wrap with SingleChildScrollView
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircleAvatar(
                      radius: 50.0,
                      backgroundImage:
                          NetworkImage(_doctorInfo!['imageUrl'] ?? ''),
                    ),
                  ),
                  Text(
                    _doctorInfo!['speciality'] ?? '',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    _doctorInfo!['name'],
                    style: TextStyle(
                      fontSize: 18.0,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.location_on),
                        onPressed: () {
                          // Handle location button press
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _doctorInfo!['about'],
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TableCalendar(
                    firstDay: DateTime.utc(2023, 1, 1),
                    lastDay: DateTime.utc(2024, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () async {
                      if (_selectedDay != null) {
                        final hasSchedule =
                            await _hasScheduleForSelectedDay(_selectedDay!);
                        if (hasSchedule) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TimeSlotPage(
                                selectedDate: _selectedDay!,
                                doctor: widget.doctor,
                              ),
                            ),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Doctor Not Available'),
                              content: Text(
                                  'The doctor is not available on the selected date.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Book Appointment'),
                  ),
                ],
              ),
            ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mini_pro_main/models/doctors.dart';

class TimeSlotPage extends StatefulWidget {
  final DateTime selectedDate;
  final Doctor doctor;

  const TimeSlotPage({
    Key? key,
    required this.selectedDate,
    required this.doctor,
  }) : super(key: key);

  @override
  _TimeSlotPageState createState() => _TimeSlotPageState();
}

class _TimeSlotPageState extends State<TimeSlotPage> {
  List<String> _availableTimeSlots = [];
  List<String> _bookedTimeSlots = [];
  late String userId;
  late String userName;

  @override
  void initState() {
    super.initState();
    _fetchTimeSlots();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
        userName = user.displayName ?? '';
      });
    }
  }

  Future<void> _fetchTimeSlots() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .where('name', isEqualTo: widget.doctor.name)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doctorDoc = snapshot.docs.first;
        final scheduleSnapshot = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorDoc.id)
            .collection('schedules')
            .get();

        if (scheduleSnapshot.docs.isNotEmpty) {
          final scheduleDoc = scheduleSnapshot.docs.first;
          final timeSlotsSnapshot = await FirebaseFirestore.instance
              .collection('doctors')
              .doc(doctorDoc.id)
              .collection('schedules')
              .doc(scheduleDoc.id)
              .get();

          if (timeSlotsSnapshot.exists) {
            final timeSlotsData = timeSlotsSnapshot.data()?['timeslots'];

            if (timeSlotsData != null && timeSlotsData is List) {
              final fetchedTimeSlots = timeSlotsData.cast<String>();

              // Fetch booked time slots
              final bookedSlotsSnapshot = await timeSlotsSnapshot.reference
                  .collection('bookedSlots')
                  .get();
              final bookedTimeSlots = bookedSlotsSnapshot.docs
                  .map((doc) => doc.data()['timeSlot'] as String)
                  .toList();

              setState(() {
                _availableTimeSlots = fetchedTimeSlots
                    .where((timeSlot) => !bookedTimeSlots.contains(timeSlot))
                    .toList();
                _bookedTimeSlots = bookedTimeSlots;
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching time slots: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Appointments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'AVAILABLE\nAPPOINTMENTS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '${widget.selectedDate.day} ${_getMonth(widget.selectedDate.month)} ${widget.selectedDate.year}',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
                    children: [
                      // Display available time slots as clickable buttons
                      ..._availableTimeSlots.map((timeSlot) {
                        return TimeSlotButton(timeSlot, this);
                      }).toList(),
                      // Display booked time slots as disabled (red) buttons
                      ..._bookedTimeSlots.map((bookedTimeSlot) {
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 5),
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            bookedTimeSlot,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                if (_selectedTimeSlot != null) {
                  bookAppointment(_selectedTimeSlot!);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentConfirmationPage(
                        dateTimestamp: Timestamp.fromDate(
                            widget.selectedDate), // Pass the Timestamp object
                        timeSlot: _selectedTimeSlot!,
                      ),
                    ),
                  );
                } else {
                  // Show an error message or handle the case when no time slot is selected
                }
              },
              child: Text('Confirm Slot'),
            ),
          ),
        ],
      ),
    );
  }

  String? _selectedTimeSlot;

  void _selectTimeSlot(String timeSlot) {
    setState(() {
      _selectedTimeSlot = timeSlot;
    });
  }

  String _getMonth(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }

  Future<void> bookAppointment(String timeSlot) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Handle the case when the user is not authenticated
        print('User is not authenticated');
        return;
      }

      final userId = user.uid;
      final userName = user.displayName ?? '';

      final snapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .where('name', isEqualTo: widget.doctor.name)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doctorDoc = snapshot.docs.first;
        final scheduleSnapshot = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorDoc.id)
            .collection('schedules')
            .get();

        if (scheduleSnapshot.docs.isNotEmpty) {
          final scheduleDoc = scheduleSnapshot.docs.first;
          final scheduleDocRef = await FirebaseFirestore.instance
              .collection('doctors')
              .doc(doctorDoc.id)
              .collection('schedules')
              .doc(scheduleDoc.id)
              .get();

          await scheduleDocRef.reference.collection('bookedSlots').add({
            'timeSlot': timeSlot,
            'bookedAt': FieldValue.serverTimestamp(),
            'userId': userId, // Store the user ID
            'userName': userName, // Store the user name
            'date': widget.selectedDate, // Store the selected date
          });
        }
      }
    } catch (e) {
      print('Error booking appointment: $e');
    }
  }
}

class TimeSlotButton extends StatelessWidget {
  final String time;
  final _TimeSlotPageState state;

  TimeSlotButton(this.time, this.state);

  @override
  Widget build(BuildContext context) {
    final isSelected = state._selectedTimeSlot == time;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ElevatedButton(
        onPressed: () {
          state._selectTimeSlot(time);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : Colors.brown.shade100,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class AppointmentTime extends StatelessWidget {
  final String time;

  AppointmentTime(this.time);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.brown.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        time,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class AppointmentConfirmationPage extends StatelessWidget {
  final Timestamp dateTimestamp; // Change the type to Timestamp
  final String timeSlot;

  const AppointmentConfirmationPage({
    Key? key,
    required this.dateTimestamp, // Pass the Timestamp object
    required this.timeSlot,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final date = dateTimestamp.toDate(); // Convert Timestamp to DateTime

    return Scaffold(
      appBar: AppBar(
        title: Text('Appointment Confirmation'),
      ),
      body: Center(
        child: Container(
          width: 300,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Your Appointment is Confirmed:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              Text(
                'on ${date.day}/${date.month}/${date.year} at $timeSlot',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

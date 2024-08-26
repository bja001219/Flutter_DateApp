import 'package:finalassign/home.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:collection';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late LinkedHashMap<DateTime, List<Event>> _events;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _events = LinkedHashMap(
      equals: isSameDay,
      hashCode: getHashCode,
    );
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user != null) {
      DocumentSnapshot settingsSnapshot =
          await _firestore.collection('settings').doc(user.uid).get();
      bool showSchedule = settingsSnapshot.exists &&
          (settingsSnapshot.data() as Map<String, dynamic>)['showSchedule'] == true;

      QuerySnapshot snapshot;
      if (showSchedule) {
        snapshot = await _firestore
            .collection('schedule')
            .where('uid', isEqualTo: user.uid)
            .get();
      } else {
        snapshot = await _firestore.collection('schedule').get();
      }

      Map<DateTime, List<Event>> eventMap = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime startDate = (data['start_date'] as Timestamp).toDate();
        DateTime endDate = (data['end_date'] as Timestamp).toDate();
        String title = data['title'];
        String detail = data['detail'];
        String uid = data['uid'];
        String id = doc.id;

        DateTime date = startDate;
        while (date.isBefore(endDate.add(Duration(days: 1)))) {
          if (!eventMap.containsKey(date)) {
            eventMap[date] = [];
          }
          eventMap[date]!.add(Event(id, title, detail, uid));
          date = date.add(Duration(days: 1));
        }
      }

      setState(() {
        _events.addAll(eventMap);
      });
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (Route<dynamic> route) => false,
            );
          },
        ),
        title: const Text('Calendar'),
        backgroundColor: Colors.pink[100],
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SchedulePage()),
              );
              _fetchEvents();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2100, 3, 14),
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
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay,
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('schedule').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final docs = snapshot.data!.docs;
                  Map<DateTime, List<Event>> eventMap = {};

                  for (var doc in docs) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    DateTime startDate = (data['start_date'] as Timestamp).toDate();
                    DateTime endDate = (data['end_date'] as Timestamp).toDate();
                    String title = data['title'];
                    String detail = data['detail'];
                    String uid = data['uid'];
                    String id = doc.id;

                    DateTime date = startDate;
                    while (date.isBefore(endDate.add(Duration(days: 1)))) {
                      if (!eventMap.containsKey(date)) {
                        eventMap[date] = [];
                      }
                      eventMap[date]!.add(Event(id, title, detail, uid));
                      date = date.add(Duration(days: 1));
                    }
                  }

                  _events = LinkedHashMap(
                    equals: isSameDay,
                    hashCode: getHashCode,
                  )..addAll(eventMap);

                  final events = _getEventsForDay(_selectedDay ?? DateTime.now());
                  if (events.isEmpty) {
                    return Center(
                      child: Text(
                        'No events for this day.',
                        style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Card(
                        child: ListTile(
                          title: Text(event.title),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailPage(
                                  eventId: event.id,
                                  title: event.title,
                                  detail: event.detail,
                                  startDate: _selectedDay!,
                                  endDate: _selectedDay!,
                                  uid: event.uid,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Event {
  final String id;
  final String title;
  final String detail;
  final String uid;

  Event(this.id, this.title, this.detail, this.uid);
}

bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) {
    return false;
  }
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

int getHashCode(DateTime key) {
  return key.year * 10000 + key.month * 100 + key.day;
}

class SchedulePage extends StatefulWidget {
  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Schedule'),
        backgroundColor: Colors.pink[100],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _startDate = pickedDate;
                          if (_endDate != null && pickedDate.isAfter(_endDate!)) {
                            _endDate = pickedDate;
                          }
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: TextEditingController(
                          text: _startDate != null
                              ? '${_startDate!.year}/${_startDate!.month}/${_startDate!.day}'
                              : '',
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? _startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _endDate = pickedDate;
                          if (_startDate != null && pickedDate.isBefore(_startDate!)) {
                            _startDate = pickedDate;
                          }
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: TextEditingController(
                          text: _endDate != null
                              ? '${_endDate!.year}/${_endDate!.month}/${_endDate!.day}'
                              : '',
                        ),
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _detailController,
              decoration: const InputDecoration(
                labelText: 'Detail',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (_startDate != null && _endDate != null && _titleController.text.isNotEmpty) {
                    User? user = _auth.currentUser;
                    if (user != null) {
                      await _firestore.collection('schedule').add({
                        'start_date': _startDate,
                        'end_date': _endDate,
                        'title': _titleController.text,
                        'detail': _detailController.text,
                        'uid': user.uid,
                      });
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Add Schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class EventDetailPage extends StatelessWidget {
  final String eventId;
  final String title;
  final String detail;
  final DateTime startDate;
  final DateTime endDate;
  final String uid;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  EventDetailPage({
    required this.eventId,
    required this.title,
    required this.detail,
    required this.startDate,
    required this.endDate,
    required this.uid,
  });

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _deleteEvent(BuildContext context) async {
    try {
      await _firestore.collection('schedule').doc(eventId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CalendarPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete event: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: Colors.pink[100],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (currentUser != null && currentUser.uid == uid) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModifyPage(
                      eventId: eventId,
                      title: title,
                      detail: detail,
                      startDate: startDate,
                      endDate: endDate,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final bool? confirmDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Delete Event'),
                      content: const Text('Are you sure you want to delete this event?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );

                if (confirmDelete == true) {
                  await _deleteEvent(context);
                }
              },
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: $title', style: TextStyle(fontSize: 20.0)),
            const SizedBox(height: 16.0),
            Text('Detail: $detail', style: TextStyle(fontSize: 16.0)),
            const SizedBox(height: 16.0),
            Text('Start Date: ${startDate.toString().split(' ')[0]}', style: TextStyle(fontSize: 16.0)),
            const SizedBox(height: 16.0),
            Text('End Date: ${endDate.toString().split(' ')[0]}', style: TextStyle(fontSize: 16.0)),
          ],
        ),
      ),
    );
  }
}

class ModifyPage extends StatefulWidget {
  final String eventId;
  final String title;
  final String detail;
  final DateTime startDate;
  final DateTime endDate;

  ModifyPage({
    required this.eventId,
    required this.title,
    required this.detail,
    required this.startDate,
    required this.endDate,
  });

  @override
  _ModifyPageState createState() => _ModifyPageState();
}

class _ModifyPageState extends State<ModifyPage> {
  late TextEditingController _titleController;
  late TextEditingController _detailController;
  DateTime? _startDate;
  DateTime? _endDate;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _detailController = TextEditingController(text: widget.detail);
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modify Event'),
        backgroundColor: Colors.pink[100],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _startDate = pickedDate;
                          if (_endDate != null && pickedDate.isAfter(_endDate!)) {
                            _endDate = pickedDate;
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _startDate == null
                              ? 'Start Date'
                              : _startDate.toString().split(' ')[0],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? _startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _endDate = pickedDate.isBefore(_startDate ?? pickedDate)
                              ? _startDate
                              : pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _endDate == null
                              ? 'End Date'
                              : _endDate.toString().split(' ')[0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Title',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter title',
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Details',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _detailController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter details',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                if (_startDate != null && _endDate != null && _detailController.text.isNotEmpty && _titleController.text.isNotEmpty) {
                  try {
                    await _firestore.collection('schedule').doc(widget.eventId).update({
                      'start_date': Timestamp.fromDate(_startDate!),
                      'end_date': Timestamp.fromDate(_endDate!),
                      'title': _titleController.text,
                      'detail': _detailController.text,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Event updated successfully')),
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => CalendarPage()),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update event: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill out all fields')),
                  );
                }
              },
              child: const Text('Update Event'),
            ),
          ],
        ),
      ),
    );
  }
}
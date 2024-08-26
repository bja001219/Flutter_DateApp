import 'package:finalassign/home.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DayPage extends StatefulWidget {
  const DayPage({super.key});

  @override
  _DayPageState createState() => _DayPageState();
}

class _DayPageState extends State<DayPage> {
  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _setDate() async {
    try {
      await FirebaseFirestore.instance.collection('date').doc('WudF1NqRs8O3Y0pK4oXA').set({
        'setdate': Timestamp.fromDate(selectedDate),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Date set successfully')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set date: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[100],
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
        title: const Text('D-Day'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Set the day you\'ve met'),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('yyyy-MM-dd').format(selectedDate),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _setDate,
              style: ElevatedButton.styleFrom(
              ),
              child: const Text('Set'),
            ),
          ],
        ),
      ),
    );
  }
}
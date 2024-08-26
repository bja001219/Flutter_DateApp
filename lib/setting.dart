import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _showPeriod = false;
  bool _showPreg = false;
  bool _showSchedule = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String uid = user.uid;
      DocumentReference userDoc = _firestore.collection('settings').doc(uid);
      DocumentSnapshot doc = await userDoc.get();

      if (!doc.exists) {
        await userDoc.set({
          'showPeriod': false,
          'showPreg': false,
          'showSchedule': false,
        });
        setState(() {
          _showPeriod = false;
          _showPreg = false;
          _showSchedule = false;
        });
      } else {
        setState(() {
          _showPeriod = doc['showPeriod'] ?? false;
          _showPreg = doc['showPreg'] ?? false;
          _showSchedule = doc['showSchedule'] ?? false;
        });
      }
    }
  }

  Future<void> _updateSetting(String field, bool value) async {
    User? user = _auth.currentUser;
    if (user != null) {
      String uid = user.uid;
      await _firestore.collection('settings').doc(uid).update({field: value});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.pink[100],
      ),
      body: Container(
        color: Colors.pink[100],
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildListTile('Hide others schedule', _showSchedule, (value) {
              setState(() {
                _showSchedule = value;
              });
              _updateSetting('showSchedule', value);
            }),
            SizedBox(height: 10),
            _buildListTile('Hide my period', _showPeriod, (value) {
              setState(() {
                _showPeriod = value;
              });
              _updateSetting('showPeriod', value);
            }),
            SizedBox(height: 10),
            _buildListTile('Hide my preg', _showPreg, (value) {
              setState(() {
                _showPreg = value;
              });
              _updateSetting('showPreg', value);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(String title, bool value, Function(bool) onChanged) {
    return ListTile(
      title: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.black),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.pink[100],
            ),
          ],
        ),
      ),
    );
  }
}
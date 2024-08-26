import 'package:finalassign/account.dart';
import 'package:finalassign/auth_gate.dart';
import 'package:finalassign/calender.dart';
import 'package:finalassign/daypage.dart';
import 'package:finalassign/map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String dateDifference = '';
  String formattedToday = DateFormat('yyyy-MM-dd').format(DateTime.now());
  DateTime? setDate;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _fetchDateDifference();
    _fetchImageUrl();
  }

  Future<void> _fetchDateDifference() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('date')
          .doc('WudF1NqRs8O3Y0pK4oXA')
          .get();

      if (documentSnapshot.exists) {
        Timestamp timestamp = documentSnapshot['setdate'];
        setDate = timestamp.toDate();
        DateTime today = DateTime.now();

        Duration difference = today.difference(setDate!);
        setState(() {
          dateDifference = '${difference.inDays + 1} days';
        });
      } else {
        setState(() {
          dateDifference = 'No date found';
        });
      }
    } catch (e) {
      setState(() {
        dateDifference = 'Error fetching date';
      });
    }
  }

  Future<void> _fetchImageUrl() async {
    try {
      Reference ref = FirebaseStorage.instance.ref().child('main.png');
      String url = await ref.getDownloadURL();
      setState(() {
        imageUrl = url;
      });
    } catch (e) {
      print('Error fetching image URL: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await _uploadImage(File(image.path));
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      Reference ref = FirebaseStorage.instance.ref().child('main.png');
      await ref.putFile(imageFile);
      String url = await ref.getDownloadURL();
      setState(() {
        imageUrl = url;
      });
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[100],
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, semanticLabel: 'menu'),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text(
          'Main',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.access_time, semanticLabel: 'dday'),
            onPressed: () {
              if (setDate != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DayPage(),
                  ),
                );
              }
            },
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Color.fromARGB(255, 243, 182, 202)),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Menus',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 50,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            _createDrawerItem(
              icon: Icons.home,
              text: 'Home',
              onTap: () => _navigateTo(context, const HomeScreen()),
            ),
            _createDrawerItem(
              icon: Icons.calendar_month,
              text: 'Calender',
              onTap: () => _navigateTo(context, CalendarPage()),
            ),
            _createDrawerItem(
              icon: Icons.map,
              text: 'Map',
              onTap: () => _navigateTo(context, MapPage()),
            ),
            _createDrawerItem(
              icon: Icons.attach_money,
              text: 'Account',
              onTap: () => _navigateTo(context, AccountPage()),
            ),
            _createDrawerItem(
              icon: Icons.logout,
              text: 'Logout',
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: imageUrl != null 
                ? Image.network(imageUrl!) 
                : CircularProgressIndicator(),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$formattedToday',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                GestureDetector(
                  onTap: () {
                    if (setDate != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewPage(
                            dateDifference: dateDifference,
                            formattedToday: formattedToday,
                            setDate: setDate!,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    '❤$dateDifference',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.pink[100],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ListTile _createDrawerItem({required IconData icon, required String text, required GestureTapCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.pink),
      title: Text(text),
      onTap: onTap,
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
  
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthGate()),
    );
  }
}

class ViewPage extends StatefulWidget {
  final String dateDifference;
  final String formattedToday;
  final DateTime setDate;

  const ViewPage({
    super.key,
    required this.dateDifference,
    required this.formattedToday,
    required this.setDate,
  });

  @override
  _ViewPageState createState() => _ViewPageState();
}

class _ViewPageState extends State<ViewPage> {
  late List<bool> _alarmChecks;
  String? imageUrl;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  List<Map<String, String>> filteredEventsWithDates = [];

  @override
  void initState() {
    super.initState();
    _alarmChecks = List<bool>.filled(_generateEventsWithDates().length, true);
    _fetchImageUrl();
    _searchController.addListener(_onSearchChanged);
    filteredEventsWithDates = _generateEventsWithDates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text.toLowerCase();
      filteredEventsWithDates = _generateEventsWithDates().where((event) {
        return event['event']!.toLowerCase().contains(searchQuery) ||
               event['date']!.toLowerCase().contains(searchQuery);
      }).toList();
    });
  }

  Future<void> _fetchImageUrl() async {
    try {
      Reference ref = FirebaseStorage.instance.ref().child('main.png');
      String url = await ref.getDownloadURL();
      setState(() {
        imageUrl = url;
      });
    } catch (e) {
      print('Error fetching image URL: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await _uploadImage(File(image.path));
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      Reference ref = FirebaseStorage.instance.ref().child('main.png');
      await ref.putFile(imageFile);
      String url = await ref.getDownloadURL();
      setState(() {
        imageUrl = url;
      });
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  String _getDayOfWeek(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return DateFormat('E').format(dateTime);
  }

  List<Map<String, String>> _generateEventsWithDates() {
    List<Map<String, String>> eventsWithDates = [];

    for (int i = 1; i <= 100; i++) {
      DateTime eventDate = widget.setDate.add(Duration(days: i * 100));
      eventsWithDates.add({
        'event': '${i * 100} Days',
        'date': DateFormat('yyyy-MM-dd').format(eventDate),
      });
    }

    for (int i = 1; i <= 27; i++) {
      DateTime eventDate = widget.setDate.add(Duration(days: i * 365));
      eventsWithDates.add({
        'event': '$i Year${i > 1 ? 's' : ''}',
        'date': DateFormat('yyyy-MM-dd').format(eventDate),
      });
    }

    eventsWithDates = eventsWithDates.toSet().toList();

    eventsWithDates.sort((a, b) {
      DateTime aValue = DateTime.parse(a['date']!);
      DateTime bValue = DateTime.parse(b['date']!);
      return aValue.compareTo(bValue);
    });

    return eventsWithDates;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                '${widget.formattedToday}\n❤${widget.dateDifference}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.pink,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: GestureDetector(
                onTap: _pickImage,
                child: imageUrl != null
                  ? Image.network(imageUrl!, fit: BoxFit.cover)
                  : CircularProgressIndicator(),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: EventSearchDelegate(_generateEventsWithDates()),
                  );
                },
              ),
            ],
          ),  
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Column(  
                  children: [
                    ListTile(
                      title: Text(
                        filteredEventsWithDates[index]['event']!,
                        style: const TextStyle(fontSize: 24.0),
                      ),
                      subtitle: Text(
                        '${filteredEventsWithDates[index]['date']} (${_getDayOfWeek(filteredEventsWithDates[index]['date']!)})',
                        style: const TextStyle(fontSize: 16.0, color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Get Alarm',
                            style: TextStyle(fontSize: 16.0),
                          ),
                          Checkbox(
                            value: _alarmChecks[index],
                            onChanged: (bool? value) {
                              setState(() {
                                _alarmChecks[index] = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      thickness: 1.0,
                    ),
                  ],
                );
              },
              childCount: filteredEventsWithDates.length,
            ),
          ),
        ],
      ),
    );
  }
}

class EventSearchDelegate extends SearchDelegate<Map<String, String>> {
  final List<Map<String, String>> events;

  EventSearchDelegate(this.events);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, {});
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = events.where((event) {
      return event['event']!.toLowerCase().contains(query.toLowerCase()) ||
             event['date']!.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(results[index]['event']!),
          subtitle: Text(results[index]['date']!),
          onTap: () {
            close(context, results[index]);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = events.where((event) {
      return event['event']!.toLowerCase().contains(query.toLowerCase()) ||
             event['date']!.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index]['event']!),
          subtitle: Text(suggestions[index]['date']!),
          onTap: () {
            query = suggestions[index]['event']!;
            showResults(context);
          },
        );
      },
    );
  }
}
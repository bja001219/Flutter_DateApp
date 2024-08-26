import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:finalassign/home.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(37.5642135, 127.0016985);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchMarkersFromFirestore();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _fetchMarkersFromFirestore() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('map').get();
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final LatLng position = LatLng(data['latitude'], data['longitude']);
        final String title = data['title'];
        final String details = data['details'];
        final String docId = doc.id;
        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId(position.toString()),
              position: position,
              infoWindow: InfoWindow(
                title: title,
                snippet: details,
                onTap: () {
                  _showEditDeleteDialog(docId, position, title, details);
                },
              ),
            ),
          );
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void _searchPlace(String place) async {
    try {
      List<Location> locations = await locationFromAddress(place);
      if (locations.isNotEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return _PlacesDialog(
              locations: locations,
              onPlaceSelected: (LatLng target, String title, String details) {
                _pinPlace(target, title, details);
              },
            );
          },
        );
      }
    } catch (e) {
      print(e);
    }
  }

  void _pinPlace(LatLng target, String title, String details) async {
    DocumentReference docRef = await _firestore.collection('map').add({
      'latitude': target.latitude,
      'longitude': target.longitude,
      'title': title,
      'details': details,
    });

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(target.toString()),
          position: target,
          infoWindow: InfoWindow(
            title: title,
            snippet: details,
            onTap: () {
              _showEditDeleteDialog(docRef.id, target, title, details);
            },
          ),
        ),
      );
    });
  }

  void _showEditDeleteDialog(String docId, LatLng position, String title, String details) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(details),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  String? newTitle = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) {
                      return _TitleDialog();
                    },
                  );
                  String? newDetails = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) {
                      return _DetailsDialog();
                    },
                  );
                  if (newTitle != null && newDetails != null) {
                    _editPlace(docId, position, newTitle, newDetails);
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Edit'),
              ),
              ElevatedButton(
                onPressed: () {
                  _deletePlace(docId, position);
                  Navigator.of(context).pop();
                },
                child: const Text('Delete'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CLOSE'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _editPlace(String docId, LatLng position, String title, String details) {
    _firestore.collection('map').doc(docId).update({
      'title': title,
      'details': details,
    });

    setState(() {
      _markers.removeWhere((marker) => marker.markerId == MarkerId(position.toString()));
      _markers.add(
        Marker(
          markerId: MarkerId(position.toString()),
          position: position,
          infoWindow: InfoWindow(
            title: title,
            snippet: details,
            onTap: () {
              _showEditDeleteDialog(docId, position, title, details);
            },
          ),
        ),
      );
    });
  }

  void _deletePlace(String docId, LatLng position) {
    _firestore.collection('map').doc(docId).delete();

    setState(() {
      _markers.removeWhere((marker) => marker.markerId == MarkerId(position.toString()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
          title: const Text('Date Map'),
          centerTitle: true,
          backgroundColor: Colors.pink[100],
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () async {
                String? place = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return _SearchDialog();
                  },
                );
                if (place != null && place.isNotEmpty) {
                  _searchPlace(place);
                }
              },
            ),
          ],
        ),
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 11.0,
          ),
          markers: _markers,
        ),
      ),
    );
  }
}

class _SearchDialog extends StatefulWidget {
  @override
  __SearchDialogState createState() => __SearchDialogState();
}

class __SearchDialogState extends State<_SearchDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search Place'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: 'Enter a place name'),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('CANCEL'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('SEARCH'),
          onPressed: () {
            Navigator.of(context).pop(_controller.text);
          },
        ),
      ],
    );
  }
}

class _PlacesDialog extends StatelessWidget {
  final List<Location> locations;
  final Function(LatLng, String, String) onPlaceSelected;

  _PlacesDialog({required this.locations, required this.onPlaceSelected});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select a Place'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: locations.length,
          itemBuilder: (BuildContext context, int index) {
            final location = locations[index];
            final LatLng target = LatLng(location.latitude, location.longitude);
            return ListTile(
              title: Text('Place ${index + 1}'),
              subtitle: Text('${location.latitude}, ${location.longitude}'),
              onTap: () async {
                String? title = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return _TitleDialog();
                  },
                );
                String? details = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return _DetailsDialog();
                  },
                );
                if (title != null && details != null) {
                  onPlaceSelected(target, title, details);
                  Navigator.of(context).pop();
                }
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('CLOSE'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _TitleDialog extends StatefulWidget {
  @override
  __TitleDialogState createState() => __TitleDialogState();
}

class __TitleDialogState extends State<_TitleDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Title'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: 'Enter title'),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('CANCEL'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('SAVE'),
          onPressed: () {
            Navigator.of(context).pop(_controller.text);
          },
        ),
      ],
    );
  }
}

class _DetailsDialog extends StatefulWidget {
  @override
  __DetailsDialogState createState() => __DetailsDialogState();
}

class __DetailsDialogState extends State<_DetailsDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Details'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: 'Enter details'),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('CANCEL'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('SAVE'),
          onPressed: () {
            Navigator.of(context).pop(_controller.text);
          },
        ),
      ],
    );
  }
}

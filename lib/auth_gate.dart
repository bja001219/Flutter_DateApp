import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'home.dart';
import 'main.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchImageUrl();
  }

  Future<void> _fetchImageUrl() async {
    String url = await _getImageUrl();
    setState(() {
      _imageUrl = url;
    }); 
  }

  Future<String> _getImageUrl() async {
    try {
      final ref = FirebaseStorage.instance.ref().child('main.png');
      String url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print(e);
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Stack(
            children: [
              Positioned.fill(
                child: _imageUrl.isNotEmpty
                    ? Image.network(
                        _imageUrl,
                        fit: BoxFit.cover,
                      )
                    : Container(color: Colors.grey), // Placeholder while loading
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.symmetric(horizontal: 32.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: SignInScreen(
                    providers: [
                      EmailAuthProvider(),
                      GoogleProvider(clientId: clientId),
                    ],
                    headerBuilder: (context, constraints, shrinkOffset) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Couple App',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.pink,
                            ),
                          ),
                        ),
                      );
                    },
                    subtitleBuilder: (context, action) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: action == AuthAction.signIn
                            ? const Text('')
                            : const Text(''),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }

        return const HomeScreen();
      },
    );
  }
}
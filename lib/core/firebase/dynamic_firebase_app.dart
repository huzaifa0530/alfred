import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_credentials.dart';
import 'package:flutter/material.dart';

class DynamicFirebaseApp {
  FirebaseApp? _app;

  FirebaseApp get currentApp {
    final app = _app;

    if (app == null) {
      throw StateError(
        'Firebase not connected. Call connect() first.',
      );
    }

    return app;
  }

  bool get isConnected => _app != null;
Future<String> connect(FirebaseCredentials creds) async {
  debugPrint('DYNAMIC FIREBASE: Starting connection...');

  // Reuse existing [DEFAULT] Firebase app.
  if (Firebase.apps.isNotEmpty) {
    debugPrint('DYNAMIC FIREBASE: Existing Firebase app found.');

    final defaultApp = Firebase.apps.firstWhere(
      (app) => app.name == defaultFirebaseAppName,
    );

    _app = defaultApp;

    debugPrint(
      'DYNAMIC FIREBASE: Reusing existing Firebase app: ${_app!.name}',
    );
    debugPrint(
      'DYNAMIC FIREBASE: Firebase project = ${_app!.options.projectId}',
    );
  } else {
    debugPrint('DYNAMIC FIREBASE: Creating [DEFAULT] app...');

    _app = await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: creds.apiKey,
        appId: creds.appId,
        messagingSenderId: creds.messagingSenderId,
        projectId: creds.projectId,
        storageBucket: creds.storageBucket,
      ),
    );

    debugPrint(
      'DYNAMIC FIREBASE: Firebase initialized: ${_app!.name}',
    );
  }

  final auth = FirebaseAuth.instance;

  debugPrint('DYNAMIC FIREBASE: Checking authentication...');

  User? user = auth.currentUser;

  if (user == null) {
    debugPrint(
      'DYNAMIC FIREBASE: No authenticated user. '
      'Signing in anonymously...',
    );

    user = (await auth.signInAnonymously()).user;
  } else {
    debugPrint(
      'DYNAMIC FIREBASE: Existing authenticated user found.',
    );
  }

  if (user == null) {
    throw StateError(
      'Anonymous Firebase authentication failed.',
    );
  }

  debugPrint('DYNAMIC FIREBASE: Anonymous authentication SUCCESS');
  debugPrint('DYNAMIC FIREBASE: UID = ${user.uid}');

  return user.uid;
}
  Future<void> disconnect() async {
    final app = _app;

    if (app == null) {
      return;
    }

    debugPrint('DYNAMIC FIREBASE: Disconnecting...');

    await app.delete();

    _app = null;

    debugPrint('DYNAMIC FIREBASE: Disconnected.');
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_credentials.dart';
import 'package:flutter/material.dart';

class DynamicFirebaseApp {
  static const String _dynamicAppName = 'dynamic_backup';
  
  FirebaseApp? _app;

  FirebaseApp get currentApp {
    final app = _app;
    if (app == null) {
      throw StateError('Firebase not connected. Call connect() first.');
    }
    return app;
  }

  bool get isConnected => _app != null;

  Future<String> connect(FirebaseCredentials creds) async {
    debugPrint('DYNAMIC FIREBASE: Starting connection...');

    // 1. Delete old dynamic app if exists (prev project)
    try {
      final existing = Firebase.app(_dynamicAppName);
      debugPrint('DYNAMIC FIREBASE: Found old dynamic app, deleting...');
      await existing.delete();
    } catch (_) {
      // no existing dynamic app, fine
    }

    // 2. Create NEW named app with new creds - this CAN be deleted
    debugPrint('DYNAMIC FIREBASE: Creating $_dynamicAppName app for project ${creds.projectId}');
    _app = await Firebase.initializeApp(
      name: _dynamicAppName,
      options: FirebaseOptions(
        apiKey: creds.apiKey,
        appId: creds.appId,
        messagingSenderId: creds.messagingSenderId,
        projectId: creds.projectId,
        storageBucket: creds.storageBucket,
      ),
    );

    final auth = FirebaseAuth.instanceFor(app: _app!);
    User? user = auth.currentUser;
    
    if (user == null) {
      debugPrint('DYNAMIC FIREBASE: Signing in anonymously...');
      user = (await auth.signInAnonymously()).user;
    }

    if (user == null) throw StateError('Anonymous auth failed');

    debugPrint('DYNAMIC FIREBASE: SUCCESS UID=${user.uid} project=${creds.projectId}');
    return user.uid;
  }

  Future<void> disconnect() async {
    final app = _app;
    if (app == null) {
      debugPrint('DYNAMIC FIREBASE: Already disconnected');
      return;
    }

    debugPrint('DYNAMIC FIREBASE: Disconnecting ${app.name}...');

    try {
      await FirebaseAuth.instanceFor(app: app).signOut();
      await app.delete(); // NOW THIS WORKS - because it's named app, not [DEFAULT]
      debugPrint('DYNAMIC FIREBASE: Deleted ${app.name}');
    } catch (e, st) {
      debugPrint('DYNAMIC FIREBASE: Disconnect error $e');
      debugPrintStack(stackTrace: st);
    } finally {
      _app = null;
    }
  }
}
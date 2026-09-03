// core/firebase/dynamic_firebase_app.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_credentials.dart';

class DynamicFirebaseApp {
  static const _appName = 'user_cloud';
  FirebaseApp? _app;

  FirebaseApp get currentApp {
    final app = _app;
    if (app == null) {
      throw StateError('Firebase not connected. Call connect() first.');
    }
    return app;
  }

  bool get isConnected => _app != null;

  /// Connects to the user's own Firebase project and returns the
  /// anonymous uid used to namespace their data. Throws on bad
  /// credentials (e.g. wrong apiKey) — surface that to the UI as
  /// "couldn't connect, check your config".
  Future<String> connect(FirebaseCredentials creds) async {
    // Re-connecting (e.g. app restart) with a different app instance
    // of the same name isn't allowed — reuse if already initialized.
    final existing = Firebase.apps.where((a) => a.name == _appName);
    _app = existing.isNotEmpty
        ? existing.first
        : await Firebase.initializeApp(
            name: _appName,
            options: FirebaseOptions(
              apiKey: creds.apiKey,
              appId: creds.appId,
              messagingSenderId: creds.messagingSenderId,
              projectId: creds.projectId,
              storageBucket: creds.storageBucket,
            ),
          );

    final auth = FirebaseAuth.instanceFor(app: _app!);
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
    return user!.uid;
  }

  Future<void> disconnect() async {
    if (_app != null) {
      await _app!.delete();
      _app = null;
    }
  }
}
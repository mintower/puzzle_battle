import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase configuration. Only the web target is filled in — this app is
/// currently deployed as a web build only (GitHub Pages).
///
/// Replace the placeholder values below with the ones from your Firebase
/// project: Firebase console -> Project settings -> General -> "Your apps"
/// -> Web app -> SDK setup and configuration -> Config.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'DefaultFirebaseOptions has only been configured for web. Add your '
      'platform\'s config here before building for it.',
    );
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyCYRpE07KnFkdxre4pcCxREOhP7_qBxEFw',
    appId: '1:873317006795:web:4f7fa1d7ddeb2ee7e68a4e',
    messagingSenderId: '873317006795',
    projectId: 'sliding-puzzle-battle-b6565',
    authDomain: 'sliding-puzzle-battle-b6565.firebaseapp.com',
    storageBucket: 'sliding-puzzle-battle-b6565.firebasestorage.app',
  );
}

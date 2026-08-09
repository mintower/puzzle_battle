import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase configuration for each platform this app is built for.
///
/// Add a new `Firebase console -> Project settings -> Your apps` entry for
/// any additional platform (iOS, etc.) and a matching block below before
/// building for it — [currentPlatform] throws for anything not listed.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for '
          '$defaultTargetPlatform. Add your platform\'s config here before '
          'building for it.',
        );
    }
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyCYRpE07KnFkdxre4pcCxREOhP7_qBxEFw',
    appId: '1:873317006795:web:4f7fa1d7ddeb2ee7e68a4e',
    messagingSenderId: '873317006795',
    projectId: 'sliding-puzzle-battle-b6565',
    authDomain: 'sliding-puzzle-battle-b6565.firebaseapp.com',
    storageBucket: 'sliding-puzzle-battle-b6565.firebasestorage.app',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyDscG4dpnDEm1edqFgOORuCdMj4iCItGXM',
    appId: '1:873317006795:android:135897dd9d5e46e9e68a4e',
    messagingSenderId: '873317006795',
    projectId: 'sliding-puzzle-battle-b6565',
    storageBucket: 'sliding-puzzle-battle-b6565.firebasestorage.app',
  );
}

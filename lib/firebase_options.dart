// Run: dart pub global activate flutterfire_cli && flutterfire configure
// Then replace this file with generated firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD8PSAl0C8WiWJa4C2AlOECzz65DtoJIes',
    appId: '1:390212331440:web:5374e18c0a30c473e5d875',
    messagingSenderId: '390212331440',
    projectId: 'project-sams-f0086',
    authDomain: 'project-sams-f0086.firebaseapp.com',
    storageBucket: 'project-sams-f0086.firebasestorage.app',
    measurementId: 'G-TS32RYW8YP',
  );

  // TODO: Replace with values from Firebase Console / flutterfire configure

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA4ByemvaKTrWnRrHsqpRPcRbUJtbChkEQ',
    appId: '1:390212331440:android:7467cf296c156a24e5d875',
    messagingSenderId: '390212331440',
    projectId: 'project-sams-f0086',
    storageBucket: 'project-sams-f0086.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAFHKxOU9ol4gWq7N1rsLfhPBIxltcJIfg',
    appId: '1:390212331440:ios:46851bf237df732fe5d875',
    messagingSenderId: '390212331440',
    projectId: 'project-sams-f0086',
    storageBucket: 'project-sams-f0086.firebasestorage.app',
    iosBundleId: 'com.smartattendance.smartAttendance',
  );

}
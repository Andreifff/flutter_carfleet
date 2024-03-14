// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyApV6ee9-isWLBPM10x85kXNxBSnYat5F0',
    appId: '1:610319907335:web:06fb104d0afdd0225788a2',
    messagingSenderId: '610319907335',
    projectId: 'carfleetmanager-1e548',
    authDomain: 'carfleetmanager-1e548.firebaseapp.com',
    storageBucket: 'carfleetmanager-1e548.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBym-eEwvqlWgtreQ534uY74TfmZmOF3G0',
    appId: '1:610319907335:android:ea0a0f3c2f2a086f5788a2',
    messagingSenderId: '610319907335',
    projectId: 'carfleetmanager-1e548',
    storageBucket: 'carfleetmanager-1e548.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDnGahN21IHwiLk0o1rZfiyQ3KFJwXAG98',
    appId: '1:610319907335:ios:52add8fdab166a005788a2',
    messagingSenderId: '610319907335',
    projectId: 'carfleetmanager-1e548',
    storageBucket: 'carfleetmanager-1e548.appspot.com',
    iosBundleId: 'com.example.flutterApplication2',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDnGahN21IHwiLk0o1rZfiyQ3KFJwXAG98',
    appId: '1:610319907335:ios:615f7e4217a45d325788a2',
    messagingSenderId: '610319907335',
    projectId: 'carfleetmanager-1e548',
    storageBucket: 'carfleetmanager-1e548.appspot.com',
    iosBundleId: 'com.example.flutterApplication2.RunnerTests',
  );
}
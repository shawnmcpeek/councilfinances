// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        return windows;
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
    apiKey: 'AIzaSyA6MRSbRIyq6t5CiZo6O4Wij7ejT6yc0-0',
    appId: '1:606365253863:web:525cfc96f84daa9bc0a242',
    messagingSenderId: '606365253863',
    projectId: 'council-finance',
    authDomain: 'council-finance.firebaseapp.com',
    storageBucket: 'council-finance.firebasestorage.app',
    measurementId: 'G-32W88CJKZW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC9ot3Rx_VzrUlvXbiiPYYExTNIX_bpu9o',
    appId: '1:606365253863:android:91637a0d87298836c0a242',
    messagingSenderId: '606365253863',
    projectId: 'council-finance',
    storageBucket: 'council-finance.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCYgYNfwdYSWPfR2Ins1tJviSh0YIe38bA',
    appId: '1:606365253863:ios:97caf1eba44231b6c0a242',
    messagingSenderId: '606365253863',
    projectId: 'council-finance',
    storageBucket: 'council-finance.firebasestorage.app',
    iosClientId: '606365253863-6u1o8fv0o41d12jqh9r3f639g1kl3amu.apps.googleusercontent.com',
    iosBundleId: 'com.example.kcmanagement',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCYgYNfwdYSWPfR2Ins1tJviSh0YIe38bA',
    appId: '1:606365253863:ios:97caf1eba44231b6c0a242',
    messagingSenderId: '606365253863',
    projectId: 'council-finance',
    storageBucket: 'council-finance.firebasestorage.app',
    iosClientId: '606365253863-6u1o8fv0o41d12jqh9r3f639g1kl3amu.apps.googleusercontent.com',
    iosBundleId: 'com.example.kcmanagement',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAnVgwRE5KlpLXhTrP57bDbN1RM61j-PTQ',
    appId: '1:606365253863:web:79209ed7d54408ecc0a242',
    messagingSenderId: '606365253863',
    projectId: 'council-finance',
    authDomain: 'council-finance.firebaseapp.com',
    storageBucket: 'council-finance.firebasestorage.app',
    measurementId: 'G-SW925HCEQZ',
    databaseURL: 'https://council-finance.firebaseio.com',
  );
}

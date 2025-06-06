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
    apiKey: 'AIzaSyA28e_Sr3ga53aetNqnyNHijycBIWACzAQ',
    appId: '1:700638742983:web:6d000f2e7f988bd08371e2',
    messagingSenderId: '700638742983',
    projectId: 'greon-app-928d5',
    authDomain: 'greon-app-928d5.firebaseapp.com',
    storageBucket: 'greon-app-928d5.firebasestorage.app',
    measurementId: 'G-7W4EQP8T7B',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCHbLVaOQ7ZsFF3in0aBF0JmV8BAO5IG2o',
    appId: '1:700638742983:android:58a5a018f70441c78371e2',
    messagingSenderId: '700638742983',
    projectId: 'greon-app-928d5',
    storageBucket: 'greon-app-928d5.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDmTZVDlo1gHAGkayHRkska6-V4AdUhBMg',
    appId: '1:700638742983:ios:4495fbffdb20dc4d8371e2',
    messagingSenderId: '700638742983',
    projectId: 'greon-app-928d5',
    storageBucket: 'greon-app-928d5.firebasestorage.app',
    iosBundleId: 'com.greon.devapps',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDmTZVDlo1gHAGkayHRkska6-V4AdUhBMg',
    appId: '1:700638742983:ios:4495fbffdb20dc4d8371e2',
    messagingSenderId: '700638742983',
    projectId: 'greon-app-928d5',
    storageBucket: 'greon-app-928d5.firebasestorage.app',
    iosBundleId: 'com.greon.devapps',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA28e_Sr3ga53aetNqnyNHijycBIWACzAQ',
    appId: '1:700638742983:web:d27d1f468f1e94f88371e2',
    messagingSenderId: '700638742983',
    projectId: 'greon-app-928d5',
    authDomain: 'greon-app-928d5.firebaseapp.com',
    storageBucket: 'greon-app-928d5.firebasestorage.app',
    measurementId: 'G-YVPXLT6FBS',
  );

}
// File ini di-generate otomatis oleh FlutterFire CLI.
// Jangan edit file ini secara manual.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
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
    apiKey: 'AIzaSyCEAwDlJ56tRiK_S6yNhR5LBNImXH0JrAA',
    appId: '1:307773262208:web:3653b0bf88ad33b76a9965',
    messagingSenderId: '307773262208',
    projectId: 'edutech-smk-app-99a83',
    authDomain: 'edutech-smk-app-99a83.firebaseapp.com',
    storageBucket: 'edutech-smk-app-99a83.firebasestorage.app',
    measurementId: 'G-J95JCL7SJD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyApVR94kAyNKxqlZqV6s0L88HvYoIPdn_I',
    appId: '1:307773262208:android:e4cf0d40281ddde26a9965',
    messagingSenderId: '307773262208',
    projectId: 'edutech-smk-app-99a83',
    storageBucket: 'edutech-smk-app-99a83.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCPoeH9zAirK14EddCQHgH9GMqXFWIWmUo',
    appId: '1:307773262208:ios:461e13cdd56c38836a9965',
    messagingSenderId: '307773262208',
    projectId: 'edutech-smk-app-99a83',
    storageBucket: 'edutech-smk-app-99a83.firebasestorage.app',
    iosBundleId: 'com.edutechsmk.app',
  );
}

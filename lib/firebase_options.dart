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
    apiKey: 'AIzaSyBUTC5TclPRuwYxSotHzx-9f2ato8mAeY8',
    appId: '1:543776401221:web:9ba21e9ad5dd39c67b402c',
    messagingSenderId: '543776401221',
    projectId: 'edutech-smk-43b56',
    authDomain: 'edutech-smk-43b56.firebaseapp.com',
    storageBucket: 'edutech-smk-43b56.firebasestorage.app',
    measurementId: 'G-EE1K1ZWX5F',
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

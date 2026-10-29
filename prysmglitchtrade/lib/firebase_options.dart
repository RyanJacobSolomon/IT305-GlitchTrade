// File generated from the Firebase project configuration.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
        return linux;
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for Fuchsia.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDw584AvgNLB0TjTXnVBkWPhznj-h8ZmdI',
    appId: '1:624441763120:android:a4595547b9ef4dfea494f5',
    messagingSenderId: '624441763120',
    projectId: 'prysm-glitch-trade',
    storageBucket: 'prysm-glitch-trade.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDw584AvgNLB0TjTXnVBkWPhznj-h8ZmdI',
    appId: '1:624441763120:android:a4595547b9ef4dfea494f5',
    messagingSenderId: '624441763120',
    projectId: 'prysm-glitch-trade',
    storageBucket: 'prysm-glitch-trade.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDw584AvgNLB0TjTXnVBkWPhznj-h8ZmdI',
    appId: '1:624441763120:android:a4595547b9ef4dfea494f5',
    messagingSenderId: '624441763120',
    projectId: 'prysm-glitch-trade',
    storageBucket: 'prysm-glitch-trade.firebasestorage.app',
  );

  static const FirebaseOptions macos = ios;
  static const FirebaseOptions windows = android;
  static const FirebaseOptions linux = android;
}

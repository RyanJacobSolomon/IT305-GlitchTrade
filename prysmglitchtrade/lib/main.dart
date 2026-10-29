import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'main_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseAvailable = true;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (exception) {
    debugPrint('Firebase initialization failed: $exception');
    firebaseAvailable = false;
  }

  runApp(MyApp(firebaseAvailable: firebaseAvailable));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.firebaseAvailable});

  final bool firebaseAvailable;

  @override
  Widget build(BuildContext context) {
    const midnight = Color(0xFF070B18);
    const cyan = Color(0xFF00D9FF);
    const magenta = Color(0xFFD800FF);
    const silver = Color(0xFFE7EDF5);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: midnight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: cyan,
          brightness: Brightness.dark,
          primary: cyan,
          secondary: magenta,
          surface: const Color(0xFF111A2E),
        ),
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(
          backgroundColor: midnight,
          foregroundColor: silver,
          elevation: 0,
        ),
      ),
      home: MainPage(firebaseAvailable: firebaseAvailable),
    );
  }
}

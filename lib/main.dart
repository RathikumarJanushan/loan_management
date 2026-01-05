import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:loan_managementapp/user/Debtor.dart';
import 'auth_wrapper.dart'; // <-- Import the new wrapper
import 'firebase_options.dart';
import 'user/home.dart';
import 'user/registration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Loan Management',
      theme: ThemeData.dark(),
      // The 'home' property tells the app which widget to load first.
      // We use our AuthWrapper to decide where to go next.
      home: const AuthWrapper(),
      // We keep the named routes for easy navigation elsewhere in the app.
      routes: {
        '/home': (_) => const HomePage(),
        '/register': (_) => const RegistrationPage(),
        '/debtor': (context) => const DebtorPage(),
      },
    );
  }
}

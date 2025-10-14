import 'package:flutter/material.dart';
import 'welcomePage.dart';
import 'introPage.dart';
import 'connexion_page.dart';
import 'creer_un_compte_page.dart';

void main() {
  runApp(const AttendoApp());
}

class AttendoApp extends StatelessWidget {
  const AttendoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const IntroPage(),
        '/bienvenue': (context) => const welcomePage(),
      },
    );
  }
}

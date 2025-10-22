import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'introPage.dart';
import 'welcomepage.dart';
import 'connexion_page.dart';
import 'creer_un_compte_page.dart';
import 'dashboard_etudiant.dart';
import 'dashboard_enseignant.dart';
import 'gestionetudiants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AttendoApp());
}

class AttendoApp extends StatelessWidget {
  const AttendoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendo',
      initialRoute: '/', // Page de démarrage
      routes: {
        '/': (context) => const IntroPage(),
        '/welcome': (context) => const WelcomePage(),
        '/connexion': (context) => const ConnexionPage(),
        '/creer_compte': (context) => const CreerComptePage(),
        '/dashboard_etudiant': (context) => const DashboardEtudiant(),
        '/dashboard_enseignant': (context) => const DashboardEnseignant(),
        '/gestion_etudiants': (context) => const GestionEtudiants(),
      },
    );
  }
}

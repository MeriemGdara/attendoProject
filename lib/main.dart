import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'welcomepage.dart';
import 'connexion_page.dart';
import 'creer_un_compte_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


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
      },
    );
  }
}

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/intro.mp4')
      ..initialize().then((_) {
        _controller.play();
        _controller.setLooping(false);
        setState(() {});

        // Après 6 secondes, aller à la page suivante
        Future.delayed(const Duration(seconds: 6), () {
          Navigator.pushReplacementNamed(context, '/welcome');
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _controller.value.isInitialized
                ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
                : const CircularProgressIndicator(color: Colors.white),
          ),
          // Bouton "Passer"
          Positioned(
            bottom: 30,
            right: 20,
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/welcome');
              },
              child: const Text(
                "Passer",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

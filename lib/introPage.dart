import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'welcomePage.dart';  // Import de la page de bienvenue pour la navigation

void main() {
  runApp(const AttendoApp());
}

class AttendoApp extends StatelessWidget {
  const AttendoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendo',
      home: IntroPage(),  // Page de démarrage
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
        _controller.play();  // Joue la vidéo une seule fois
        _controller.setLooping(false);  // Empêche la boucle
        _controller.addListener(_videoListener);  // Ajoute un listener pour détecter la fin
        setState(() {});  // Met à jour l'UI
      });
  }

  void _videoListener() {
    if (_controller.value.isInitialized &&  // Vérifie si la vidéo est initialisée
        !_controller.value.isPlaying &&  // Vérifie si la vidéo n'est plus en train de jouer
        _controller.value.position >= _controller.value.duration) {  // Vérifie si la vidéo est terminée
      // Redirige vers WelcomePage une fois la vidéo terminée
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);  // Supprime le listener
    _controller.dispose();  // Libère les ressources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
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
    );
  }
}
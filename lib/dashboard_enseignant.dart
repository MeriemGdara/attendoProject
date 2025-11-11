import 'dart:async';
import 'package:attendo/GestionSeancesPage.dart';
import 'package:attendo/StatistiquesPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'GestionCoursPage.dart';
import 'ModifierProfileEnseignant.dart';
import 'connexion_page.dart';
import 'gestionetudiants.dart';

class DashboardEnseignant extends StatefulWidget {
  final String enseignantId;
  const DashboardEnseignant({super.key, required this.enseignantId});

  @override
  State<DashboardEnseignant> createState() => _DashboardEnseignantState();
}

class _DashboardEnseignantState extends State<DashboardEnseignant> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startSeanceWatcher();
  }

  /// Vérifie et demande la permission de localisation
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("❌ Le service de localisation n'est pas activé");
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("❌ Permission de localisation refusée");
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("❌ Permission de localisation refusée définitivement");
      return false;
    }

    return true;
  }

  /// Timer qui récupère automatiquement la position si une séance approche
  void _startSeanceWatcher() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final now = DateTime.now();
        final enseignantId = widget.enseignantId;

        // Récupérer toutes les séances de cet enseignant
        final snap = await FirebaseFirestore.instance
            .collection('séances')
            .where('enseignantId', isEqualTo: enseignantId)
            .get();

        for (final seance in snap.docs) {
          final horaireData = seance['horaire'];

          DateTime horaire;
          if (horaireData is Timestamp) {
            horaire = horaireData.toDate();
          } else if (horaireData is String) {
            horaire = DateTime.parse(horaireData);
          } else {
            continue;
          }

          // Vérifie si la séance est proche (+/- 5 minutes)
          if ((now.isAfter(horaire.subtract(const Duration(minutes: 5))) &&
              now.isBefore(horaire.add(const Duration(minutes: 5))))) {
            try {
              if (await _checkLocationPermission()) {
                Position position = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                );

                // Enregistrement dans Firestore
                await FirebaseFirestore.instance
                    .collection('positions_enseignants')
                    .doc(enseignantId)
                    .set({
                  'seanceId': seance.id,
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                  'timestamp': Timestamp.now(),
                });

                print("✅ Position enregistrée pour la séance ${seance.id}");
              }
            } catch (e) {
              print("❌ Erreur récupération position : $e");
            }
          }
        }
      } catch (e) {
        print("❌ Erreur lors de la récupération des séances : $e");
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.only(top: 30, bottom: 1),
            child: Center(
              child: Image.asset(
                'assets/images/ATTEND.png',
                width: 250,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF78c8c0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 1),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'Dashboard Enseignant',
                          style: GoogleFonts.fredoka(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 2
                              ..color = const Color(0xFF1A2B4A),
                          ),
                        ),
                        Text(
                          'Dashboard Enseignant',
                          style: GoogleFonts.fredoka(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 30,
                        crossAxisSpacing: 40,
                        childAspectRatio: 1.0,
                        children: [
                          DashboardCard(
                            imagePath: 'assets/images/profil.jpg',
                            label: 'Profil',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ModifierProfileEnseignant()),
                              );
                            },
                          ),
                          DashboardCard(
                            imagePath: 'assets/images/cour.jpg',
                            label: 'Gestion cours',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => GestionCoursPage()),
                              );
                            },
                          ),
                          DashboardCard(
                            imagePath: 'assets/images/gestion_etudiants.png',
                            label: 'Gestion étudiants',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const GestionEtudiants()),
                              );
                            },
                          ),
                          DashboardCard(
                            imagePath: 'assets/images/classe.jpg',
                            label: 'Statistiques',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const StatistiquesPage()),
                              );
                            },
                          ),
                          DashboardCard(
                            imagePath: 'assets/images/online_L1.jpg',
                            label: 'Ajouter séance',
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GestionSeancesPage(
                                    enseignantId: FirebaseAuth.instance.currentUser!.uid,
                                  ),
                                ),
                              );
                            },
                          ),
                          DashboardCard(
                            imagePath: 'assets/images/logout.png',
                            label: 'Se déconnecter',
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const ConnexionPage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// DashboardCard reste inchangé
class DashboardCard extends StatefulWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) => setState(() => _scale = 0.95);
  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onTap();
  }

  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                widget.imagePath,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2B4A),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

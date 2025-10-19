import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ModifierProfileEnseignant.dart';
import 'WelcomePage.dart';

class DashboardEnseignant extends StatelessWidget {
  const DashboardEnseignant({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Logo
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

          // Conteneur turquoise
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

                  // Titre Dashboard
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

                  // Grille des cartes
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
                            label: 'Ajouter cours',
                            onTap: () {},
                          ),
                          DashboardCard(
                            imagePath: 'assets/images/gestion_etudiant.jpg',
                            label: 'Gérer étudiants',
                            onTap: () {},
                          ),
                          DashboardCard(
                            imagePath: 'assets/images/classe.jpg',
                            label: 'Gérer classes',
                            onTap: () {},
                          ),
                          DashboardCard(
                            imagePath: 'assets/images/online_L1.jpg',
                            label: 'Lancer cours',
                            onTap: () {},
                          ),
                          DashboardCard(
                            imagePath: 'assets/images/logout.png',
                            label: 'Se déconnecter',
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const WelcomePage()),
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

// Carte Dashboard avec animation au clic et image
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

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.95);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

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
                width: 120, // taille plus grande
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

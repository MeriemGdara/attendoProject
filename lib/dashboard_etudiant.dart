import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profil_page.dart';
import 'WelcomePage.dart';

class DashboardEtudiant extends StatelessWidget {
  const DashboardEtudiant({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // fond global blanc
      body: Column(
        children: [
          // Logo sur fond blanc
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

          // Conteneur turquoise avec coins arrondis en haut
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

                  // Titre Dashboard Étudiant
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'Dashboard Étudiant',
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
                          'Dashboard Étudiant',
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
                        childAspectRatio: 1.0, // carré
                        children: [
                          DashboardCard(
                            icon: Icons.person,
                            label: 'profil',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ProfilPage()),
                              );
                            },
                          ),
                          DashboardCard(icon: Icons.menu_book, label: 'cours', onTap: () {}),
                          DashboardCard(icon: Icons.notifications, label: 'notification', onTap: () {}),
                          DashboardCard(icon: Icons.history, label: 'historique', onTap: () {}),
                          DashboardCard(icon: Icons.logout, label: 'Se déconnecter', onTap: () {Navigator.pushReplacement( // remplace l'écran actuel par WelcomePage
                            context,
                            MaterialPageRoute(builder: (context) => const WelcomePage()),
                          );}),
                          DashboardCard(icon: Icons.grade, label: 'notes', onTap: () {}),
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

// Carte Dashboard avec animation au clic
class DashboardCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.95); // réduit la carte
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0); // revient à normal
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
              Icon(widget.icon, size: 50, color: const Color(0xFF1A2B4A)),
              const SizedBox(height: 10),
              Text(
                widget.label,
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2B4A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AjoutCours.dart';
import 'AfficherCoursPage.dart';
import 'RechercheCoursPage.dart';
import 'dashboard_enseignant.dart'; // <-- Assure-toi d'avoir cette page

class GestionCoursPage extends StatelessWidget {
  const GestionCoursPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String enseignantId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF78c8c0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () {
            // Navigation vers le dashboard enseignant avec l'ID
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardEnseignant(enseignantId: enseignantId),
              ),
            );
          },
        ),
        title: Text(
          "Gestion des cours",
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 26,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // --- Image d'arrière-plan ---
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgroudCours.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // --- Contenu principal ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // --- Cartes de navigation ---
                  _buildMenuCard(
                    context,
                    title: "Ajouter un cours",
                    subtitle: "Créer un nouveau cours et le publier",
                    icon: Icons.add_circle_outline,
                    color: const Color(0xFF78c8c0),
                    page: const AjoutCours(),
                  ),
                  const SizedBox(height: 20),

                  _buildMenuCard(
                    context,
                    title: "Afficher les cours",
                    subtitle: "Voir tous les cours enregistrés",
                    icon: Icons.list_alt,
                    color: const Color(0xFF5A9E9B),
                    page: const AfficherCoursPage(),
                  ),
                  const SizedBox(height: 20),

                  _buildMenuCard(
                    context,
                    title: "Rechercher un cours",
                    subtitle: "Filtrer les cours par nom",
                    icon: Icons.search_rounded,
                    color: const Color(0xFF40837E),
                    page: const RechercheCoursPage(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required Widget page}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

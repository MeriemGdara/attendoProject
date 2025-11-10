import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'CreerSeancePage.dart';
import 'AfficherSeancesPage.dart';
import 'RechercheSeancesPage.dart';
import 'dashboard_enseignant.dart';

class GestionSeancesPage extends StatelessWidget {
  final String enseignantId; // L’ID de l’enseignant connecté
  const GestionSeancesPage({required this.enseignantId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF58B6B3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DashboardEnseignant(enseignantId: enseignantId),
              ),
            );
          },
        ),
        title: Text(
          "Gestion des séances",
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
              'assets/images/backgroundSeance1.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // --- Cartes de navigation ---
                  _buildMenuCard(
                    context,
                    title: "Créer une séance",
                    subtitle: "Ajouter une nouvelle séance pour vos cours",
                    icon: Icons.add_circle_outline,
                    color: const Color(0xFF58B6B3),
                    page: CreerSeancePage(enseignantId: enseignantId),
                  ),
                  const SizedBox(height: 20),

                  _buildMenuCard(
                    context,
                    title: "Afficher les séances",
                    subtitle: "Voir toutes vos séances enregistrées",
                    icon: Icons.list_alt,
                    color: const Color(0xFF4C9A97),
                    page: AfficherSeancesPage(),
                  ),
                  const SizedBox(height: 20),

                  _buildMenuCard(
                    context,
                    title: "Rechercher une séance",
                    subtitle: "Filtrer vos séances par nom ou cours",
                    icon: Icons.search_rounded,
                    color: const Color(0xFF3B7C78),
                    page: RechercheSeancesPage(enseignantId: enseignantId),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget pour une carte de menu améliorée ---
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
                        color: const Color(0xFF2C3E50)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.fredoka(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400),
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

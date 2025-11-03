import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ParticipationEtudiantsPage.dart';
import 'ProgressionClassesPage.dart';

class StatistiquesPage extends StatefulWidget {
  const StatistiquesPage({super.key});

  @override
  State<StatistiquesPage> createState() => _StatistiquesPageState();
}

class _StatistiquesPageState extends State<StatistiquesPage> {
  int nbEtudiants = 0;
  int nbEnseignants = 0;
  int nbCours = 0;
  int nbClasses = 0;
  bool chargement = true;

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  Future<void> chargerDonnees() async {
    try {
      final etudiantsSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'etudiant')
          .get();
      nbEtudiants = etudiantsSnap.size;

      final enseignantsSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'enseignant')
          .get();
      nbEnseignants = enseignantsSnap.size;

      final coursSnap = await FirebaseFirestore.instance.collection('cours').get();
      nbCours = coursSnap.size;

      final classesSnap = await FirebaseFirestore.instance.collection('classes').get();
      nbClasses = classesSnap.size;

      setState(() {
        chargement = false;
      });
    } catch (e) {
      print("❌ Erreur Firestore : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text(
          "Statistiques",
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1c2942),
          ),
        ),
        backgroundColor: const Color(0xFF5fc2ba),
        centerTitle: true,
      ),
      body: SafeArea(
        child: chargement
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF5fc2ba)))
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Vue d\'ensemble de votre établissement',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7a8fa3),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Cartes statistiques
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _EnhancedStatCard(
                    number: nbEtudiants.toString(),
                    label: 'Étudiants',
                    icon: Icons.people_alt_rounded,
                    backgroundColor: const Color(0xFF67b3ee),
                    iconColor: Colors.white,
                  ),
                  _EnhancedStatCard(
                    number: nbEnseignants.toString(),
                    label: 'Enseignants',
                    icon: Icons.person_4_rounded,
                    backgroundColor: const Color(0xFFf9c178),
                    iconColor: Colors.white,
                  ),
                  _EnhancedStatCard(
                    number: nbCours.toString(),
                    label: 'Cours',
                    icon: Icons.book_rounded,
                    backgroundColor: const Color(0xFF5fc2ba),
                    iconColor: Colors.white,
                  ),
                  _EnhancedStatCard(
                    number: nbClasses.toString(),
                    label: 'Classes',
                    icon: Icons.class_rounded,
                    backgroundColor: const Color(0xFFf58ea8),
                    iconColor: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Actions rapides / détails
              Text(
                'Actions rapides',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1c2942),
                ),
              ),
              const SizedBox(height: 16),

              _EnhancedMenuItem(
                title: 'Analyser participation étudiants',
                icon: Icons.analytics_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ParticipationEtudiantsPage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _EnhancedMenuItem(
                title: 'Suivre progression des classes',
                icon: Icons.trending_up_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProgressionClassesPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Carte statistique
class _EnhancedStatCard extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const _EnhancedStatCard({
    required this.number,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: GoogleFonts.fredoka(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Menu item pour actions rapides
class _EnhancedMenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _EnhancedMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFe8f0f5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFe8f0f5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF5fc2ba),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1c2942),
                  ),
                ),
              ],
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: const Color(0xFF5fc2ba),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

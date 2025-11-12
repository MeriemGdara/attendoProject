import 'package:attendo/DiscussionsPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ClassesGroupesPage.dart';
import 'rechercher_filtrer_page.dart';
import 'reaffecter_etudiants_page.dart';
import 'Statistiques des étudiants.dart';
import 'dashboard_enseignant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'DiscussionsPage.dart';

class GestionEtudiants extends StatefulWidget {
  const GestionEtudiants({super.key});

  @override
  State<GestionEtudiants> createState() => _GestionEtudiantsState();
}

class _GestionEtudiantsState extends State<GestionEtudiants> {
  int nbEtudiants = 0;
  int nbClasses = 0;
  int nbGroupes = 0;
  bool chargement = true;

  int nbMessagesNonLus=0;

  void chargerMessagesNonLus() {
    final enseignantId = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance
        .collection('messages')
        .where('enseignantId', isEqualTo: enseignantId)
        .snapshots()
        .listen((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['isRead'] == false && data['senderId'] != enseignantId) {
          count++;
        }
      }
      setState(() {
        nbMessagesNonLus = count;
      });
    });
  }


  // ✅ Fonction pour charger les données depuis Firestore
  Future<void> chargerDonnees() async {
    try {
      // 🔹 Nombre d'étudiants
      final etudiantsSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'etudiant')
          .get();
      nbEtudiants = etudiantsSnap.size;

      // 🔹 Classes
      final classesSnap =
      await FirebaseFirestore.instance.collection('classes').get();
      nbClasses = classesSnap.size;

      // 🔹 Groupes
      int totalGroupes = 0;
      for (var doc in classesSnap.docs) {
        List groupes = doc['groupes'];
        totalGroupes += groupes.length;
      }
      nbGroupes = totalGroupes;

      setState(() {
        chargement = false;
      });
    } catch (e) {
      print("❌ Erreur Firestore : $e");
    }
  }

  @override
  void initState() {
    super.initState();
    chargerDonnees();
    chargerMessagesNonLus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: chargement
            ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF5fc2ba)))
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 15),
            child: Column(
              children: [
                // ✅ En-tête avec flèche retour + texte
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xFF1c2942), size: 22),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DashboardEnseignant(
                              enseignantId: FirebaseAuth.instance.currentUser!.uid, // ✅ passe l’ID de l’enseignant connecté
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 50),
                    Text(
                      'Gestion étudiants',
                      style: GoogleFonts.fredoka(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1c2942),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                // ✅ Logo rond
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF5fc2ba),
                      width: 10,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/gestion_etudiants.png',
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ 3 cartes statistiques alignées
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatCard(
                      number: nbEtudiants.toString(),
                      label: 'Étudiants',
                      backgroundColor: const Color(0xFF67b3ee),
                    ),
                    _StatCard(
                      number: nbClasses.toString(),
                      label: 'Classes',
                      backgroundColor: const Color(0xFFf9c178),
                    ),
                    _StatCard(
                      number: nbGroupes.toString(),
                      label: 'Groupes',
                      backgroundColor: const Color(0xFF5fc2ba),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // ✅ Menus
                _MenuItem(
                  title: 'Consulter classes/groupes',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                          const ClassesGroupesPage()),
                    );
                  },
                ),

                const SizedBox(height: 16),
                _MenuItem(
                  title: 'Rechercher et filtrer',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                          const RechercherFiltrerPage()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _MenuItem(
                  title: 'Réaffecter étudiants',
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                            const ReaffecterEtudiantsPage()));
                  },
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DiscussionsPage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFd3edea),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Discussions',
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1c2942),
                          ),
                        ),
                        Row(
                          children: [
                            if (nbMessagesNonLus > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$nbMessagesNonLus',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF1c2942),
                              size: 28,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
        _MenuItem(
          title: 'Suivre les statistiques',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                  const SuivreStatistiquesPage()),
            );
          },
        )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ------------------------------------------------------
// 🔹 Widget StatCard (même style, taille identique)
// ------------------------------------------------------
class _StatCard extends StatelessWidget {
  final String number;
  final String label;
  final Color backgroundColor;

  const _StatCard({
    required this.number,
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100, // ✅ Même largeur pour toutes
      height: 100, // ✅ Même hauteur
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            number,
            style: GoogleFonts.fredoka(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1c2942),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1c2942),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------
// 🔹 Widget MenuItem (inchangé)
// ------------------------------------------------------
class _MenuItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFd3edea),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1c2942),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF1c2942),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

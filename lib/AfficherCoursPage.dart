import 'package:attendo/GestionCoursPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'AjoutCours.dart'; // Assure-toi que le chemin est correct

class AfficherCoursPage extends StatelessWidget {
  const AfficherCoursPage({super.key});

  Future<void> _supprimerCours(BuildContext context, String coursId) async {
    final now = DateTime.now();

    final seancesSnapshot = await FirebaseFirestore.instance
        .collection('séances')
        .where('courId', isEqualTo: coursId)
        .get();

    bool seanceCommence = false;

    for (var doc in seancesSnapshot.docs) {
      final data = doc.data();
      final horaire = data['horaire'] as Timestamp?;
      if (horaire != null && horaire.toDate().isBefore(now)) {
        seanceCommence = true;
        break;
      }
    }

    if (seanceCommence) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "⏰ Impossible de supprimer ce cours, il a des séances déjà commencées ou terminées.",
            ),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in seancesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      final coursRef = FirebaseFirestore.instance.collection('cours').doc(coursId);
      batch.delete(coursRef);

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Cours et ses séances supprimés avec succès"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const GestionCoursPage()),
            );
          },
        ),
        title: Text(
          "Mes Cours",
          style: GoogleFonts.fredoka(
            fontSize: 26,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgroudCours.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cours')
                  .where('enseignantId', isEqualTo: enseignantId)
                  .orderBy('dateCreation', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF78c8c0),
                      strokeWidth: 3,
                    ),
                  );
                }

                final cours = snapshot.data!.docs;
                if (cours.isEmpty) {
                  return Center(
                    child: Text(
                      "Aucun cours trouvé.",
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
                  itemCount: cours.length,
                  itemBuilder: (context, index) {
                    final data = cours[index].data() as Map<String, dynamic>;
                    final coursId = cours[index].id;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 5),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.3),
                        color: const Color(0xFFDFF7F6),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['nomCours'] ?? 'Sans titre',
                                      style: GoogleFonts.fredoka(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: const Color(0xFF4C9A97),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.black, size: 24),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => AjoutCours(
                                                  coursId: coursId,
                                                  data: data,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red, size: 24),
                                          onPressed: () => _supprimerCours(context, coursId),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                data['description'] ?? '',
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  height: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AfficherSeancesPage extends StatefulWidget {
  const AfficherSeancesPage({super.key});

  @override
  State<AfficherSeancesPage> createState() => _AfficherSeancesPageState();
}

class _AfficherSeancesPageState extends State<AfficherSeancesPage> {
  Future<void> supprimerSeance(BuildContext context, String seanceId) async {
    try {
      await FirebaseFirestore.instance.collection('séances').doc(seanceId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Séance supprimée avec succès")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String enseignantId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Mes Séances",
          style: GoogleFonts.fredoka(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF78c8c0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // 🔹 Image de fond
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgroundSeance1.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 🔹 Contenu principal
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cours')
                  .where('enseignantId', isEqualTo: enseignantId)
                  .snapshots(),
              builder: (context, coursSnapshot) {
                if (!coursSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final coursDocs = coursSnapshot.data!.docs;
                if (coursDocs.isEmpty) {
                  return Center(
                    child: Text(
                      "Aucun cours trouvé.",
                      style: GoogleFonts.fredoka(
                          fontSize: 18, color: Colors.black),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: coursDocs.map((coursDoc) {
                    final coursData = coursDoc.data() as Map<String, dynamic>;
                    final coursId = coursDoc.id;
                    final coursNom = coursData['nomCours'] ?? 'Sans titre';

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('séances')
                          .where('courId', isEqualTo: coursId)
                          .snapshots(),
                      builder: (context, seancesSnapshot) {
                        if (!seancesSnapshot.hasData) {
                          return const SizedBox();
                        }

                        final seancesDocs = seancesSnapshot.data!.docs;

                        if (seancesDocs.isEmpty) return const SizedBox();

                        // 🔹 Carte du cours
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 10.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDFF7F6),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(2, 3),
                              ),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              iconColor: const Color(0xFF2B6D6A),
                              collapsedIconColor: const Color(0xFF2B6D6A),
                              leading: const Icon(Icons.book_outlined,
                                  color: Color(0xFF2B6D6A), size: 35),
                              title: Text(
                                coursNom,
                                style: GoogleFonts.fredoka(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2B6D6A),
                                ),
                              ),
                              children: seancesDocs.map((seanceDoc) {
                                final seanceData =
                                seanceDoc.data() as Map<String, dynamic>;
                                final horaire = seanceData['horaire'] as Timestamp?;
                                final dateHeure = horaire?.toDate();
                                final maintenant = DateTime.now();
                                final bool seancePasse = dateHeure != null &&
                                    dateHeure.isBefore(maintenant);

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      seanceData['nom'] ?? 'Séance sans titre',
                                      style: GoogleFonts.fredoka(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        if (seanceData['description'] != null)
                                          Text(
                                            seanceData['description'],
                                            style: GoogleFonts.fredoka(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        if (dateHeure != null)
                                          Text(
                                            "📅 ${DateFormat('dd/MM/yyyy HH:mm').format(dateHeure)}",
                                            style: GoogleFonts.fredoka(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: seancePasse
                                        ? IconButton(
                                      icon: const Icon(Icons.info,
                                          color: Colors.grey),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "⏰ Cette séance est déjà commencée ou terminée, elle ne peut pas être supprimée.",
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                        : IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      onPressed: () => supprimerSeance(
                                          context, seanceDoc.id),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

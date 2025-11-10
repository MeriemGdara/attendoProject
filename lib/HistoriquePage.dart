import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoriquePage extends StatelessWidget {
  const HistoriquePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String etudiantId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF78c8c0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2B4A),
        title: Text(
          'Historique des présences',
          style: GoogleFonts.fredoka(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('séances')
              .where('idEtudiant', isEqualTo: etudiantId)
              .orderBy('horaire', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF78c8c0)),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'Aucun historique trouvé.',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              );
            }

            final historique = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: historique.length,
              itemBuilder: (context, index) {
                final data = historique[index].data() as Map<String, dynamic>;
                final Timestamp? horaireTs = data['horaire'] as Timestamp?;
                final DateTime horaire =
                horaireTs != null ? horaireTs.toDate() : DateTime.now();

                final bool present = data['present'] ?? false;
                final String courId = data['courId'] ?? '';

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('cours')
                      .doc(courId)
                      .get(),
                  builder: (context, coursSnapshot) {
                    if (!coursSnapshot.hasData) {
                      return const SizedBox();
                    }

                    final coursData =
                    coursSnapshot.data!.data() as Map<String, dynamic>?;
                    final nomCours = coursData?['nomCours'] ?? 'Cours inconnu';

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Icon(
                          present ? Icons.check_circle : Icons.cancel,
                          color: present ? Colors.green : Colors.red,
                          size: 35,
                        ),
                        title: Text(
                          nomCours,
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          "${horaire.day}/${horaire.month}/${horaire.year} • "
                              "${horaire.hour.toString().padLeft(2, '0')}:${horaire.minute.toString().padLeft(2, '0')}",
                          style: GoogleFonts.fredoka(
                            color: Colors.black54,
                          ),
                        ),
                        trailing: Text(
                          present ? "Présent" : "Absent",
                          style: GoogleFonts.fredoka(
                            color: present ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

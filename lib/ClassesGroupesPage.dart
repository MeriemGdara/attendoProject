import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ClassesGroupesPage extends StatefulWidget {
  const ClassesGroupesPage({super.key});

  @override
  State<ClassesGroupesPage> createState() => _ClassesGroupesPageState();
}

class _ClassesGroupesPageState extends State<ClassesGroupesPage> {
  // Pour suivre quel groupe est ouvert pour chaque classe
  Map<String, String?> groupeOuvert = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Classes et Groupes",
          style: GoogleFonts.fredoka(
            fontSize: 22,       // taille de la police
            fontWeight: FontWeight.bold, // gras
            color: const Color(0xFF1c2942), // couleur du texte
          ),
        ),
        backgroundColor: const Color(0xFF5fc2ba),
        centerTitle: true, // centrer le titre si tu veux
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final classes = snapshot.data!.docs;
          if (classes.isEmpty) {
            return const Center(child: Text("Aucune classe trouvée"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classe = classes[index];
              final groupes = List<String>.from(classe['groupes']);

              // Groupe sélectionné pour cette classe
              final groupeSelectionne = groupeOuvert[classe.id];

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom de la classe
                      Text(
                        classe.id,
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                            color: const Color(0xFF1c2942)
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Boutons des groupes
                      Wrap(
                        spacing: 10,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFd3edea),
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                // Toggle : si le même groupe est cliqué, on ferme
                                if (groupeOuvert[classe.id] == groupes[0]) {
                                  groupeOuvert[classe.id] = null;
                                } else {
                                  groupeOuvert[classe.id] = groupes[0];
                                }
                              });
                            },
                            child: Text(groupes[0]),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFd3edea),
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                if (groupeOuvert[classe.id] == groupes[1]) {
                                  groupeOuvert[classe.id] = null;
                                } else {
                                  groupeOuvert[classe.id] = groupes[1];
                                }
                              });
                            },
                            child: Text(groupes[1]),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFd3edea),
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                if (groupeOuvert[classe.id] == "Tous") {
                                  groupeOuvert[classe.id] = null;
                                } else {
                                  groupeOuvert[classe.id] = "Tous";
                                }
                              });
                            },
                            child: const Text("Tous"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Liste des étudiants si un groupe est ouvert
                      if (groupeSelectionne != null)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'etudiant')
                              .where('classe', isEqualTo: classe.id)
                              .snapshots(),
                          builder: (context, etuSnapshot) {
                            if (!etuSnapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            // Filtrer selon le groupe sélectionné
                            final etudiants = etuSnapshot.data!.docs.where((e) {
                              if (groupeSelectionne == "Tous") return true;
                              return e['groupe'] == groupeSelectionne;
                            }).toList();

                            if (etudiants.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text("Aucun étudiant"),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: etudiants.length,
                              itemBuilder: (_, i) {
                                final e = etudiants[i];
                                return ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(e['name'] ?? 'Nom inconnu'),
                                  subtitle: Text(
                                      "Groupe: ${e['groupe']} | Classe: ${e['classe']}"),
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

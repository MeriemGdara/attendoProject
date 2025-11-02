import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ClassesGroupesPage extends StatefulWidget {
  const ClassesGroupesPage({super.key});

  @override
  State<ClassesGroupesPage> createState() => _ClassesGroupesPageState();
}

class _ClassesGroupesPageState extends State<ClassesGroupesPage> {
  Map<String, String?> groupeOuvert = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Classes et Groupes",
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1c2942),
          ),
        ),
        backgroundColor: const Color(0xFF5fc2ba),
        centerTitle: true,
      ),

      // 🌄 Image de fond claire sans couche
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/fond.png",
              fit: BoxFit.cover,
            ),
          ),

          // 🌟 Contenu principal par-dessus
          StreamBuilder<QuerySnapshot>(
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
                  final groupeSelectionne = groupeOuvert[classe.id];

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: Colors.white.withOpacity(0.9), // 🔹 Légèrement transparent
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classe.id,
                            style: GoogleFonts.fredoka(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1c2942),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Wrap(
                            spacing: 10,
                            children: [
                              for (var g in [...groupes, "Tous"])
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFd3edea),
                                    foregroundColor: Colors.black,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      groupeOuvert[classe.id] =
                                      (groupeOuvert[classe.id] == g) ? null : g;
                                    });
                                  },
                                  child: Text(g),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

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
        ],
      ),
    );
  }
}

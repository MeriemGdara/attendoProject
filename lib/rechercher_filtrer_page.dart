import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class RechercherFiltrerPage extends StatefulWidget {
  const RechercherFiltrerPage({super.key});

  @override
  State<RechercherFiltrerPage> createState() => _RechercherFiltrerPageState();
}

class _RechercherFiltrerPageState extends State<RechercherFiltrerPage> {
  String searchQuery = "";
  String? selectedClasse;
  String? selectedGroupe;

  List<String> classesList = [];
  List<String> groupesList = [];

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  /// 🔹 Charger la liste des classes depuis Firestore
  Future<void> loadClasses() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('classes').get();

      setState(() {
        classesList = snapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      debugPrint("Erreur lors du chargement des classes: $e");
    }
  }

  /// 🔹 Charger la liste des groupes selon la classe choisie
  Future<void> loadGroupes(String classeId) async {
    try {
      final doc =
      await FirebaseFirestore.instance.collection('classes').doc(classeId).get();

      if (doc.exists) {
        setState(() {
          groupesList = List<String>.from(doc['groupes']);
          selectedGroupe = null;
        });
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des groupes: $e");
    }
  }

  /// 🔹 Stream des étudiants filtrés selon les sélections
  Stream<QuerySnapshot> getEtudiantsStream() {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'etudiant');

    if (selectedClasse != null && selectedClasse!.isNotEmpty) {
      query = query.where('classe', isEqualTo: selectedClasse);
    }

    if (selectedGroupe != null && selectedGroupe!.isNotEmpty) {
      query = query.where('groupe', isEqualTo: selectedGroupe);
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rechercher et Filtrer',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF5fc2ba),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 Barre de recherche
            TextField(
              decoration: InputDecoration(
                labelText: 'Rechercher un étudiant',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),

            const SizedBox(height: 16),

            // 🔹 Filtres Classe / Groupe dynamiques
            Row(
              children: [
                // ---- CLASSE ----
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Classe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    value: selectedClasse,
                    items: classesList
                        .map((classe) => DropdownMenuItem(
                      value: classe,
                      child: Text(classe),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClasse = value;
                      });
                      if (value != null) loadGroupes(value);
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // ---- GROUPE ----
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Groupe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    value: selectedGroupe,
                    items: groupesList
                        .map((groupe) => DropdownMenuItem(
                      value: groupe,
                      child: Text(groupe),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedGroupe = value;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔹 Liste des étudiants filtrés
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getEtudiantsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "Aucun étudiant trouvé",
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  final etudiants = snapshot.data!.docs.where((doc) {
                    final nom = doc['name'].toString().toLowerCase();
                    return nom.contains(searchQuery);
                  }).toList();

                  if (etudiants.isEmpty) {
                    return const Center(child: Text("Aucun étudiant trouvé"));
                  }

                  return ListView.builder(
                    itemCount: etudiants.length,
                    itemBuilder: (context, index) {
                      final etudiant = etudiants[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: ListTile(
                          leading: const Icon(Icons.person,
                              color: Color(0xFF5fc2ba), size: 30),
                          title: Text(
                            etudiant['name'],
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text(
                            "Classe : ${etudiant['classe']} | Groupe : ${etudiant['groupe']}",
                            style: const TextStyle(fontSize: 14),
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
      ),
    );
  }
}

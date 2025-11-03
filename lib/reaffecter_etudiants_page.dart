import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ReaffecterEtudiantsPage extends StatefulWidget {
  const ReaffecterEtudiantsPage({super.key});

  @override
  State<ReaffecterEtudiantsPage> createState() => _ReaffecterEtudiantsPageState();
}

class _ReaffecterEtudiantsPageState extends State<ReaffecterEtudiantsPage> {
  String searchQuery = "";
  String? selectedEtudiantId;
  String? selectedClasse;
  String? selectedGroupe;

  List<Map<String, dynamic>> etudiants = [];
  List<String> classes = [];
  List<String> groupes = [];

  bool chargement = true;

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  Future<void> chargerDonnees() async {
    setState(() => chargement = true);

    try {
      // 🔹 Charger les étudiants
      final etudiantsSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'etudiant')
          .get();

      etudiants = etudiantsSnap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'classe': data['classe'] ?? '',
          'groupe': data['groupe'] ?? '',
        };
      }).toList();

      // 🔹 Charger les classes
      final classesSnap = await FirebaseFirestore.instance.collection('classes').get();
      classes = classesSnap.docs.map((doc) {
        final data = doc.data();
        return data.containsKey('name') ? data['name'] as String : doc.id;
      }).toList();

      // 🔹 Charger les groupes
      final groupesSnap = await FirebaseFirestore.instance.collection('groupes').get();
      groupes = groupesSnap.docs.map((doc) {
        final data = doc.data();
        return data.containsKey('name') ? data['name'] as String : doc.id;
      }).toList();

      setState(() => chargement = false);
    } catch (e) {
      print("❌ Erreur Firestore : $e");
      setState(() => chargement = false);
    }
  }

  // 🔹 Sélection d’un étudiant
  void etudiantSelectionne(String? id) {
    if (id == null) return;

    final etudiant = etudiants.firstWhere((e) => e['id'] == id);
    setState(() {
      selectedEtudiantId = id;
      selectedClasse = etudiant['classe'];
      selectedGroupe = etudiant['groupe'];
    });
  }

  // 🔹 Réaffecter
  Future<void> reaffecterEtudiant() async {
    if (selectedEtudiantId == null || selectedClasse == null || selectedGroupe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner tous les champs")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(selectedEtudiantId)
          .update({
        'classe': selectedClasse,
        'groupe': selectedGroupe,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Étudiant réaffecté avec succès !")),
      );
    } catch (e) {
      print("❌ Erreur lors de la réaffectation : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la réaffectation")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Réaffecter Étudiants",
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF5fc2ba),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fond.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: chargement
              ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF5fc2ba)),
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Recherche
              TextField(
                decoration: InputDecoration(
                  labelText: "Rechercher un étudiant",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    selectedEtudiantId = null; // 🔹 Réinitialiser la sélection
                  });
                },
              ),
              const SizedBox(height: 16),

              // 🔹 Liste déroulante des résultats filtrés
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Nom de l’étudiant',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: selectedEtudiantId,
                items: etudiants
                    .where((e) {
                  final nom = (e['name'] ?? '').toLowerCase();
                  return nom.contains(searchQuery.toLowerCase());
                })
                    .map((e) {
                  return DropdownMenuItem<String>(
                    value: e['id'],
                    child: Text(e['name'] ?? ''),
                  );
                })
                    .toList(),
                onChanged: etudiantSelectionne,
              ),

              const SizedBox(height: 16),

              // 🔹 Classe actuelle
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Classe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: selectedClasse,
                items: classes.map((c) {
                  return DropdownMenuItem<String>(
                    value: c,
                    child: Text(c),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedClasse = value),
              ),

              const SizedBox(height: 16),

              // 🔹 Groupe actuel
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Groupe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                value: selectedGroupe,
                items: groupes.map((g) {
                  return DropdownMenuItem<String>(
                    value: g,
                    child: Text(g),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedGroupe = value),
              ),

              const SizedBox(height: 30),

              // 🔹 Bouton Réaffecter
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5fc2ba),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: reaffecterEtudiant,
                  child: Text(
                    "Réaffecter l'étudiant",
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

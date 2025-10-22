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
    setState(() {
      chargement = true;
    });

    try {
      // 🔹 Étudiants
      final etudiantsSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'etudiant')
          .get();

      etudiants = etudiantsSnap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('name') && data.containsKey('classe') && data.containsKey('groupe')) {
          return {
            'id': doc.id,
            'name': data['name'],
            'classe': data['classe'],
            'groupe': data['groupe'],
          };
        } else {
          print("⚠ Document ${doc.id} ignoré : champ manquant");
          return null;
        }
      }).where((e) => e != null).toList().cast<Map<String, dynamic>>();

      // 🔹 Classes
      final classesSnap = await FirebaseFirestore.instance.collection('classes').get();
      classes = classesSnap.docs.map((doc) => doc['name'] as String).toList();

      // 🔹 Groupes
      final groupesSnap = await FirebaseFirestore.instance.collection('groupes').get();
      groupes = groupesSnap.docs.map((doc) => doc['name'] as String).toList();

      setState(() {
        chargement = false;
      });
    } catch (e) {
      print("❌ Erreur Firestore : $e");
      setState(() {
        chargement = false;
      });
    }
  }

  // 🔹 Lorsqu’un étudiant est sélectionné
  void etudiantSelectionne(String? id) {
    setState(() {
      selectedEtudiantId = id;
      if (id != null) {
        final etudiant = etudiants.firstWhere((e) => e['id'] == id);
        selectedClasse = etudiant['classe'];
        selectedGroupe = etudiant['groupe'];
      } else {
        selectedClasse = null;
        selectedGroupe = null;
      }
    });
  }

  // 🔹 Réaffecter l’étudiant
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
        const SnackBar(content: Text("Étudiant réaffecté avec succès !")),
      );

      // Réinitialiser les selections
      setState(() {
        selectedEtudiantId = null;
        selectedClasse = null;
        selectedGroupe = null;
        searchQuery = "";
      });
    } catch (e) {
      print("❌ Erreur lors de la réaffectation : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la réaffectation")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final etudiantsFiltres = etudiants
        .where((e) => e['name'].toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Réaffecter Étudiants",
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF5fc2ba),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: chargement
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF5fc2ba)))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Barre de recherche
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
                });
              },
            ),
            const SizedBox(height: 16),

            // 🔹 Dropdown des étudiants
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Nom de l’étudiant',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              value: selectedEtudiantId,
              items: etudiantsFiltres.map((e) => DropdownMenuItem(
                value: e['id'] as String,
                child: Text(e['name'] as String),
              )).toList(),
              onChanged: etudiantSelectionne,
            ),

            const SizedBox(height: 16),

            // 🔹 Classe actuelle
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Classe actuelle',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              value: selectedClasse,
              items: [
                if (selectedClasse != null && !classes.contains(selectedClasse!))
                  DropdownMenuItem(value: selectedClasse!, child: Text(selectedClasse!)),
                ...classes.map((c) => DropdownMenuItem(value: c, child: Text(c))),
              ],
              onChanged: (value) {
                setState(() {
                  selectedClasse = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // 🔹 Groupe actuel
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Groupe actuel',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              value: selectedGroupe,
              items: [
                if (selectedGroupe != null && !groupes.contains(selectedGroupe!))
                  DropdownMenuItem(value: selectedGroupe!, child: Text(selectedGroupe!)),
                ...groupes.map((g) => DropdownMenuItem(value: g, child: Text(g))),
              ],
              onChanged: (value) {
                setState(() {
                  selectedGroupe = value;
                });
              },
            ),

            const SizedBox(height: 30),

            // 🔹 Bouton Réaffecter
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5fc2ba),
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
    );
  }
}

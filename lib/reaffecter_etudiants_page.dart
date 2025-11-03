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
  List<String> classesList = [];
  Map<String, List<String>> classesMap = {}; // map: nomClasse -> listes des groupes
  List<String> groupesDisponibles = [];

  bool chargement = true;

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  Future<void> chargerDonnees() async {
    setState(() => chargement = true);
    try {
      // Charger les étudiants (role == etudiant)
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

      // Charger les classes et extraire leurs groupes depuis chaque document de 'classes'
      final classesSnap = await FirebaseFirestore.instance.collection('classes').get();
      classesList = [];
      classesMap = {};
      for (var doc in classesSnap.docs) {
        final data = doc.data();
        // On considère que le nom de la classe peut être dans 'name' ou sinon on prend doc.id
        final nomClasse = (data.containsKey('name') && (data['name'] is String) && (data['name'] as String).isNotEmpty)
            ? data['name'] as String
            : doc.id;

        // 'groupes' peut être une liste dans le doc (ex: ['G1','G2'])
        List<String> groupes = [];
        if (data.containsKey('groupes') && data['groupes'] is List) {
          groupes = List<String>.from(data['groupes'].map((g) => g.toString()));
        } else {
          // fallback si la classe n'a pas de champ 'groupes'
          groupes = ['G1', 'G2'];
        }

        classesList.add(nomClasse);
        classesMap[nomClasse] = groupes;
      }

      // Tri optionnel
      classesList.sort();

      setState(() => chargement = false);
    } catch (e) {
      print("❌ Erreur Firestore : $e");
      setState(() => chargement = false);
    }
  }

  // Quand un étudiant est choisi dans le dropdown
  void etudiantSelectionne(String? id) {
    if (id == null) return;
    final etu = etudiants.firstWhere((e) => e['id'] == id);
    final classe = (etu['classe'] ?? '').toString();
    final groupe = (etu['groupe'] ?? '').toString();

    setState(() {
      selectedEtudiantId = id;
      selectedClasse = classe.isNotEmpty ? classe : null;
      selectedGroupe = groupe.isNotEmpty ? groupe : null;
    });

    // Charger les groupes pour la classe sélectionnée
    if (selectedClasse != null) {
      chargerGroupesPourClasse(selectedClasse!);
    } else {
      setState(() {
        groupesDisponibles = [];
        selectedGroupe = null;
      });
    }
  }

  // Charger groupes depuis classesMap pour la classe donnée
  Future<void> chargerGroupesPourClasse(String classe) async {
    final groupes = classesMap[classe] ?? ['G1', 'G2'];
    // si le groupe actuel de l'étudiant n'est pas présent, on l'ajoute pour éviter l'erreur Flutter
    if (selectedGroupe != null && selectedGroupe!.isNotEmpty && !groupes.contains(selectedGroupe)) {
      groupes.insert(0, selectedGroupe!); // garder le groupe actuel visible et sélectionnable
    }
    setState(() {
      groupesDisponibles = groupes;
      // si selectedGroupe n'est plus valide -> le réinitialiser
      if (selectedGroupe != null && !groupesDisponibles.contains(selectedGroupe)) {
        selectedGroupe = null;
      }
    });
  }

  // Quand la classe change manuellement
  void classeSelectionnee(String? classe) {
    if (classe == null) return;
    setState(() {
      selectedClasse = classe;
      // réinitialiser groupe (l'utilisateur doit choisir dans la nouvelle liste)
      selectedGroupe = null;
    });
    chargerGroupesPourClasse(classe);
  }

  Future<void> reaffecterEtudiant() async {
    if (selectedEtudiantId == null || selectedClasse == null || selectedGroupe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner étudiant / classe / groupe")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(selectedEtudiantId).update({
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
        title: Text("Réaffecter Étudiants", style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5fc2ba),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/fond.png'), fit: BoxFit.cover),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: chargement
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF5fc2ba)))
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recherche
              TextField(
                decoration: InputDecoration(
                  labelText: "Rechercher un étudiant",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) {
                  setState(() {
                    searchQuery = v;
                    selectedEtudiantId = null; // reset selection until choose
                  });
                },
              ),
              const SizedBox(height: 16),

              // Dropdown étudiants (filtré par searchQuery)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Nom de l’étudiant',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                value: selectedEtudiantId,
                items: etudiants
                    .where((e) =>
                    (e['name'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase()))
                    .map((e) => DropdownMenuItem<String>(value: e['id'], child: Text(e['name'] ?? '')))
                    .toList(),
                onChanged: etudiantSelectionne,
              ),
              const SizedBox(height: 16),

              // Dropdown classes
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Classe',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                value: selectedClasse,
                items: classesList
                    .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                    .toList(),
                onChanged: classeSelectionnee,
              ),
              const SizedBox(height: 16),

              // Dropdown groupes (dépend de la classe)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Groupe',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                value: selectedGroupe,
                items: groupesDisponibles
                    .map((g) => DropdownMenuItem<String>(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) => setState(() => selectedGroupe = value),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5fc2ba),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: reaffecterEtudiant,
                  child: Text("Réaffecter l'étudiant",
                      style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

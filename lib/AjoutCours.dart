import 'package:attendo/GestionCoursPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_enseignant.dart';

class AjoutCours extends StatefulWidget {
  final String? coursId; // null = ajout, non-null = modification
  final Map<String, dynamic>? data;

  const AjoutCours({super.key, this.coursId, this.data});

  @override
  _AjoutCoursState createState() => _AjoutCoursState();
}

class _AjoutCoursState extends State<AjoutCours> {
  final _formKey = GlobalKey<FormState>();
  String nomCours = '';
  String description = '';
  String nomEnseignant = '';
  String enseignantId = '';
  bool _isLoading = true;
  int maxAbsences = 0;

  @override
  void initState() {
    super.initState();

    // Si on modifie, pré-remplir les champs
    if (widget.data != null) {
      nomCours = widget.data!['nomCours'] ?? '';
      description = widget.data!['description'] ?? '';
      maxAbsences = widget.data!['maxAbsences'] ?? 0;
    }

    _loadEnseignantData();
  }

  Future<void> _loadEnseignantData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        enseignantId = user.uid;
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(enseignantId)
            .get();

        setState(() {
          nomEnseignant = doc.exists && doc['name'] != null
              ? doc['name']
              : user.displayName ?? 'Enseignant';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        nomEnseignant = 'Enseignant';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur récupération enseignant: $e')),
      );
    }
  }

  Future<void> _ajouterCours() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        if (widget.coursId == null) {
          // AJOUT
          await FirebaseFirestore.instance.collection('cours').add({
            'nomCours': nomCours,
            'description': description,
            'nomEnseignant': nomEnseignant,
            'enseignantId': enseignantId,
            'dateCreation': Timestamp.now(),
            'maxAbsences': maxAbsences,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Cours ajouté avec succès !')),
          );
        } else {
          // MODIFICATION
          await FirebaseFirestore.instance
              .collection('cours')
              .doc(widget.coursId)
              .update({
            'nomCours': nomCours,
            'description': description,
            'maxAbsences': maxAbsences,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✏️ Cours modifié avec succès !')),
          );
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardEnseignant(
              enseignantId: enseignantId,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgroundCours1.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, top: 10),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => GestionCoursPage()),
                  );
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  )
                ],
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.coursId == null ? "Créer un nouveau cours" : "Modifier le cours",
                        style: GoogleFonts.fredoka(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 25),
                      TextFormField(
                        initialValue: nomCours,
                        decoration: _inputDecoration("Nom du cours", Icons.book),
                        validator: (value) =>
                        value!.isEmpty ? "Entrez le nom du cours" : null,
                        onSaved: (value) => nomCours = value!,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        initialValue: description,
                        decoration: _inputDecoration("Description", Icons.description),
                        validator: (value) =>
                        value!.isEmpty ? "Entrez une description" : null,
                        onSaved: (value) => description = value!,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        initialValue: maxAbsences.toString(),
                        decoration: _inputDecoration(
                            "Nombre maximum d'absences", Icons.warning),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Entrez un nombre";
                          if (int.tryParse(value) == null) return "Entrez un nombre valide";
                          return null;
                        },
                        onSaved: (value) => maxAbsences = int.parse(value!),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Enseignant",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFF58B6B3), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Color(0xFF58B6B3), size: 25),
                            const SizedBox(width: 10),
                            Text(
                              nomEnseignant,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF626571),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF58B6B3),
                            padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 4,
                          ),
                          icon: Icon(
                            widget.coursId == null ? Icons.add : Icons.edit,
                            color: Colors.white,
                          ),
                          label: Text(
                            widget.coursId == null ? 'Ajouter le cours' : 'Modifier le cours',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: _ajouterCours,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF58B6B3)),
      filled: true,
      fillColor: Colors.grey[100],
      labelStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF58B6B3), width: 2),
      ),
    );
  }
}

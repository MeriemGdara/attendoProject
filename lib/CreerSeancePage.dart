import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dashboard_enseignant.dart';

class CreerSeancePage extends StatefulWidget {
  final String enseignantId; // ID de l'enseignant connecté
  const CreerSeancePage({required this.enseignantId, super.key});

  @override
  _CreerSeancePageState createState() => _CreerSeancePageState();
}

class _CreerSeancePageState extends State<CreerSeancePage> {
  final _formKey = GlobalKey<FormState>();
  String nom = '';
  String description = '';
  DateTime? horaire;
  int duree = 60;
  String? courID;
  List<String> classesSelectionnees = [];

  List<Map<String, dynamic>> mesCours = [];
  List<Map<String, dynamic>> mesClasses = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerCoursEtClasses();
  }

  Future<void> _chargerCoursEtClasses() async {
    try {
      print(">>> ID enseignant connecté : ${widget.enseignantId}");
      // Récupérer les cours de l'enseignant
      final queryCours = await FirebaseFirestore.instance
          .collection('cours')
          .where('enseignantId', isEqualTo: widget.enseignantId)
          .get();
      print("Cours trouvés : ${queryCours.docs.length}");
      for (var doc in queryCours.docs) {
        print("Cours: ${doc.data()}");
      }
      // Récupérer les classes avec leurs groupes
      final queryClasses = await FirebaseFirestore.instance.collection('classes').get();

      List<Map<String, dynamic>> classesAvecGroupes = [];

      for (var doc in queryClasses.docs) {
        List<dynamic> groupes = doc['groupes'] ?? [];
        for (var g in groupes) {
          classesAvecGroupes.add({
            'id': '${doc.id}_$g',
            'nom': '${doc.id} - $g',
          });
        }
      }

      setState(() {
        mesCours = queryCours.docs
            .map((doc) => {'id': doc.id, 'nom': doc['nomCours']})
            .toList();

        // Initialiser courID avec le premier cours si la liste n'est pas vide
        courID = mesCours.isNotEmpty ? mesCours[0]['id'] : null;

        mesClasses = classesAvecGroupes;
        _isLoading = false;
      });

      // Debug
      print("Cours récupérés: $mesCours");
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement : $e')),
      );
    }
  }

  Future<void> _sauvegarderSeance() async {
    if (_formKey.currentState!.validate() &&
        horaire != null &&
        courID != null &&
        classesSelectionnees.isNotEmpty) {
      try {
        // 🔹 Ajout dans Firestore
        await FirebaseFirestore.instance.collection('séances').add({
          'nom': nom,
          'description': description,
          'horaire': Timestamp.fromDate(horaire!),
          'duree': duree,
          'courId': courID,
          'enseignantId': widget.enseignantId,
          'classes': classesSelectionnees,
        });

        // 🔹 Message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Séance créée avec succès')),
        );

        // 🔹 Redirection vers le Dashboard Enseignant
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardEnseignant(
              enseignantId: widget.enseignantId,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création : $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
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
          // Fond moderne
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Contenu principal
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.85,
              ),
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
                      const Text(
                        "Créer une séance",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50)),
                      ),
                      const SizedBox(height: 20),

                      // Nom séance
                      _buildTextField("Nom de la séance", Icons.book, (v) => nom = v, true),
                      const SizedBox(height: 15),

                      // Description
                      _buildTextField("Description", Icons.description,
                              (v) => description = v, false,
                          maxLines: 3),
                      const SizedBox(height: 15),

                      // Horaire
                      Text(
                        "Horaire",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton.icon(
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                horaire = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            }
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(horaire == null
                            ? 'Sélectionner horaire'
                            : 'Horaire: ${horaire!.toLocal()}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF58B6B3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Durée
                      DropdownButtonFormField<int>(
                        decoration: _inputDecoration("Durée (minutes)", Icons.timer),
                        value: duree,
                        items: [30, 60, 90, 120]
                            .map((e) =>
                            DropdownMenuItem(value: e, child: Text('$e minutes')))
                            .toList(),
                        onChanged: (value) => setState(() => duree = value!),
                      ),
                      const SizedBox(height: 15),

                      // Sélection cours
                      DropdownButtonFormField<String>(
                        isExpanded: true, // <- IMPORTANT
                        decoration: _inputDecoration("Sélectionner le cours", Icons.book),
                        value: courID,
                        items: mesCours.map((c) => DropdownMenuItem<String>(
                          value: c['id'].toString(),
                          child: Text(c['nom'].toString()),
                        )).toList(),
                        onChanged: (value) => setState(() => courID = value),
                        validator: (value) => value == null ? 'Requis' : null,
                      ),
                      const SizedBox(height: 15),

                      // Sélection multiple classes
                      const Text(
                        "Sélectionner les classes",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      ...mesClasses.map((c) => CheckboxListTile(
                        title: Text(c['nom']),
                        value: classesSelectionnees.contains(c['id']),
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              classesSelectionnees.add(c['id']);
                            } else {
                              classesSelectionnees.remove(c['id']);
                            }
                          });
                        },
                      )),

                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("Créer séance"),
                          onPressed: _sauvegarderSeance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF58B6B3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
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

  Widget _buildTextField(String label, IconData icon, Function(String) onChanged, bool required,
      {int maxLines = 1}) {
    return TextFormField(
      decoration: _inputDecoration(label, icon),
      maxLines: maxLines,
      validator: required ? (v) => v!.isEmpty ? 'Requis' : null : null,
      onChanged: onChanged,
    );
  }
}

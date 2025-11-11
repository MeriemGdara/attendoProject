import 'package:attendo/GestionSeancesPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'dashboard_enseignant.dart';
import 'package:google_fonts/google_fonts.dart';

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
  String codeSeance = ''; // ✅ Code saisi par l'enseignant
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
      final queryCours = await FirebaseFirestore.instance
          .collection('cours')
          .where('enseignantId', isEqualTo: widget.enseignantId)
          .get();

      final queryClasses =
      await FirebaseFirestore.instance.collection('classes').get();

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
        courID = mesCours.isNotEmpty ? mesCours[0]['id'] : null;
        mesClasses = classesAvecGroupes;
        _isLoading = false;
      });
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
        final coursSelectionne = mesCours.firstWhere(
              (c) => c['id'] == courID,
          orElse: () => {'nom': ''},
        );
        String nomCours = coursSelectionne['nom'] ?? '';

        // ✅ Vérification si le code existe déjà
        final existCheck = await FirebaseFirestore.instance
            .collection('séances')
            .where('code', isEqualTo: codeSeance)
            .get();

        if (existCheck.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Ce code de séance existe déjà, veuillez en choisir un autre.')),
          );
          return;
        }

        await FirebaseFirestore.instance.collection('séances').add({
          'nom': nom,
          'description': description,
          'horaire': Timestamp.fromDate(horaire!),
          'duree': duree,
          'courId': courID,
          'enseignantId': widget.enseignantId,
          'classes': classesSelectionnees,
          'code': codeSeance, // ✅ Code saisi par l’enseignant
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Séance créée avec succès')),
        );

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
          // 🔹 Image de fond
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgroundSeance2.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 🔹 Flèche de retour
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.black, size: 26),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GestionSeancesPage(
                          enseignantId: widget.enseignantId,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 🔹 Conteneur blanc scrollable
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.only(top: 150),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Créer une séance",
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildTextField("Nom de la séance", Icons.book,
                              (v) => nom = v, true),
                      const SizedBox(height: 15),

                      _buildTextField("Code de la séance", Icons.qr_code,
                              (v) => codeSeance = v, true),
                      const SizedBox(height: 15),

                      _buildTextField("Description", Icons.description,
                              (v) => description = v, false,
                          maxLines: 3),
                      const SizedBox(height: 15),

                      Text(
                        "Horaire",
                        style: GoogleFonts.fredoka(
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
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      DropdownButtonFormField<int>(
                        decoration:
                        _inputDecoration("Durée (minutes)", Icons.timer),
                        value: duree,
                        items: [30, 60, 90, 120]
                            .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text('$e minutes'),
                        ))
                            .toList(),
                        onChanged: (value) => setState(() => duree = value!),
                      ),
                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: _inputDecoration(
                            "Sélectionner le cours", Icons.book),
                        value: courID,
                        items: mesCours
                            .map((c) => DropdownMenuItem<String>(
                          value: c['id'].toString(),
                          child: Text(c['nom'].toString()),
                        ))
                            .toList(),
                        onChanged: (value) => setState(() => courID = value),
                        validator: (value) =>
                        value == null ? 'Requis' : null,
                      ),
                      const SizedBox(height: 15),

                      Text(
                        "Sélectionner les classes",
                        style: GoogleFonts.fredoka(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      MultiSelectDialogField(
                        items: mesClasses
                            .map((c) =>
                            MultiSelectItem<String>(c['id'], c['nom']))
                            .toList(),
                        title: const Text("Classes"),
                        selectedColor: const Color(0xFF58B6B3),
                        buttonIcon: const Icon(Icons.class_),
                        buttonText: const Text(
                          "Choisir les classes",
                          style: TextStyle(fontSize: 16),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: const Color(0xFF58B6B3), width: 1.5),
                        ),
                        initialValue: classesSelectionnees,
                        onConfirm: (values) {
                          setState(() {
                            classesSelectionnees = List<String>.from(values);
                          });
                        },
                        validator: (values) {
                          if (values == null || values.isEmpty) {
                            return "Veuillez sélectionner au moins une classe";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            "Créer séance",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                          onPressed: _sauvegarderSeance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF58B6B3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 4,
                          ),
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

  Widget _buildTextField(String label, IconData icon,
      Function(String) onChanged, bool required,
      {int maxLines = 1}) {
    return TextFormField(
      decoration: _inputDecoration(label, icon),
      maxLines: maxLines,
      validator: required ? (v) => v!.isEmpty ? 'Requis' : null : null,
      onChanged: onChanged,
    );
  }
}

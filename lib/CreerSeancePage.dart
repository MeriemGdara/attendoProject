import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'QRCodePage.dart';
import 'package:google_fonts/google_fonts.dart';

class CreerSeancePage extends StatefulWidget {
  final String enseignantId; // ID de l'enseignant connecté
  final String? seanceId; // Si on édite une séance
  final Map<String, dynamic>? seanceData; // Données de la séance à éditer

  const CreerSeancePage({
    required this.enseignantId,
    this.seanceId,
    this.seanceData,
    super.key,
  });

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
  String codeSeance = '';
  List<String> classesSelectionnees = [];

  List<Map<String, dynamic>> mesCours = [];
  List<Map<String, dynamic>> mesClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerCoursEtClasses();

    // Génération automatique du code dès l'ouverture de la page
    codeSeance = generateUniqueCode();

    // Si édition, pré-remplir les champs
    if (widget.seanceData != null) {
      final data = widget.seanceData!;
      nom = data['nom'] ?? '';
      description = data['description'] ?? '';
      duree = data['duree'] ?? 60;
      courID = data['courId'];
      codeSeance = data['code'] ?? codeSeance;
      horaire = (data['horaire'] as Timestamp?)?.toDate();
      classesSelectionnees = List<String>.from(data['classes'] ?? []);
    }
  }

  String generateUniqueCode({int length = 6}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<void> _chargerCoursEtClasses() async {
    try {
      final queryCours = await FirebaseFirestore.instance
          .collection('cours')
          .where('enseignantId', isEqualTo: widget.enseignantId)
          .get();

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
        courID ??= mesCours.isNotEmpty ? mesCours[0]['id'] : null;
        mesClasses = classesAvecGroupes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur chargement : $e')),
      );
    }
  }

  // 🔹 Vérification chevauchement avec les séances existantes pour les classes sélectionnées
  Future<bool> _verifierSeancesClasses() async {
    if (classesSelectionnees.isEmpty || horaire == null) return false;

    final collection = FirebaseFirestore.instance.collection('séances');

    for (String classeId in classesSelectionnees) {
      final query = await collection
          .where('classes', arrayContains: classeId)
          .get();

      for (var doc in query.docs) {
        if (widget.seanceId != null && doc.id == widget.seanceId) continue;

        final seanceData = doc.data();
        final Timestamp? horaireExist = seanceData['horaire'] as Timestamp?;
        final int dureeExist = seanceData['duree'] ?? 60;
        if (horaireExist == null) continue;

        final DateTime debutExist = horaireExist.toDate();
        final DateTime finExist = debutExist.add(Duration(minutes: dureeExist));
        final DateTime debutNew = horaire!;
        final DateTime finNew = debutNew.add(Duration(minutes: duree));

        bool chevauchement = debutNew.isBefore(finExist) && finNew.isAfter(debutExist);
        if (chevauchement) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _sauvegarderSeance() async {
    if (_formKey.currentState!.validate() &&
        horaire != null &&
        courID != null &&
        classesSelectionnees.isNotEmpty) {

      // 🔹 Vérifier chevauchement
      if (!await _verifierSeancesClasses()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Impossible de créer la séance : chevauchement avec une séance existante pour ces classes'),
          ),
        );
        return;
      }

      try {
        final collection = FirebaseFirestore.instance.collection('séances');

        if (widget.seanceId != null) {
          // Mise à jour
          await collection.doc(widget.seanceId).update({
            'nom': nom,
            'description': description,
            'horaire': Timestamp.fromDate(horaire!),
            'duree': duree,
            'courId': courID,
            'classes': classesSelectionnees,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Séance mise à jour avec succès')),
          );
        } else {
          // Création
          final existCheck = await collection.where('code', isEqualTo: codeSeance).get();
          if (existCheck.docs.isNotEmpty) codeSeance = generateUniqueCode();

          await collection.add({
            'nom': nom,
            'description': description,
            'horaire': Timestamp.fromDate(horaire!),
            'duree': duree,
            'courId': courID,
            'enseignantId': widget.enseignantId,
            'classes': classesSelectionnees,
            'code': codeSeance,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Séance créée avec succès')),
          );
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur : $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Veuillez remplir tous les champs')),
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
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgroundSeance2.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.only(top: 100),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.seanceId != null ? "Modifier la séance" : "Créer une séance",
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField("Nom de la séance", Icons.book,
                              (v) => nom = v, true, initialValue: nom),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          const Icon(Icons.qr_code, color: Color(0xFF58B6B3)),
                          const SizedBox(width: 10),
                          Text(
                            "Code de la séance : $codeSeance",
                            style: GoogleFonts.fredoka(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QRCodePage(code: codeSeance),
                              ),
                            );
                          },
                          icon: const Icon(Icons.qr_code),
                          label: const Text("Afficher QR Code"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C3E50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildTextField("Description", Icons.description,
                              (v) => description = v, false,
                          maxLines: 3, initialValue: description),
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
                            initialDate: horaire ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(horaire ?? DateTime.now()),
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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<int>(
                        decoration: _inputDecoration("Durée (minutes)", Icons.timer),
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
                        decoration: _inputDecoration("Sélectionner le cours", Icons.book),
                        value: courID,
                        items: mesCours
                            .map((c) => DropdownMenuItem<String>(
                          value: c['id'].toString(),
                          child: Text(c['nom'].toString()),
                        ))
                            .toList(),
                        onChanged: (value) => setState(() => courID = value),
                        validator: (value) => value == null ? 'Requis' : null,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "Sélectionner les classes",
                        style: GoogleFonts.fredoka(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      MultiSelectDialogField(
                        items: mesClasses
                            .map((c) => MultiSelectItem<String>(c['id'], c['nom']))
                            .toList(),
                        title: const Text("Classes"),
                        selectedColor: const Color(0xFF58B6B3),
                        buttonIcon: const Icon(Icons.class_),
                        buttonText: const Text("Choisir les classes", style: TextStyle(fontSize: 16)),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFF58B6B3), width: 1.5),
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
                          label: Text(
                            widget.seanceId != null ? "Mettre à jour" : "Créer séance",
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          onPressed: _sauvegarderSeance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF58B6B3),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
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
      {int maxLines = 1, String? initialValue}) {
    return TextFormField(
      initialValue: initialValue,
      decoration: _inputDecoration(label, icon),
      maxLines: maxLines,
      validator: required ? (v) => v!.isEmpty ? 'Requis' : null : null,
      onChanged: onChanged,
    );
  }
}

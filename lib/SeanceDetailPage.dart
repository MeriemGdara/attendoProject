import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SeanceDetailPage extends StatefulWidget {
  final String seanceId;
  final String nomCours;
  final String description;
  final Timestamp horaire;
  final int dureeMinutes;
  final String classe;
  final String groupe;
  final String codeSeance;

  const SeanceDetailPage({
    super.key,
    required this.seanceId,
    required this.nomCours,
    required this.description,
    required this.horaire,
    required this.dureeMinutes,
    required this.classe,
    required this.groupe,
    required this.codeSeance,
  });

  @override
  State<SeanceDetailPage> createState() => _SeanceDetailPageState();
}

class _SeanceDetailPageState extends State<SeanceDetailPage> {
  late Timer _timer;
  bool _isSessionActive = false;
  bool _isPresent = false;
  DateTime? _attendanceTime;
  final TextEditingController codeController = TextEditingController();

  // 🔹 Nouvelle variable pour stocker le nom de la séance
  String nomSeance = "Chargement...";

  @override
  void initState() {
    super.initState();
    _checkSessionStatus();
    _loadNomSeance(); // 🔹 Charger le nom une seule fois

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _checkSessionStatus();
      });

      final now = DateTime.now();
      final sessionStart = widget.horaire.toDate();
      final maxDuration = sessionStart.add(const Duration(minutes: 15));

      if (_isSessionActive && !_isPresent && now.isAfter(maxDuration)) {
        markAbsent();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⏰ Temps dépassé, vous êtes marqué Absent.'),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  // 🔹 Fonction pour charger le nom de la séance une seule fois
  Future<void> _loadNomSeance() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('séances')
          .doc(widget.seanceId)
          .get();
      if (doc.exists) {
        setState(() {
          nomSeance = doc['nom'] ?? 'Nom non disponible';
        });
      } else {
        setState(() {
          nomSeance = 'Séance introuvable';
        });
      }
    } catch (e) {
      print("Erreur lors du chargement du nom de séance : $e");
      setState(() {
        nomSeance = 'Erreur de chargement';
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    codeController.dispose();
    super.dispose();
  }

  void _checkSessionStatus() {
    final now = DateTime.now();
    final sessionStart = widget.horaire.toDate();
    final sessionEnd = sessionStart.add(Duration(minutes: widget.dureeMinutes));
    _isSessionActive = now.isAfter(sessionStart) && now.isBefore(sessionEnd);
  }

  String getSessionTimer() {
    final now = DateTime.now();
    final sessionStart = widget.horaire.toDate();
    final sessionEnd = sessionStart.add(Duration(minutes: widget.dureeMinutes));

    if (_isPresent && _attendanceTime != null) {
      final elapsed = now.difference(_attendanceTime!);
      final h = elapsed.inHours.toString().padLeft(2, '0');
      final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
      final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
      return "$h:$m:$s";
    } else if (_isSessionActive) {
      final remaining = sessionEnd.difference(now);
      final h = remaining.inHours.toString().padLeft(2, '0');
      final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
      final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
      return "$h:$m:$s";
    }
    return "00:00:00";
  }

  String getTimerLabel() {
    if (_isPresent) {
      return "⏱ Temps écoulé depuis la présence";
    } else if (_isSessionActive) {
      return "⏳ Temps restant pour la séance";
    } else if (DateTime.now().isBefore(widget.horaire.toDate())) {
      return "🕒 Séance à venir";
    } else {
      return "✅ Séance terminée";
    }
  }

  Future<void> markPresent() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final presencesRef = FirebaseFirestore.instance.collection('presences');

    final existing = await presencesRef
        .where('userId', isEqualTo: userId)
        .where('seanceId', isEqualTo: widget.seanceId)
        .get();

    if (existing.docs.isEmpty) {
      await presencesRef.add({
        'userId': userId,
        'seanceId': widget.seanceId,
        'date': Timestamp.now(),
        'classe': widget.classe,
        'groupe': widget.groupe,
        'etat': 'Présent',
      });

      setState(() {
        _isPresent = true;
        _attendanceTime = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Présence enregistrée avec succès !'),
            backgroundColor: Color(0xFF78c8c0),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez déjà marqué votre présence.'),
          backgroundColor: Color(0xFFB45309),
        ),
      );
    }
  }

  Future<void> markAbsent() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final presencesRef = FirebaseFirestore.instance.collection('presences');

    final existing = await presencesRef
        .where('userId', isEqualTo: userId)
        .where('seanceId', isEqualTo: widget.seanceId)
        .get();

    if (existing.docs.isEmpty) {
      await presencesRef.add({
        'userId': userId,
        'seanceId': widget.seanceId,
        'date': Timestamp.now(),
        'classe': widget.classe,
        'groupe': widget.groupe,
        'etat': 'Absent',
      });
    }
  }

  void _checkCode() {
    if (!_isSessionActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La séance n\'est pas active.')),
      );
      return;
    }

    String inputCode = codeController.text.trim();
    if (inputCode.toLowerCase() == widget.codeSeance.toLowerCase()) {
      markPresent();
      codeController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Code incorrect'),
          backgroundColor: Colors.redAccent,
        ),
      );
      codeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final horaireStr = DateFormat('HH:mm').format(widget.horaire.toDate());
    final finStr = DateFormat('HH:mm')
        .format(widget.horaire.toDate().add(Duration(minutes: widget.dureeMinutes)));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF78c8c0),
        centerTitle: true,
        title: Text(
          "Marquer la Présence",
          style: GoogleFonts.fredoka(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        elevation: 4,
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte du cours
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.teal.shade400,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.nomCours,
                      style: GoogleFonts.fredoka(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 🔹 Affichage direct du nom chargé une seule fois
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Nom de la séance : ",
                            style: GoogleFonts.fredoka(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: nomSeance,
                            style: GoogleFonts.fredoka(
                              color: Colors.green.shade900, // vert foncé pour le nom seulement
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Description
              Text(
                "Description",
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  color: const Color(0xFF333333),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description.isNotEmpty
                    ? widget.description
                    : "Aucune description disponible.",
                style: GoogleFonts.fredoka(fontSize: 17, color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),

              // Horaire
              Row(
                children: [
                  const Icon(Icons.schedule, color: Color(0xFF78c8c0)),
                  const SizedBox(width: 10),
                  Text(
                    "$horaireStr - $finStr (${widget.dureeMinutes} min)",
                    style: GoogleFonts.fredoka(
                      fontSize: 17,
                      color: const Color(0xFF444444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 35),

              // Timer
              Center(
                child: Column(
                  children: [
                    Text(
                      getTimerLabel(),
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _isPresent
                            ? const Color(0xFFd1fae5)
                            : Colors.tealAccent.shade100,
                        border: Border.all(
                          color: _isPresent
                              ? Colors.teal.shade700
                              : Colors.teal.shade400,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        getSessionTimer(),
                        style: GoogleFonts.fredoka(
                          fontSize: 46,
                          fontWeight: FontWeight.bold,
                          color: _isPresent ? Colors.black : Colors.teal.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),

              // Code + bouton
              if (!_isPresent && _isSessionActive)
                Column(
                  children: [
                    TextField(
                      controller: codeController,
                      decoration: InputDecoration(
                        labelText: 'Entrez le code de la séance',
                        labelStyle: GoogleFonts.fredoka(fontSize: 17),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon:
                        const Icon(Icons.lock, color: Color(0xFF78c8c0)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _checkCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF78c8c0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          "Marquer ma présence",
                          style: GoogleFonts.fredoka(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              if (!_isSessionActive && !_isPresent)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "⏰ La séance n'est pas encore active ou est déjà terminée.",
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 16),
                      textAlign: TextAlign.center,
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
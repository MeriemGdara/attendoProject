import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'SeanceDetailPage.dart';

class SeancesEtudiantPage extends StatefulWidget {
  const SeancesEtudiantPage({super.key});

  @override
  State<SeancesEtudiantPage> createState() => _SeancesEtudiantPageState();
}

class _SeancesEtudiantPageState extends State<SeancesEtudiantPage> {
  String? studentClasseGroupe;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _getClasseGroupe();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {}); // met à jour les compteurs
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _getClasseGroupe() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        final classe = doc['classe'] ?? '';
        final groupe = doc['groupe'] ?? '';
        setState(() {
          studentClasseGroupe = "${classe}_${groupe}";
        });
      }
    } catch (e) {
      print("Erreur récupération classe/groupe : $e");
    }
  }

  String formatDuree(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return "$h h, $m min";
    if (h > 0) return "$h h";
    return "$m min";
  }

  String formatHoraire(Timestamp horaire) {
    final date = horaire.toDate();
    return DateFormat.Hm().format(date); // exemple : 16:30
  }

  String getCountdown(Timestamp horaire) {
    final now = DateTime.now();
    final diff = horaire.toDate().difference(now);
    if (diff.isNegative) return "Déjà commencé";
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  bool isImportant(Timestamp horaire) {
    final now = DateTime.now();
    final diff = horaire.toDate().difference(now);
    return diff.inMinutes <= 60 && diff.isNegative == false;
  }

  bool isPassed(Timestamp horaire, int dureeMinutes) {
    final now = DateTime.now();
    final endTime = horaire.toDate().add(Duration(minutes: dureeMinutes));
    return now.isAfter(endTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mes Séances",
          style:
          GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF78c8c0),
      ),
      body: studentClasseGroupe == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('séances')
            .where('classes', arrayContains: studentClasseGroupe)
            .snapshots(),
        builder: (context, snapSeances) {
          if (snapSeances.hasError) {
            return Center(child: Text('Erreur: ${snapSeances.error}'));
          }
          if (!snapSeances.hasData || snapSeances.data!.docs.isEmpty) {
            return const Center(
                child: Text('Aucune séance pour votre groupe'));
          }

          final seances = snapSeances.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: seances.length,
            itemBuilder: (context, index) {
              final s = seances[index];
              final coursId = s['courId'] ?? '';
              final horaire = s['horaire'] as Timestamp;
              final description = s['description'] ?? '';
              final dureeMinutes = s['duree'] ?? 0;

              final passed = isPassed(horaire, dureeMinutes);
              final important = isImportant(horaire);
              final countdown =
              passed ? "Séance terminée" : getCountdown(horaire);

              return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('cours')
                      .doc(coursId)
                      .get(),
                  builder: (context, snapCours) {
                    String nomCours = coursId;
                    if (snapCours.hasData && snapCours.data!.exists) {
                      nomCours = snapCours.data!['nomCours'] ?? coursId;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.grey[200],
                      elevation: 4,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                nomCours,
                                style: GoogleFonts.fredoka(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (passed)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF934040),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "Passé",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("Horaire: ${formatHoraire(horaire)}"),
                            Text("Durée: ${formatDuree(dureeMinutes)}"),
                            Text("Description: $description"),
                            const SizedBox(height: 6),
                            if (!passed)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: important
                                          ? const Color(0xFF814B4B)
                                          : const Color(0xFF5E80AC),
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      important
                                          ? "Important"
                                          : "Non important",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Temps restant: $countdown",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.qr_code,
                              color: Colors.black87),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SeanceDetailPage(
                                  seanceId: s.id,
                                  nomCours: nomCours,
                                  description: description,
                                  horaire: horaire,
                                  dureeMinutes: dureeMinutes,
                                  classe: studentClasseGroupe!
                                      .split('_')[0],
                                  groupe: studentClasseGroupe!
                                      .split('_')[1],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  });
            },
          );
        },
      ),
    );
  }
}

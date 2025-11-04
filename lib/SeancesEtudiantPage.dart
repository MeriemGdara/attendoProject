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
  String? userId;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _getClasseGroupe();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _getClasseGroupe() async {
    try {
      userId = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
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
    return DateFormat.Hm().format(horaire.toDate());
  }

  // 🔹 Récupère le statut du user pour une séance donnée
  Future<String?> _getPresenceStatus(String seanceId) async {
    final snap = await FirebaseFirestore.instance
        .collection('presences')
        .where('userId', isEqualTo: userId)
        .where('seanceId', isEqualTo: seanceId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      return snap.docs.first['etat'];
    }
    return null; // pas encore marqué
  }

  String _getTimeRemainingSinceStart(DateTime startTime) {
    final end = startTime.add(const Duration(minutes: 15));
    final now = DateTime.now();
    if (now.isAfter(end)) return "00:00";
    final remaining = end.difference(now);
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> _markAbsentsAfterDeadline(
      String seanceId, DateTime startTime, String classeGroupe) async {
    final now = DateTime.now();
    final limit = startTime.add(const Duration(minutes: 15));
    if (now.isBefore(limit)) return; // encore dans le délai

    final classe = classeGroupe.split('_')[0];
    final groupe = classeGroupe.split('_')[1];

    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('classe', isEqualTo: classe)
        .where('groupe', isEqualTo: groupe)
        .get();

    for (final user in usersSnapshot.docs) {
      final uid = user.id;
      final existingPresence = await FirebaseFirestore.instance
          .collection('presences')
          .where('userId', isEqualTo: uid)
          .where('seanceId', isEqualTo: seanceId)
          .get();

      if (existingPresence.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('presences').add({
          'userId': uid,
          'seanceId': seanceId,
          'etat': 'Absent',
          'date': Timestamp.now(),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mes Séances",
          style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold),
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
            return const Center(child: Text('Aucune séance pour votre groupe'));
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
              final codeSeance = s['code'] ?? '0000';

              return FutureBuilder(
                future: FirebaseFirestore.instance.collection('cours').doc(coursId).get(),
                builder: (context, snapCours) {
                  String nomCours = coursId;
                  if (snapCours.hasData && snapCours.data!.exists) {
                    nomCours = snapCours.data!['nomCours'] ?? coursId;
                  }

                  return FutureBuilder<String?>(
                    future: _getPresenceStatus(s.id),
                    builder: (context, presenceSnap) {
                      final statut = presenceSnap.data;
                      final now = DateTime.now();
                      final startTime = horaire.toDate();
                      final endTime = startTime.add(Duration(minutes: dureeMinutes));

                      _markAbsentsAfterDeadline(s.id, startTime, studentClasseGroupe!);

                      String message = "";
                      Color color = Colors.grey;
                      bool presenceActive = false;

                      // 🧠 Nouvelle logique claire
                      if (now.isBefore(startTime)) {
                        message = "🕒 La séance n’a pas encore commencé";
                        color = const Color(0xFF5E80AC);
                      } else if (now.isAfter(startTime) &&
                          now.isBefore(startTime.add(const Duration(minutes: 15))) &&
                          statut == null) {
                        message =
                        "⏳ Temps restant pour marquer votre présence : ${_getTimeRemainingSinceStart(startTime)}";
                        color = const Color(0xFF814B4B);
                        presenceActive = true;
                      } else if (now.isAfter(startTime.add(const Duration(minutes: 15))) &&
                          now.isBefore(endTime) &&
                          statut == null) {
                        message = "⛔ Délai dépassé — présence non enregistrée";
                        color = Colors.red.shade700;
                      } else if (statut == 'Présent' && now.isBefore(endTime)) {
                        message = "🟢 Présence enregistrée — séance en cours";
                        color = Colors.green;
                      } else if (statut == 'Présent' && now.isAfter(endTime)) {
                        message = "✅ Séance terminée — présence enregistrée";
                        color = Colors.green.shade700;
                      } else if (statut == 'Absent' && now.isAfter(endTime)) {
                        message = "📅 Séance terminée — marqué absent";
                        color = Colors.redAccent;
                      } else if (statut == 'Absent' && now.isBefore(endTime)) {
                        message = "❌ Absence enregistrée — séance en cours";
                        color = Colors.redAccent;
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        color: Colors.grey[200],
                        elevation: 4,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          title: Text(
                            nomCours,
                            style: GoogleFonts.fredoka(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text("Horaire: ${formatHoraire(horaire)}"),
                              Text("Durée: ${formatDuree(dureeMinutes)}"),
                              Text("Description: $description"),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  message,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.qr_code, color: Colors.black87),
                            onPressed: presenceActive
                                ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SeanceDetailPage(
                                    seanceId: s.id,
                                    nomCours: nomCours,
                                    description: description,
                                    horaire: horaire,
                                    dureeMinutes: dureeMinutes,
                                    classe: studentClasseGroupe!.split('_')[0],
                                    groupe: studentClasseGroupe!.split('_')[1],
                                    codeSeance: codeSeance,
                                  ),
                                ),
                              );
                            }
                                : null,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

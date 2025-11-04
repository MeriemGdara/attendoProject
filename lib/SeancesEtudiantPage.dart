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
    return null;
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

  String _getTimeUntilStart(DateTime startTime) {
    final now = DateTime.now();
    if (now.isAfter(startTime)) return "00:00";
    final remaining = startTime.difference(now);
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) {
      return "$h h $m min";
    }
    return "$m:$s";
  }

  Future<void> _markAbsentsAfterDeadline(
      String seanceId, DateTime startTime, String classeGroupe) async {
    final now = DateTime.now();
    final limit = startTime.add(const Duration(minutes: 15));
    if (now.isBefore(limit)) return;

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
          style: GoogleFonts.fredoka(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFF78c8c0),
        elevation: 0,
        centerTitle: false,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
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

          final now = DateTime.now();
          final sortedSeances = seances.toList()..sort((a, b) {
            final startA = (a['horaire'] as Timestamp).toDate();
            final startB = (b['horaire'] as Timestamp).toDate();
            final endA = startA.add(Duration(minutes: a['duree'] ?? 0));
            final endB = startB.add(Duration(minutes: b['duree'] ?? 0));

            final aIsActive = now.isAfter(startA) && now.isBefore(endA);
            final bIsActive = now.isAfter(startB) && now.isBefore(endB);

            if (aIsActive && !bIsActive) return -1;
            if (!aIsActive && bIsActive) return 1;
            return startA.compareTo(startB);
          });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: sortedSeances.length,
            itemBuilder: (context, index) {
              final s = sortedSeances[index];
              final coursId = s['courId'] ?? '';
              final horaire = s['horaire'] as Timestamp;
              final description = s['description'] ?? '';
              final dureeMinutes = s['duree'] ?? 0;
              final codeSeance = s['code'] ?? '0000';
              final nomSeance = s['nom'] ?? 'Séance sans nom'; // ✅ Ajout du nom de la séance

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
                      final startTime = horaire.toDate();
                      final endTime = startTime.add(Duration(minutes: dureeMinutes));

                      _markAbsentsAfterDeadline(s.id, startTime, studentClasseGroupe!);

                      String message = "";
                      Color statusColor = Colors.grey;
                      bool presenceActive = false;
                      bool isEnCours = false;
                      String? countdownText;

                      if (now.isBefore(startTime)) {
                        message = "🕒 La séance n'a pas encore commencé";
                        statusColor = const Color(0xFF5E80AC);
                        countdownText = "Va commencer dans ${_getTimeUntilStart(startTime)}";
                      } else if (now.isAfter(startTime) &&
                          now.isBefore(startTime.add(const Duration(minutes: 15))) &&
                          statut == null) {
                        message =
                        "⏳ Temps restant pour marquer votre présence : ${_getTimeRemainingSinceStart(startTime)}";
                        statusColor = const Color(0xFFD97706);
                        presenceActive = true;
                        isEnCours = true;
                      } else if (now.isAfter(startTime.add(const Duration(minutes: 15))) &&
                          now.isBefore(endTime) &&
                          statut == null) {
                        message = "⛔ Délai dépassé — présence non enregistrée";
                        statusColor = const Color(0xFFDC2626);
                        isEnCours = true;
                      } else if (statut == 'Présent' && now.isBefore(endTime)) {
                        message = "🟢 Présence enregistrée — séance en cours";
                        statusColor = const Color(0xFF16A34A);
                        isEnCours = true;
                      } else if (statut == 'Présent' && now.isAfter(endTime)) {
                        message = "✅ Séance terminée — présence enregistrée";
                        statusColor = const Color(0xFF15803D);
                      } else if (statut == 'Absent' && now.isAfter(endTime)) {
                        message = "📅 Séance terminée — marqué absent";
                        statusColor = const Color(0xFFE11D48);
                      } else if (statut == 'Absent' && now.isBefore(endTime)) {
                        message = "❌ Absence enregistrée — séance en cours";
                        statusColor = const Color(0xFFE11D48);
                        isEnCours = true;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: presenceActive
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
                          child: Card(
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: Colors.white,
                            elevation: isEnCours ? 6 : 2,
                            shadowColor: isEnCours
                                ? statusColor.withOpacity(0.3)
                                : Colors.black.withOpacity(0.08),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 🔸 Indicateur séance en cours
                                  if (isEnCours)
                                    _buildStatusBadge("EN COURS", statusColor),

                                  // 🔸 Compte à rebours avant démarrage
                                  if (countdownText != null)
                                    _buildCountdownBadge(countdownText),

                                  // 🔸 Nom du cours
                                  Text(
                                    nomCours,
                                    style: GoogleFonts.fredoka(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // ✅ Nom de la séance
                                  Text(
                                    nomSeance,
                                    style: GoogleFonts.fredoka(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF374151),
                                    ),
                                  ),

                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDetailRow(
                                          icon: Icons.schedule,
                                          label: "Horaire",
                                          value: formatHoraire(horaire),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildDetailRow(
                                          icon: Icons.timer,
                                          label: "Durée",
                                          value: formatDuree(dureeMinutes),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Description
                                  if (description.isNotEmpty) ...[
                                    Text(
                                      "Description",
                                      style: GoogleFonts.fredoka(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      description,
                                      style: GoogleFonts.fredoka(
                                        fontSize: 16,
                                        color: const Color(0xFF4B5563),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  // Statut
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: statusColor.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            message,
                                            style: GoogleFonts.fredoka(
                                              color: statusColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (presenceActive)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 12),
                                            child: Icon(
                                              Icons.qr_code_2,
                                              color: statusColor,
                                              size: 24,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  Widget _buildStatusBadge(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.fredoka(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownBadge(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF5E80AC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.fredoka(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.fredoka(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

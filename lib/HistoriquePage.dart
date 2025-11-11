import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_enseignant.dart';
class HistoriquePage extends StatefulWidget {
  const HistoriquePage({super.key});

  @override
  State<HistoriquePage> createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> {
  late String etudiantId;
  late String? etudiantClasse;
  late String? etudiantGroupe;
  List<Map<String, dynamic>> presences = [];
  bool loading = true;
  String selectedCours = 'Tous';
  String selectedEtat = 'Tous';

  @override
  void initState() {
    super.initState();
    _loadHistorique();
  }

  Future<void> _loadHistorique() async {
    setState(() => loading = true);

    try {
      etudiantId = FirebaseAuth.instance.currentUser?.uid ?? '';
      print("[v0] UID connecté : $etudiantId");

      if (etudiantId.isEmpty) {
        print("[v0] Erreur : Aucun utilisateur connecté");
        setState(() => loading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(etudiantId)
          .get();

      if (userDoc.exists) {
        etudiantClasse = userDoc['classe'] as String?;
        etudiantGroupe = userDoc['groupe'] as String?;
        print("[v0] Classe: $etudiantClasse, Groupe: $etudiantGroupe");
      }

      final presenceSnapshot = await FirebaseFirestore.instance
          .collection('presences')
          .where('userId', isEqualTo: etudiantId)
          .orderBy('date', descending: true)
          .get();

      print("[v0] Présences trouvées : ${presenceSnapshot.docs.length}");

      List<Map<String, dynamic>> enrichedPresences = [];

      for (var presenceDoc in presenceSnapshot.docs) {
        final presenceData = presenceDoc.data();
        final seanceId = presenceData['seanceId'] as String?;

        if (seanceId != null && seanceId.isNotEmpty) {
          final seanceDoc = await FirebaseFirestore.instance
              .collection('séances')
              .doc(seanceId)
              .get();

          if (seanceDoc.exists) {
            final seanceData = seanceDoc.data() as Map<String, dynamic>;
            final courId = seanceData['courId'] as String?;
            final horaire = seanceData['horaire'] as Timestamp?;

            String nomCours = 'Cours inconnu';
            String enseignantId = '';
            String nomEnseignant = 'Enseignant inconnu';

            if (courId != null && courId.isNotEmpty) {
              final coursDoc = await FirebaseFirestore.instance
                  .collection('cours')
                  .doc(courId)
                  .get();

              if (coursDoc.exists) {
                nomCours = coursDoc['nomCours'] as String? ?? 'Cours inconnu';
                enseignantId = coursDoc['enseignantId'] as String? ?? '';

                if (enseignantId.isNotEmpty) {
                  final enseignantDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(enseignantId)
                      .get();
                  if (enseignantDoc.exists) {
                    nomEnseignant = enseignantDoc['name'] as String? ?? 'Enseignant inconnu';
                  }
                }
              }
            }

            enrichedPresences.add({
              'nomCours': nomCours,
              'etat': presenceData['etat'] ?? 'Absent',
              'date': presenceData['date'],
              'horaire': horaire,
              'seanceId': seanceId,
              'nomEnseignant': nomEnseignant,
            });
          }
        }
      }

      print("[v0] Présences enrichies : ${enrichedPresences.length}");

      setState(() {
        presences = enrichedPresences;
        loading = false;
      });
    } catch (e) {
      print("[v0] Erreur lors du chargement de l'historique: $e");
      setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> getFilteredPresences() {
    return presences.where((presence) {
      bool matchCours = selectedCours == 'Tous' || selectedCours == presence['nomCours'];
      bool matchEtat = selectedEtat == 'Tous' || selectedEtat == presence['etat'];
      return matchCours && matchEtat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPresences = getFilteredPresences();
    final total = filteredPresences.length;
    final totalPresent = filteredPresences.where((p) {
      return (p['etat'] ?? '').toLowerCase() == 'présent';
    }).length;
    final totalAbsent = total - totalPresent;
    final taux = total > 0 ? (totalPresent / total * 100).toStringAsFixed(1) : '0';

    final Set<String> uniqueCours = {
      'Tous',
      ...presences.map((p) => p['nomCours'] as String)
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF58B6B3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () {
            Navigator.pop(context); // 🔙 Retourne simplement à la page précédente
          },
        ),

        title: Text(
          "Historique des présences",
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 26,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: loading
            ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF5fc2ba)),
        )
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              children: [
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatCard(
                      number: totalPresent.toString(),
                      label: 'Présences',
                      backgroundColor: const Color(0xFF67b3ee),
                      icon: Icons.check_circle,
                      iconColor: Colors.white,
                    ),
                    _StatCard(
                      number: totalAbsent.toString(),
                      label: 'Absences',
                      backgroundColor: const Color(0xFFE8A4A4),
                      icon: Icons.cancel,
                      iconColor: Colors.white,
                    ),
                    _StatCard(
                      number: '$taux%',
                      label: 'Taux',
                      backgroundColor: const Color(0xFFf9c178),
                      icon: Icons.trending_up,
                      iconColor: Colors.white,
                    ),
                  ],
                ),

                const SizedBox(height: 50),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtrage par cours
                    Text(
                      'Filtrage par cours',
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1c2942),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFd3edea),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        value: selectedCours,
                        items: uniqueCours.map((cours) {
                          return DropdownMenuItem<String>(
                            value: cours,
                            child: Text(
                              cours,
                              style: GoogleFonts.fredoka(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1c2942),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCours = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Filtrage par présence
                    Text(
                      'Filtrage par présence',
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1c2942),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFd3edea),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        value: selectedEtat,
                        items: const [
                          DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                          DropdownMenuItem(value: 'Présent', child: Text('Présent')),
                          DropdownMenuItem(value: 'Absent', child: Text('Absent')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedEtat = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 50),

                if (filteredPresences.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'Aucun historique trouvé.',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                else
                  Column(
                    children: List.generate(filteredPresences.length, (index) {
                      final presence = filteredPresences[index];
                      final Timestamp? dateTs = presence['date'] as Timestamp?;
                      final DateTime date = dateTs != null ? dateTs.toDate() : DateTime.now();
                      final Timestamp? horaireTs = presence['horaire'] as Timestamp?;
                      final DateTime horaire = horaireTs != null ? horaireTs.toDate() : DateTime.now();

                      final String etat = presence['etat'] ?? 'Absent';
                      final bool present = etat.toLowerCase() == 'présent';
                      final String nomCours = presence['nomCours'] ?? 'Cours inconnu';
                      final String nomEnseignant = presence['nomEnseignant'] ?? 'Enseignant inconnu';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: present ? const Color(0xFF5fc2ba) : const Color(0xFFE8A4A4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),


                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: present ? const Color(0xFF67b3ee) : const Color(0xFFE8A4A4),
                              ),
                              child: Icon(
                                present ? Icons.check : Icons.close,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nomCours,
                                    style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1c2942),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${horaire.day}/${horaire.month}/${horaire.year} à ${horaire.hour.toString().padLeft(2, '0')}:${horaire.minute.toString().padLeft(2, '0')}",
                                    style: GoogleFonts.fredoka(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Enseignant : $nomEnseignant",
                                    style: GoogleFonts.fredoka(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              etat,
                              style: GoogleFonts.fredoka(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: present ? const Color(0xFF5fc2ba) : const Color(0xFFE8A4A4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String number;
  final String label;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.number,
    required this.label,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            number,
            style: GoogleFonts.fredoka(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1c2942),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1c2942),
            ),
          ),
        ],
      ),
    );
  }
}

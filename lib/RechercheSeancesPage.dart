import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RechercheSeancesPage extends StatefulWidget {
  final String enseignantId;
  const RechercheSeancesPage({required this.enseignantId, super.key});

  @override
  State<RechercheSeancesPage> createState() => _RechercheSeancesPageState();
}

class _RechercheSeancesPageState extends State<RechercheSeancesPage> {
  String searchQuery = "";

  Future<void> supprimerSeance(BuildContext context, String seanceId) async {
    try {
      await FirebaseFirestore.instance.collection('séances').doc(seanceId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Séance supprimée avec succès")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Rechercher des séances",
          style: GoogleFonts.fredoka(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF78c8c0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgroundSeance1.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Rechercher par nom de séance ou cours",
                      hintStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => searchQuery = value.toLowerCase()),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('cours')
                        .where('enseignantId', isEqualTo: widget.enseignantId)
                        .snapshots(),
                    builder: (context, coursSnapshot) {
                      if (!coursSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final coursDocs = coursSnapshot.data!.docs;

                      if (coursDocs.isEmpty) {
                        return Center(
                          child: Text(
                            "Aucun cours trouvé.",
                            style: GoogleFonts.fredoka(
                                fontSize: 18, color: Colors.black),
                          ),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: coursDocs.map((coursDoc) {
                          final coursData = coursDoc.data() as Map<String, dynamic>;
                          final coursId = coursDoc.id;
                          final coursNom = coursData['nomCours'] ?? 'Sans titre';

                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('séances')
                                .where('courId', isEqualTo: coursId)
                                .snapshots(),
                            builder: (context, seancesSnapshot) {
                              if (!seancesSnapshot.hasData) return const SizedBox();

                              final seancesDocs = seancesSnapshot.data!.docs.where((seanceDoc) {
                                final seanceData = seanceDoc.data() as Map<String, dynamic>;
                                final nomSeance = (seanceData['nom'] ?? '').toLowerCase();
                                return nomSeance.contains(searchQuery) ||
                                    coursNom.toLowerCase().contains(searchQuery);
                              }).toList();

                              if (seancesDocs.isEmpty) return const SizedBox();

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 10.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDFF7F6),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(2, 3),
                                    ),
                                  ],
                                ),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    dividerColor: Colors.transparent,
                                  ),
                                  child: ExpansionTile(
                                    iconColor: const Color(0xFF2B6D6A),
                                    collapsedIconColor: const Color(0xFF2B6D6A),
                                    leading: const Icon(Icons.book_outlined,
                                        color: Color(0xFF2B6D6A), size: 35),
                                    title: Text(
                                      coursNom,
                                      style: GoogleFonts.fredoka(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2B6D6A),
                                      ),
                                    ),
                                    children: seancesDocs.map((seanceDoc) {
                                      final seanceData = seanceDoc.data() as Map<String, dynamic>;
                                      final Timestamp? horaireTimestamp = seanceData['horaire'] as Timestamp?;
                                      final dateHeure = horaireTimestamp?.toDate();
                                      final duree = seanceData['duree'] ?? 60;
                                      final maintenant = DateTime.now();

                                      // Statut dynamique
                                      String statutSeance() {
                                        if (dateHeure == null) return "";
                                        final finSeance = dateHeure.add(Duration(minutes: duree));
                                        if (maintenant.isAfter(finSeance)) return "Terminé";
                                        if (maintenant.isAfter(dateHeure) && maintenant.isBefore(finSeance)) return "En cours";
                                        final diff = dateHeure.difference(maintenant);
                                        final minutes = diff.inMinutes;
                                        final secondes = diff.inSeconds % 60;
                                        return "Commence dans ${minutes.abs()}m ${secondes.abs()}s";
                                      }

                                      bool peutSupprimer() {
                                        if (dateHeure == null) return false;
                                        final finSeance = dateHeure.add(Duration(minutes: duree));
                                        return !(maintenant.isBefore(finSeance) && maintenant.isBefore(dateHeure));
                                      }

                                      return Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                        child: IntrinsicHeight(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      seanceData['nom'] ?? 'Séance sans titre',
                                                      style: GoogleFonts.fredoka(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    if (seanceData['description'] != null)
                                                      Text(
                                                        seanceData['description'],
                                                        style: GoogleFonts.fredoka(
                                                          fontSize: 14,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    if (dateHeure != null)
                                                      Text(
                                                        "📅 ${DateFormat('dd/MM/yyyy HH:mm').format(dateHeure)}",
                                                        style: GoogleFonts.fredoka(
                                                          fontSize: 14,
                                                          color: Colors.black54,
                                                        ),
                                                      ),
                                                    if (seanceData['code'] != null)
                                                      RichText(
                                                        text: TextSpan(
                                                          children: [
                                                            TextSpan(
                                                              text: "🔑 Code : ",
                                                              style: GoogleFonts.fredoka(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.black,
                                                              ),
                                                            ),
                                                            TextSpan(
                                                              text: seanceData['code'],
                                                              style: GoogleFonts.fredoka(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.green.shade900,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: statutSeance() == "Terminé"
                                                          ? Colors.grey
                                                          : statutSeance() == "En cours"
                                                          ? Colors.orange
                                                          : Colors.blue,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      statutSeance(),
                                                      textAlign: TextAlign.center,
                                                      style: GoogleFonts.fredoka(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  GestureDetector(
                                                    onTap: peutSupprimer()
                                                        ? null
                                                        : () => supprimerSeance(context, seanceDoc.id),
                                                    child: Icon(
                                                      Icons.delete,
                                                      color: peutSupprimer() ? Colors.grey : Colors.redAccent,
                                                      size: 26,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

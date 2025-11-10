import 'package:attendo/GestionCoursPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AfficherCoursPage.dart';

class RechercheCoursPage extends StatefulWidget {
  const RechercheCoursPage({super.key});

  @override
  State<RechercheCoursPage> createState() => _RechercheCoursPageState();
}

class _RechercheCoursPageState extends State<RechercheCoursPage> {
  String searchQuery = "";
  String enseignantId = "";

  @override
  void initState() {
    super.initState();
    _loadEnseignantId();
  }

  void _loadEnseignantId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      enseignantId = user.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF78c8c0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const GestionCoursPage()),
            );
          },
        ),
        title: Text(
          " Rechercher mes cours",
          style: GoogleFonts.fredoka(
            fontSize: 22,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // --- Image de fond ---
          Positioned.fill(
            child: Image.asset('assets/images/backgroudCours.jpg', fit: BoxFit.cover),
          ),
          const SizedBox(height: 60),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "🔍 Rechercher un cours...",
                      hintStyle: const TextStyle(color: Colors.black,fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.black),
                    onChanged: (value) => setState(() => searchQuery = value),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('cours')
                        .where('enseignantId', isEqualTo: enseignantId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator(color: Colors.white));
                      }

                      // Filtrer selon le texte saisi
                      final filtered = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['nomCours'] ?? '')
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase()) ||
                            (data['nomEnseignant'] ?? '')
                                .toLowerCase()
                                .contains(searchQuery.toLowerCase());
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(
                            child: Text("Aucun cours trouvé.",
                                style: TextStyle(color: Colors.black)));
                      }

                      return ListView(
                        padding: const EdgeInsets.only(top:0, left: 16, right: 16, bottom: 10),
                        children: filtered.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 8,
                              shadowColor: Colors.black.withOpacity(0.3),
                              color: const Color(0xFFDFF7F6), // couleur douce
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['nomCours'] ?? 'Sans titre',
                                      style: GoogleFonts.fredoka(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: const Color(0xFF4C9A97),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "${data['description'] ?? ''}",
                                      style: GoogleFonts.fredoka(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        height: 1.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

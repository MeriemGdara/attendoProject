import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _contenuController = TextEditingController();
  bool showAddCard = false;

  /// 🔹 ID de la note en cours d'édition
  String? editingNoteId;

  /// 🔹 Récupérer l'ID du user connecté
  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// 🔹 Ajouter ou modifier une note
  Future<void> _enregistrerNote({String? id}) async {
    if (_titreController.text.isEmpty ||
        _contenuController.text.isEmpty ||
        userId.isEmpty) return;

    if (id == null) {
      // Nouvelle note
      await FirebaseFirestore.instance.collection('notes').add({
        'userId': userId,
        'titre': _titreController.text,
        'contenu': _contenuController.text,
        'date': FieldValue.serverTimestamp(),
      });
    } else {
      // Modifier note existante
      await FirebaseFirestore.instance.collection('notes').doc(id).update({
        'titre': _titreController.text,
        'contenu': _contenuController.text,
      });
    }

    _titreController.clear();
    _contenuController.clear();
    editingNoteId = null; // réinitialiser
    setState(() => showAddCard = false);
  }

  /// 🔹 Supprimer une note
  Future<void> _supprimerNote(String id) async {
    await FirebaseFirestore.instance.collection('notes').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mes Notes",
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1c2942),
          ),
        ),
        backgroundColor: const Color(0xFF5fc2ba),
      ),
      body: Stack(
        children: [
          // 🌄 Fond image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/fondNotes.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 💬 Liste des notes
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notes')
                .where('userId', isEqualTo: userId)
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Erreur de chargement des notes",
                    style: GoogleFonts.fredoka(color: Colors.white),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "Aucune note pour l’instant",
                    style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white),
                  ),
                );
              }

              final notes = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.only(
                    top: 80, left: 16, right: 16, bottom: 100),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index].data() as Map<String, dynamic>;
                  final noteId = notes[index].id;

                  final Timestamp? ts = note['date'];
                  final dateStr = ts != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                      ts.millisecondsSinceEpoch)
                      .toLocal()
                      .toString()
                      .split('.')[0]
                      : '';

                  return Card(
                    color: Colors.white.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: Text(
                        note['titre'] ?? '',
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A2B4A),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note['contenu'] ?? '',
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Color(0xFF5fc2ba)),
                            onPressed: () {
                              _titreController.text = note['titre'];
                              _contenuController.text = note['contenu'];
                              editingNoteId = noteId; // stocker l’ID
                              setState(() => showAddCard = true);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () => _supprimerNote(noteId),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // 🪄 Carte d’ajout / édition
          if (showAddCard)
            Center(
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1A2B4A), width: 3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      editingNoteId == null ? "Nouvelle Note" : "Modifier Note",
                      style: GoogleFonts.fredoka(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A2B4A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _titreController,
                      decoration: const InputDecoration(
                        labelText: "Titre",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _contenuController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Contenu",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A2B4A),
                          ),
                          onPressed: () =>
                              _enregistrerNote(id: editingNoteId),
                          child: const Text("Enregistrer",
                              style: TextStyle(color: Colors.white)),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF1A2B4A), width: 2),
                          ),
                          onPressed: () {
                            _titreController.clear();
                            _contenuController.clear();
                            editingNoteId = null;
                            setState(() => showAddCard = false);
                          },
                          child: const Text("Annuler"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ➕ Bouton flottant
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF1A2B4A),
              onPressed: () {
                _titreController.clear();
                _contenuController.clear();
                editingNoteId = null;
                setState(() => showAddCard = true);
              },
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

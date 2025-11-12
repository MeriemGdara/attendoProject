import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _contenuController = TextEditingController();
  bool showAddCard = false;
  String? editingNoteId;
  DateTime? _selectedDate;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      calendar.CalendarApi.calendarScope,
      'https://www.googleapis.com/auth/calendar.events',
    ],
  );

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<http.Client?> _getGoogleAuthClient() async {
    GoogleSignInAccount? account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn();
    if (account == null) return null;

    final headers = await account.authHeaders;
    return GoogleAuthClient(headers);
  }

  Future<String?> _ajouterEvenementCalendar(String titre, String contenu) async {
    if (_selectedDate == null) return null;
    try {
      final client = await _getGoogleAuthClient();
      if (client == null) return null;

      final calendarApi = calendar.CalendarApi(client);
      final event = calendar.Event(
        summary: titre,
        description: contenu,
        start: calendar.EventDateTime(
          dateTime: _selectedDate,
          timeZone: "Africa/Tunis",
        ),
        end: calendar.EventDateTime(
          dateTime: _selectedDate!.add(const Duration(hours: 1)),
          timeZone: "Africa/Tunis",
        ),
      );

      final createdEvent = await calendarApi.events.insert(event, "primary");
      client.close();
      return createdEvent.id;
    } catch (e) {
      debugPrint("Erreur lors de l'ajout à Google Calendar : $e");
      return null;
    }
  }

  Future<void> _choisirDate(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _enregistrerNote({String? id}) async {
    if (_titreController.text.isEmpty ||
        _contenuController.text.isEmpty ||
        userId.isEmpty) return;

    String? eventId;
    if (_selectedDate != null) {
      eventId = await _ajouterEvenementCalendar(
        _titreController.text,
        _contenuController.text,
      );
    }

    final noteData = {
      'userId': userId,
      'titre': _titreController.text,
      'contenu': _contenuController.text,
      'date': FieldValue.serverTimestamp(),
      if (_selectedDate != null) 'evenementDate': _selectedDate,
      if (eventId != null) 'eventId': eventId,
    };

    if (id == null) {
      await FirebaseFirestore.instance.collection('notes').add(noteData);
    } else {
      await FirebaseFirestore.instance.collection('notes').doc(id).update(noteData);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Note enregistrée avec succès")),
    );

    _titreController.clear();
    _contenuController.clear();
    editingNoteId = null;
    _selectedDate = null;
    setState(() => showAddCard = false);
  }

  Future<void> _supprimerNote(String id) async {
    final doc = await FirebaseFirestore.instance.collection('notes').doc(id).get();
    final data = doc.data();
    final eventId = data?['eventId'];

    await FirebaseFirestore.instance.collection('notes').doc(id).delete();

    if (eventId != null) {
      try {
        final client = await _getGoogleAuthClient();
        if (client == null) return;
        final calendarApi = calendar.CalendarApi(client);
        await calendarApi.events.delete("primary", eventId);
        client.close();
      } catch (e) {
        debugPrint("Erreur suppression événement : $e");
      }
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _contenuController.dispose();
    super.dispose();
  }
  // ==============================================================
  // 🔸 INTERFACE UTILISATEUR
  // ==============================================================

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
          // 🌄 Arrière-plan
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
                return const Center(child: Text("Erreur de chargement"));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Aucune note pour l’instant"));
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
                      ? DateTime.fromMillisecondsSinceEpoch(ts.millisecondsSinceEpoch)
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
                          Text(note['contenu'] ?? ''),
                          const SizedBox(height: 5),
                          Text(dateStr, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF5fc2ba)),
                            onPressed: () {
                              _titreController.text = note['titre'];
                              _contenuController.text = note['contenu'];
                              editingNoteId = noteId;
                              setState(() => showAddCard = true);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
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

          // 🪄 Carte d’ajout / modification
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

                    // Champ titre
                    TextField(
                      controller: _titreController,
                      decoration: const InputDecoration(
                        labelText: "Titre",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Champ contenu
                    TextField(
                      controller: _contenuController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Contenu",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Sélecteur de date
                    TextButton.icon(
                      onPressed: () => _choisirDate(context),
                      icon: const Icon(Icons.calendar_today, color: Color(0xFF1A2B4A)),
                      label: Text(
                        _selectedDate == null
                            ? "Choisir une date"
                            : "Date : ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} "
                            "à ${_selectedDate!.hour.toString().padLeft(2, '0')}:${_selectedDate!.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Color(0xFF1A2B4A)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Boutons d’action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A2B4A),
                          ),
                          onPressed: () => _enregistrerNote(id: editingNoteId),
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
                            _selectedDate = null;
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
                _selectedDate = null;
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

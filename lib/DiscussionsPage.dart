import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:attendo/SendMessagePage.dart';

class DiscussionsPage extends StatefulWidget {
  const DiscussionsPage({super.key});

  @override
  State<DiscussionsPage> createState() => _DiscussionsPageState();
}

class _DiscussionsPageState extends State<DiscussionsPage> {
  final String teacherId = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Discussions",
          style: GoogleFonts.fredoka(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: const Color(0xFF78c8c0),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('messages')
            .where('enseignantId', isEqualTo: teacherId)
            .orderBy('date', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final messages = snapshot.data!.docs;

          // Ne garder que les messages envoyés par l'étudiant
          final studentMessages = messages
              .where((m) => m['etudiantId'] != null || m['senderId'] != teacherId)
              .toList();



          if (studentMessages.isEmpty) return const Center(child: Text("Aucune discussion"));

          // Récupérer tous les studentId uniques
          final studentIds = studentMessages.map((m) => m['etudiantId'] as String).toSet().toList();

          return FutureBuilder<QuerySnapshot>(
            future: _firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: studentIds)
                .get(),
            builder: (context, usersSnapshot) {
              if (!usersSnapshot.hasData) return const Center(child: CircularProgressIndicator());

              // Map studentId -> studentName
              final Map<String, String> studentNames = {};
              for (var doc in usersSnapshot.data!.docs) {
                studentNames[doc.id] = doc['name'] ?? 'Étudiant';
              }

              // Regrouper messages par étudiant
              Map<String, List<QueryDocumentSnapshot>> grouped = {};
              for (var msg in studentMessages) {
                final studentId = msg['etudiantId'];
                grouped.putIfAbsent(studentId, () => []).add(msg);
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: grouped.entries.map((entry) {
                  final studentId = entry.key;
                  final msgs = entry.value;
                  final lastMsgDoc = msgs.last;
                  final lastMsg = lastMsgDoc['message'];
                  final isRead = lastMsgDoc['isRead'] ?? false;
                  final studentName = studentNames[studentId] ?? 'Étudiant';

                  return Card(
                    color: isRead ? Colors.white : const Color(0xFFDFF7F6),
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Étudiant : ",
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black, // couleur pour "Étudiant :"
                              ),
                            ),
                            TextSpan(
                              text: studentName, // par ex. "Fridoka Angra"
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: const Color(0xFF2B6D6A), // couleur différente pour le nom
                              ),
                            ),
                          ],
                        ),
                      ),

                      subtitle: Text(
                        lastMsg,
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: (!isRead && lastMsgDoc['senderId'] != teacherId)
                          ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "NON LU",
                          style: GoogleFonts.fredoka(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                          : null,
                      onTap: () async {
                        // Marquer seulement les messages reçus de l'étudiant
                        for (var msg in msgs) {
                          if (!(msg['isRead'] ?? false) && msg['senderId'] != teacherId) {
                            await msg.reference.update({'isRead': true});
                          }
                        }

                        // Ouvrir SendMessagePage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SendMessagePage(otherUserId: studentId),
                          ),
                        );
                      },

                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}

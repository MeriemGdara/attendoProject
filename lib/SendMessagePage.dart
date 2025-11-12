import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class SendMessagePage extends StatefulWidget {
  final String otherUserId;
  const SendMessagePage({super.key, required this.otherUserId});

  @override
  State<SendMessagePage> createState() => _SendMessagePageState();
}

class _SendMessagePageState extends State<SendMessagePage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String currentUserId;
  String currentUserRole = "etudiant";
  String currentUserName = "Utilisateur";
  String otherUserName = "Utilisateur";

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _loadUsers().then((_) {
      _markMessagesAsRead();
    });
  }

  Future<void> _markMessagesAsRead() async {
    final query = await _firestore
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      final data = doc.data();
      final enseignantId = data['enseignantId'];
      final etudiantId = data['etudiantId'];
      final senderId = data['senderId'];

      final isBetweenUsers =
          (enseignantId == currentUserId || enseignantId == widget.otherUserId) &&
              (etudiantId == currentUserId || etudiantId == widget.otherUserId);

      final isReceivedByMe = senderId != currentUserId;

      if (isBetweenUsers && isReceivedByMe) {
        await doc.reference.update({'isRead': true});
      }
    }
  }

  Future<void> _loadUsers() async {
    final currentSnapshot =
    await _firestore.collection('users').doc(currentUserId).get();
    final otherSnapshot =
    await _firestore.collection('users').doc(widget.otherUserId).get();

    setState(() {
      currentUserRole = currentSnapshot.data()?['role'] ?? "etudiant";
      currentUserName = currentSnapshot.data()?['name'] ?? "Utilisateur";
      otherUserName = otherSnapshot.data()?['name'] ?? "Utilisateur";
    });
  }

  void sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();

    await _firestore.collection('messages').add({
      'enseignantId': currentUserRole == 'enseignant'
          ? currentUserId
          : widget.otherUserId,
      'etudiantId': currentUserRole == 'etudiant'
          ? currentUserId
          : widget.otherUserId,
      'message': messageText,
      'date': FieldValue.serverTimestamp(),
      'isRead': false,
      'senderId': currentUserId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Discussion $currentUserName et $otherUserName',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black
          ),
        ),
        backgroundColor: const Color(0xFF78c8c0),
        elevation: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .orderBy('date', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("Aucun message pour le moment",
                          style: TextStyle(fontSize: 18)));
                }

                final messages = snapshot.data!.docs.where((msg) {
                  final enseignantId = msg['enseignantId'];
                  final etudiantId = msg['etudiantId'];
                  return (enseignantId == currentUserId ||
                      enseignantId == widget.otherUserId) &&
                      (etudiantId == currentUserId ||
                          etudiantId == widget.otherUserId);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUserId;
                    final messageText = msg['message'];
                    final timestamp = msg['date']?.toDate() ?? DateTime.now();

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFF78c8c0).withOpacity(0.25)
                              : const Color(0xFFFFF5E1),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(22),
                            topRight: const Radius.circular(22),
                            bottomLeft: Radius.circular(isMe ? 22 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 22),
                          ),
                          border: Border.all(
                            color: const Color(0xFF1A2B4A), // bleu foncé
                            width: 2, // épaisseur de la bordure
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1), // shadow plus visible
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              messageText,
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')} - ${timestamp.day}/${timestamp.month}/${timestamp.year}",
                              style: GoogleFonts.fredoka(
                                fontSize: 15,
                                color: Colors.black,
                              ),
                            )
                          ],
                        ),
                      ),
                    );

                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Écris ton message...',
                      hintStyle: GoogleFonts.fredoka(
                        color: Colors.black38,
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF78c8c0),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 30),
                    onPressed: sendMessage,
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:attendo/SendMessagePage.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with TickerProviderStateMixin {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAbsencesAndNotify();
    _listenNewNotifications();
    _listenNewMessages();
    print("User ID connecté: $userId");
  }

  // -------------------- Vérification des absences --------------------
  Future<void> _checkAbsencesAndNotify() async {
    final presencesSnapshot = await _firestore
        .collection('presences')
        .where('userId', isEqualTo: userId)
        .where('etat', isEqualTo: 'Absent')
        .get();

    if (presencesSnapshot.docs.isEmpty) return;

    Map<String, int> absencesByCours = {};

    final seanceIds = presencesSnapshot.docs.map((p) => p['seanceId']).toSet().toList();
    final seancesSnapshot = await _firestore
        .collection('séances')
        .where(FieldPath.documentId, whereIn: seanceIds)
        .get();

    Map<String, String> seanceToCours = {};
    for (var s in seancesSnapshot.docs) {
      seanceToCours[s.id] = s['courId'];
    }

    for (var pres in presencesSnapshot.docs) {
      final seanceId = pres['seanceId'];
      final coursId = seanceToCours[seanceId];
      if (coursId == null) continue;
      absencesByCours[coursId] = (absencesByCours[coursId] ?? 0) + 1;
    }

    final coursIds = absencesByCours.keys.toList();
    final coursSnapshot = await _firestore
        .collection('cours')
        .where(FieldPath.documentId, whereIn: coursIds)
        .get();

    for (var c in coursSnapshot.docs) {
      final coursId = c.id;
      final nomCours = c['nomCours'] ?? 'Cours inconnu';
      final maxAbsences = c['maxAbsences'] ?? 0;

      if ((absencesByCours[coursId] ?? 0) >= maxAbsences) {
        final notifSnapshot = await _firestore
            .collection('notifications')
            .where('etudiantId', isEqualTo: userId)
            .where('coursId', isEqualTo: coursId)
            .get();

        if (notifSnapshot.docs.isEmpty) {
          await _firestore.collection('notifications').add({
            'etudiantId': userId,
            'coursId': coursId,
            'message':
            "Vous avez atteint le nombre maximum d'absences (${absencesByCours[coursId]}) pour $nomCours",
            'date': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
    }
  }

  // -------------------- ALERTES TOP --------------------
  void _showTopAlert(String message, {bool isMessage = false, String? senderName}) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final emoji = isMessage ? "📩" : "🔔";
    final displayMessage = senderName != null ? "$emoji $senderName : $message" : "$emoji $message";

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            offset: Offset(0, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                displayMessage,
                style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3)).then((_) => overlayEntry.remove());
  }

  void _listenNewNotifications() {
    _firestore
        .collection('notifications')
        .where('etudiantId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          _showTopAlert(docChange.doc['message'], isMessage: false);
        }
      }
    });
  }

  void _listenNewMessages() {
    _firestore
        .collection('messages')
        .where('etudiantId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added &&
            docChange.doc['senderId'] != userId) {
          final teacherId = docChange.doc['enseignantId'];

          _firestore.collection('users').doc(teacherId).get().then((teacherDoc) {
            final teacherName = teacherDoc['name'] ?? "Enseignant";
            _showTopAlert(docChange.doc['message'], isMessage: true, senderName: teacherName);
          });
        }
      }
    });
  }

  // -------------------- BUILD --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(
          "Notifications & Messages",
          style: GoogleFonts.fredoka(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFF78c8c0),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('notifications')
                .where('etudiantId', isEqualTo: userId)
                .snapshots(),
            builder: (context, notifSnapshot) {
              int notificationsCount = 0;
              if (notifSnapshot.hasData) {
                notificationsCount = notifSnapshot.data!.docs
                    .where((doc) => doc['isRead'] == false)
                    .length;
              }

              return StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('messages')
                    .where('etudiantId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, msgSnapshot) {
                  int messagesCount = 0;
                  if (msgSnapshot.hasData) {
                    messagesCount = msgSnapshot.data!.docs
                        .where((doc) => doc['isRead'] == false && doc['senderId'] != userId)
                        .length;
                  }

                  Widget buildTab(String label, int count) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (count > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6B6B),
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                              ),
                              child: Text(
                                '$count',
                                style: GoogleFonts.fredoka(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(child: buildTab("Notifications", notificationsCount)),
                      Tab(child: buildTab("Messages", messagesCount)),
                    ],
                    labelColor: const Color(0xFF2B6D6A),
                    unselectedLabelColor: Colors.black54,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(
                        color: Color(0xFF2B6D6A),
                        width: 3,
                      ),
                      insets: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF8FFFE),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ------------------ Onglet Notifications ------------------
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('notifications')
                .where('etudiantId', isEqualTo: userId)
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(Icons.notifications_off_rounded, "Aucune notification", "Vous êtes à jour !");
              }

              final notifications = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final message = notif['message'];
                  final date = notif['date']?.toDate() ?? DateTime.now();
                  final isRead = notif['isRead'] ?? false;

                  return GestureDetector(
                    onTap: () async {
                      if (!isRead) {
                        await notif.reference.update({"isRead": true});
                      }
                    },
                    child: _buildNotificationCard(message, date, isRead, notif),
                  );
                },
              );
            },
          ),

          // ------------------ Onglet Messages ------------------
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('messages')
                .where('etudiantId', isEqualTo: userId)
                .orderBy('date', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final messages = snapshot.data!.docs;

              Map<String, List<QueryDocumentSnapshot>> grouped = {};
              for (var msg in messages) {
                final teacherId = msg['enseignantId'];
                grouped.putIfAbsent(teacherId, () => []).add(msg);
              }

              if (grouped.isEmpty) {
                return _buildEmptyState(Icons.mail_outline_rounded, "Aucun message", "Commencez une conversation !");
              }

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: grouped.entries.map((entry) {
                  final teacherId = entry.key;
                  final msgs = entry.value;
                  final lastMsgDoc = msgs.last;
                  final lastMsg = lastMsgDoc['message'];
                  final isRead = lastMsgDoc['isRead'] ?? false;

                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('users').doc(teacherId).get(),
                    builder: (context, teacherSnapshot) {
                      if (!teacherSnapshot.hasData) return const SizedBox();
                      final teacherName = teacherSnapshot.data!['name'] ?? "Enseignant";

                      return _buildMessageCard(teacherId, msgs, teacherName, lastMsg, isRead);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // -------------------- Widgets --------------------
  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF78c8c0).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: const Color(0xFF78c8c0)),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: GoogleFonts.fredoka(fontSize: 14, color: Colors.black38)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(String message, DateTime date, bool isRead, QueryDocumentSnapshot notif) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFDFF7F6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(
          color: isRead ? Colors.grey.withOpacity(0.1) : const Color(0xFF78c8c0).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF78c8c0).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.notifications_active_sharp, color: const Color(0xFF2B6D6A), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message,
                      style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(DateFormat('dd/MM/yyyy • HH:mm').format(date),
                      style: GoogleFonts.fredoka(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () async {
                await notif.reference.delete();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.close_rounded, size: 18, color: Colors.red.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(String teacherId, List<QueryDocumentSnapshot> msgs, String teacherName,
      String lastMsg, bool isRead) {
    bool showUnreadBadge = !isRead && msgs.last['senderId'] != userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFDFF7F6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(
          color: isRead ? Colors.grey.withOpacity(0.1) : const Color(0xFF78c8c0).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            for (var msg in msgs) {
              if (msg['isRead'] == false && msg['senderId'] != userId) {
                await msg.reference.update({'isRead': true});
              }
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SendMessagePage(otherUserId: teacherId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Enseignant : ",
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            TextSpan(
                              text: teacherName,
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: const Color(0xFF2B6D6A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(lastMsg,
                          style: GoogleFonts.fredoka(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w400),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (showUnreadBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Text(
                      "Nouveau",
                      style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

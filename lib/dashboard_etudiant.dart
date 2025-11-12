// DashboardEtudiant.dart
import 'package:attendo/HistoriquePage.dart';
import 'package:attendo/ModifierProfileEtudiant.dart';
import 'package:attendo/connexion_page.dart';
import 'package:attendo/notes_page.dart';
import 'package:attendo/SeancesEtudiantPage.dart';
import 'package:attendo/NotificationsPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:async/async.dart';

class DashboardEtudiant extends StatefulWidget {
  const DashboardEtudiant({super.key});

  @override
  State<DashboardEtudiant> createState() => _DashboardEtudiantState();
}

class _DashboardEtudiantState extends State<DashboardEtudiant> {
  String nomEtudiant = '';
  String role = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getEtudiantInfo();
  }

  Future<void> _getEtudiantInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            nomEtudiant = 'Utilisateur non connecté';
            _loading = false;
          });
        }
        return;
      }

      final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        final fetchedName = (data['name'] ?? data['nom'] ?? '') as String;
        final fetchedRole = (data['role'] ?? '') as String;

        if (mounted) {
          setState(() {
            nomEtudiant =
            fetchedName.isNotEmpty ? fetchedName : 'Nom introuvable';
            role = fetchedRole;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            nomEtudiant = 'Profil introuvable';
            _loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de l’étudiant : $e');
      if (mounted) {
        setState(() {
          nomEtudiant = 'Erreur de chargement';
          _loading = false;
        });
      }
    }
  }

  Stream<int> unreadMessagesStream() {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('messages')
        .where('etudiantId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      final count = snapshot.docs
          .where((doc) =>
      doc.data().containsKey('senderId') &&
          doc.data().containsKey('isRead') &&
          doc['senderId'] != currentUserId &&
          doc['isRead'] == false)
          .length;
      return count;
    });
  }

  Stream<int> unreadNotificationsStream() {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('etudiantId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      final count = snapshot.docs
          .where((doc) =>
          doc.data().containsKey('isRead') &&
          doc['isRead'] == false)
          .length;
      return count;
    });
  }

  // 🌟 Stream combiné pour somme totale des messages et notifications non lus
  Stream<int> totalUnreadStream() {
    return StreamZip([unreadMessagesStream(), unreadNotificationsStream()])
        .map((list) => list[0] + list[1]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Logo
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.only(top: 30, bottom: 1),
            child: Center(
              child: Image.asset(
                'assets/images/ATTEND.png',
                width: 250,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Conteneur turquoise
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF8DD3CC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Titre Dashboard
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        'Dashboard Étudiant',
                        style: GoogleFonts.fredoka(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 2
                            ..color = const Color(0xFF1A2B4A),
                        ),
                      ),
                      Text(
                        'Dashboard Étudiant',
                        style: GoogleFonts.fredoka(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Nom étudiant
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person,
                          color: Color(0xFF152F5C),
                          size: 22,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          nomEtudiant,
                          style: GoogleFonts.fredoka(
                            color: const Color(0xFF152F5C),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 0),
                  // Grille cartes
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 2),
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 30,
                        crossAxisSpacing: 40,
                        childAspectRatio: 1.0,
                        children: [
                          DashboardCard(
                            imagePath: 'assets/images/student.jpg',
                            label: 'Profil',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                  const ModifierProfileEtudiant(),
                                ),
                              );
                            },
                          ),
                          DashboardCard(
                            imagePath: 'assets/images/courEtudiant.jpg',
                            label: 'Séances',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const SeancesEtudiantPage()),
                              );
                            },
                          ),
                          // Carte Notifications + Messages
                          DashboardCard(
                            label: 'Notifications',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const NotificationsPage()),
                              ).then((_) {
                                setState(() {}); // Rafraîchit le badge au retour
                              });
                            },
                            child: StreamBuilder<int>(
                              stream: totalUnreadStream(),
                              builder: (context, snapshot) {
                                final total = snapshot.data ?? 0;
                                return Stack(
                                  children: [
                                    Center(
                                      child: Image.asset(
                                        'assets/images/notification.jpg',
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    if (total > 0)
                                      Positioned(
                                        top: -5,
                                        right: 3,
                                        child: Container(
                                          padding: const EdgeInsets.all(9),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.4),
                                                blurRadius: 6,
                                                offset: const Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            '$total',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                          DashboardCard(
                            imagePath: 'assets/images/historique.jpg',
                            label: 'Historique',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HistoriquePage(),
                                ),
                              );
                            },
                          ),
                          DashboardCard(
                            imagePath: 'assets/images/gestion_etudiant.jpg',
                            label: 'Notes',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotesPage(),
                                ),
                              );
                            },
                          ),
                          DashboardCard(
                            imagePath: 'assets/images/logout.png',
                            label: 'Se déconnecter',
                            onTap: () async {
                              await FirebaseAuth.instance.signOut();
                              if (mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ConnexionPage(),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Carte Dashboard
class DashboardCard extends StatefulWidget {
  final String? imagePath;
  final String label;
  final VoidCallback onTap;
  final Widget? child;

  const DashboardCard({
    super.key,
    this.imagePath,
    required this.label,
    required this.onTap,
    this.child,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) => setState(() => _scale = 0.95);
  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onTap();
  }

  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.child ??
                  Image.asset(
                    widget.imagePath!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2B4A),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

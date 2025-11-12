import 'package:attendo/GestionSeancesPage.dart';
import 'package:attendo/StatistiquesPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'GestionCoursPage.dart';
import 'gestionetudiants.dart';
import 'AjoutCours.dart';
import 'ModifierProfileEnseignant.dart';
import 'connexion_page.dart';
import 'CreerSeancePage.dart';

class DashboardEnseignant extends StatefulWidget {
  final String enseignantId;
  const DashboardEnseignant({super.key, required this.enseignantId});

  @override
  State<DashboardEnseignant> createState() => _DashboardEnseignantState();
}

class _DashboardEnseignantState extends State<DashboardEnseignant> {
  String nomEnseignant = '';
  String role = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getEnseignantInfo();
  }

  Stream<int> unreadMessagesStream() {
    final enseignantId = widget.enseignantId;

    return FirebaseFirestore.instance
        .collection('messages')
        .where('enseignantId', isEqualTo: enseignantId)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['isRead'] == false && data['senderId'] != enseignantId) {
          count++;
        }
      }
      return count;
    });
  }

  Future<void> _getEnseignantInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            nomEnseignant = 'Utilisateur non connecté';
            role = '';
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
            nomEnseignant =
            fetchedName.isNotEmpty ? fetchedName : 'Nom introuvable';
            role = fetchedRole;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            nomEnseignant = 'Profil introuvable';
            role = '';
            _loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur récupération utilisateur: $e');
      if (mounted) {
        setState(() {
          nomEnseignant = 'Erreur de chargement';
          role = '';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
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
                  const SizedBox(height: 1),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'Dashboard Enseignant',
                          style: GoogleFonts.fredoka(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 2
                              ..color = Color(0xFF1A2B4A),
                          ),
                        ),
                        Text(
                          'Dashboard Enseignant',
                          style: GoogleFonts.fredoka(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
                        Container(
                          width: 30,
                          height: 25,
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF152F5C),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          nomEnseignant,
                          style: GoogleFonts.fredoka(
                            color: const Color(0xFF152F5C),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 0.2),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 30,
                        crossAxisSpacing: 40,
                        childAspectRatio: 1.0,
                        children: [
                          DashboardCard(
                            imagePath: 'assets/images/profil.jpg',
                            label: 'Profil',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const ModifierProfileEnseignant()),
                              );
                            },
                          ),
                          DashboardCard(
                            imagePath: 'assets/images/cour.jpg',
                            label: 'Gestion cours',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => GestionCoursPage()),
                              );
                            },
                          ),
                          // Gestion étudiants avec badge
                          DashboardCard(
                            label: 'Gestion étudiants',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const GestionEtudiants()),
                              );
                            },
                            child: StreamBuilder<int>(
                              stream: unreadMessagesStream(),
                              builder: (context, snapshot) {
                                final unreadCount = snapshot.data ?? 0;
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/gestion_etudiants.png',
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.contain,
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        top: -5,
                                        right: 3,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white.withOpacity(0.4),
                                                blurRadius: 6,
                                                offset: const Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            '$unreadCount',
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
                            imagePath: 'assets/images/classe.jpg',
                            label: 'Statistiques',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const StatistiquesPage()),
                              );
                            },
                          ),
                          DashboardCard(
                            imagePath: 'assets/images/online_L1.jpg',
                            label: 'Gestion séances',
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        GestionSeancesPage(
                                            enseignantId: widget.enseignantId)),
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
                                      builder: (context) => const ConnexionPage()),
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

// Carte Dashboard avec option child
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

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.95);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

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
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
              const SizedBox(height: 2),
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

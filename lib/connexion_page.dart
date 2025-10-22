import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_etudiant.dart';
import 'dashboard_enseignant.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  _ConnexionPageState createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  // ---------------------------------------------------------
  // 🔹 1️⃣ Contrôleurs des champs
  // ---------------------------------------------------------
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // ---------------------------------------------------------
  // 🔹 2️⃣ Fonction de connexion avec contrôle de saisie
  // ---------------------------------------------------------
  void login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // ✅ Vérification champs vides
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tous les champs doivent être remplis")),
      );
      return;
    }

    // ✅ Vérification format email
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email invalide")),
      );
      return;
    }

    try {
      // 🔹 Authentification Firebase
      //vérifie dans Firebase Authentication si l’email + mot de passe existent.
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // 🔹 Récupération du rôle depuis Firestore
      // récupère dans Cloud Firestore les informations associées à cet utilisateur
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Utilisateur introuvable.")),
        );
        return;
      }

      String role = userDoc['role'];

      // 🔹 Redirection selon le rôle
      if (role == 'etudiant') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardEtudiant()),
        );
      } else if (role == 'enseignant') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardEnseignant()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rôle non reconnu.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Erreur inconnue")),
      );
    }
  }

  // ---------------------------------------------------------
  // 🔹 3️⃣ Interface utilisateur
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6DD5C9),
      body: Column(
        children: [
          // 🔹 Haut de page : icône et titre
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: Color(0xFF6DD5C9)),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 30),
                child: Column(
                  children: [
                    const Icon(Icons.school, size: 80, color: Colors.black),
                    const SizedBox(height: 15),
                    Text(
                      'Bienvenue !',
                      style: GoogleFonts.fredoka(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🔹 Corps : formulaire de connexion
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Se connecter",
                        style: GoogleFonts.fredoka(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B263B),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // 🔹 Champ email
                      TextField(
                        controller: emailController,
                        style: GoogleFonts.fredoka(),
                        decoration: InputDecoration(
                          hintText: "Email",
                          hintStyle: GoogleFonts.fredoka(color: Colors.black54),
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: Colors.black54),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 🔹 Champ mot de passe
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        style: GoogleFonts.fredoka(),
                        decoration: InputDecoration(
                          hintText: "Mot de passe",
                          hintStyle: GoogleFonts.fredoka(color: Colors.black54),
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Colors.black54),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 🔹 Mot de passe oublié
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            "Mot de passe oublié?",
                            style: GoogleFonts.fredoka(
                              color: Colors.black54,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),

                      // 🔹 Bouton connexion
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9BE3E2), Color(0xFF00BFA6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.4),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            "Accéder",
                            style: GoogleFonts.fredoka(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 35),

                      // 🔹 Lien vers création de compte
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 70, height: 1.5, color: Colors.black54),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: GestureDetector(
                              onTap: () {

                                //Ouvre une nouvelle page
                                Navigator.pushNamed(context, '/creer_compte');
                              },
                              child: Text(
                                "Créer compte",
                                style: GoogleFonts.fredoka(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontSize: 25,
                                ),
                              ),
                            ),
                          ),
                          Container(width: 80, height: 1.5, color: Colors.black54),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreerComptePage extends StatefulWidget {
  const CreerComptePage({super.key});

  @override
  _CreerComptePageState createState() => _CreerComptePageState();
}

class _CreerComptePageState extends State<CreerComptePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void creerCompte() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim());

      // Optionnel : enregistrer nom et téléphone dans Firestore
      // await FirebaseFirestore.instance
      //     .collection('users')
      //
      //     .doc(userCredential.user!.uid)
      //     .set({
      //   'name': nameController.text.trim(),
      //   'phone': phoneController.text.trim(),
      //   'email': emailController.text.trim(),
      // });

      Navigator.pushReplacementNamed(context, '/connexion');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Erreur inconnue")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6DD5C9),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: Color(0xFF6DD5C9)),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 30),
                child: Column(
                  children: [
                    const Icon(Icons.person_add_alt_1,
                        size: 80, color: Colors.black),
                    const SizedBox(height: 15),
                    Text(
                      'Créer un compte',
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
                        "Créer votre compte",
                        style: GoogleFonts.fredoka(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B263B),
                        ),
                      ),
                      const SizedBox(height: 25),
                      TextField(
                        controller: nameController,
                        style: GoogleFonts.fredoka(),
                        decoration: InputDecoration(
                          hintText: "Nom complet",
                          hintStyle: GoogleFonts.fredoka(color: Colors.black54),
                          prefixIcon:
                          const Icon(Icons.person_outline, color: Colors.black54),
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
                      TextField(
                        controller: emailController,
                        style: GoogleFonts.fredoka(),
                        decoration: InputDecoration(
                          hintText: "Email",
                          hintStyle: GoogleFonts.fredoka(color: Colors.black54),
                          prefixIcon:
                          const Icon(Icons.email_outlined, color: Colors.black54),
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
                      TextField(
                        controller: phoneController,
                        style: GoogleFonts.fredoka(),
                        decoration: InputDecoration(
                          hintText: "Téléphone",
                          hintStyle: GoogleFonts.fredoka(color: Colors.black54),
                          prefixIcon:
                          const Icon(Icons.phone_outlined, color: Colors.black54),
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
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        style: GoogleFonts.fredoka(),
                        decoration: InputDecoration(
                          hintText: "Mot de passe",
                          hintStyle: GoogleFonts.fredoka(color: Colors.black54),
                          prefixIcon:
                          const Icon(Icons.lock_outline, color: Colors.black54),
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
                      const SizedBox(height: 25),
                      Container(
                        width: double.infinity,
                        height: 55,
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
                          onPressed: creerCompte,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            "Créer le compte",
                            style: GoogleFonts.fredoka(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 70, height: 1.5, color: Colors.black54),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                "Se connecter",
                                style: GoogleFonts.fredoka(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontSize: 25,
                                ),
                              ),
                            ),
                          ),
                          Container(width: 70, height: 1.5, color: Colors.black54),
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreerComptePage extends StatefulWidget {
  const CreerComptePage({super.key});

  @override
  _CreerComptePageState createState() => _CreerComptePageState();
}

class _CreerComptePageState extends State<CreerComptePage> {
  // ---------------------------------------------------------
  // 🔹 1️⃣ Contrôleurs des champs texte
  // ---------------------------------------------------------
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController codeController = TextEditingController(); // pour enseignants

  // ---------------------------------------------------------
  // 🔹 2️⃣ Variables pour les rôles, classes et groupes
  // ---------------------------------------------------------
  String? roleSelectionne;
  String? classeSelectionnee;
  String? groupeSelectionne;
  Map<String, List<String>> classesEtGroupes = {}; // récupérées depuis Firestore
  bool chargement = true; // état du chargement des classes

  // ---------------------------------------------------------
  // 🔹 3️⃣ Charger les classes et groupes depuis Firestore
  // ---------------------------------------------------------
  Future<void> chargerClasses() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('classes').get();

      final Map<String, List<String>> temp = {};
      for (var doc in snapshot.docs) {
        temp[doc.id] = List<String>.from(doc['groupes']);
      }

      setState(() {
        classesEtGroupes = temp;
        chargement = false;
      });
    } catch (e) {
      print("Erreur lors du chargement des classes : $e");
    }
  }

  @override
  void initState() {
    super.initState();
    chargerClasses(); // Charger les classes dès l'ouverture de la page
  }

  // ---------------------------------------------------------
  // 🔹 4️⃣ Fonction pour créer un compte avec contrôle de saisie
  // ---------------------------------------------------------
  void creerCompte() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String phone = phoneController.text.trim();
    String password = passwordController.text.trim();
    String code = codeController.text.trim();

    // ✅ Vérification des champs vides
    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tous les champs doivent être remplis")),
      );
      return;
    }

    // ✅ Vérification email
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email invalide")),
      );
      return;
    }

    // ✅ Vérification téléphone tunisien (8 chiffres)
    final phoneRegex = RegExp(r"^\d{8}$");
    if (!phoneRegex.hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Téléphone invalide : 8 chiffres requis")),
      );
      return;
    }

    // ✅ Vérification rôle
    if (roleSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez choisir un rôle")),
      );
      return;
    }

    // ✅ Si enseignant → vérifie le code
    if (roleSelectionne == "enseignant" && code != "CODEPROF123") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Code enseignant incorrect")),
      );
      return;
    }

    // ✅ Si étudiant → vérifie la sélection classe/groupe
    if (roleSelectionne == "etudiant" &&
        (classeSelectionnee == null || groupeSelectionne == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez choisir une classe et un groupe")),
      );
      return;
    }

    try {
      // 🔹 Création du compte Firebase Auth
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🔹 Enregistrement des informations dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': name,
        'phone': phone,
        'email': email,
        'role': roleSelectionne,
        if (roleSelectionne == "etudiant") ...{
          'classe': classeSelectionnee,
          'groupe': groupeSelectionne,
        }
      });

      // 🔹 Redirection vers la page de connexion
      Navigator.pushReplacementNamed(context, '/connexion');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Erreur inconnue")),
      );
    }
  }

  // ---------------------------------------------------------
  // 🔹 5️⃣ Interface utilisateur
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6DD5C9),
      body: Column(
        children: [
          // 🔹 Haut de la page : icône et titre
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

          // 🔹 Corps de la page : formulaire
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
                      // Titre du formulaire
                      Text(
                        "Créer votre compte",
                        style: GoogleFonts.fredoka(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B263B),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // 🔹 Champ nom complet
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 18),

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
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 🔹 Champ téléphone
                      TextField(
                        controller: phoneController,
                        style: GoogleFonts.fredoka(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Téléphone",
                          hintStyle: GoogleFonts.fredoka(color: Colors.black54),
                          prefixIcon: const Icon(Icons.phone_outlined,
                              color: Colors.black54),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
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
                          prefixIcon:
                          const Icon(Icons.lock_outline, color: Colors.black54),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 🔹 Dropdown pour choisir le rôle
                      DropdownButtonFormField<String>(
                        value: roleSelectionne,
                        items: const [
                          DropdownMenuItem(
                              value: "etudiant", child: Text("Étudiant")),
                          DropdownMenuItem(
                              value: "enseignant", child: Text("Enseignant")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            roleSelectionne = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Choisir un rôle",
                          prefixIcon: const Icon(Icons.school_outlined),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 🔹 Si enseignant → champ code
                      if (roleSelectionne == "enseignant")
                        TextField(
                          controller: codeController,
                          style: GoogleFonts.fredoka(),
                          decoration: InputDecoration(
                            hintText: "Code enseignant",
                            hintStyle: GoogleFonts.fredoka(color: Colors.black54),
                            prefixIcon: const Icon(Icons.lock_open,
                                color: Colors.black54),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),

                      // 🔹 Si étudiant → choix classe et groupe
                      if (!chargement && roleSelectionne == "etudiant") ...[
                        const SizedBox(height: 18),
                        DropdownButtonFormField<String>(
                          value: classeSelectionnee,
                          items: classesEtGroupes.keys
                              .map((classe) => DropdownMenuItem(
                            value: classe,
                            child: Text(classe),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              classeSelectionnee = value;
                              groupeSelectionne = null;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Choisir la classe",
                            prefixIcon: const Icon(Icons.class_),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (classeSelectionnee != null)
                          DropdownButtonFormField<String>(
                            value: groupeSelectionne,
                            items: classesEtGroupes[classeSelectionnee]!
                                .map((groupe) => DropdownMenuItem(
                              value: groupe,
                              child: Text(groupe),
                            ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                groupeSelectionne = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Choisir le groupe",
                              prefixIcon: const Icon(Icons.group),
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                      ],

                      const SizedBox(height: 25),

                      // 🔹 Bouton Créer le compte
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

                      // 🔹 Lien Se connecter
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

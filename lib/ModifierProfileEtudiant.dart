import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_etudiant.dart';

class ModifierProfileEtudiant extends StatefulWidget {
  const ModifierProfileEtudiant({super.key});

  @override
  State<ModifierProfileEtudiant> createState() => _ModifierProfilePageState();
}

class _ModifierProfilePageState extends State<ModifierProfileEtudiant> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Contrôleurs pour récupérer le texte saisi dans les TextFields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController oldPasswordController = TextEditingController();



  // Variable pour afficher un loader pendant les opérations Firebase
  bool isLoading = false;

  // Méthode appelée au lancement de la page
  @override
  void initState() {
    super.initState();
    _chargerDonneesUtilisateur(); // Charge les données de l'utilisateur depuis Firestore
  }

  // Méthode pour récupérer les informations de l'utilisateur connecté
  Future<void> _chargerDonneesUtilisateur() async {
    final user = _auth.currentUser; // Récupère l'utilisateur connecté
    if (user != null) {
      final snapshot = await _firestore.collection('users').doc(user.uid).get(); // Récupère le document Firestore
      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          // Remplit les champs avec les informations existantes
          nameController.text = data['name'] ?? '';
          emailController.text = user.email ?? '';
          phoneController.text = data['phone'] ?? '';
        });
      }
    }
  }

  // Méthode pour modifier le profil utilisateur
  Future<void> _modifierProfile() async {
    final user = _auth.currentUser; // Vérifie si un utilisateur est connecté
    if (user == null) return;

    // Vérification que tous les champs obligatoires sont remplis
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tous les champs doivent être remplis")),
      );
      return;
    }

    // Vérification que le mot de passe actuel est renseigné
    if (oldPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre mot de passe actuel')),
      );
      return;
    }

    setState(() => isLoading = true); // Active le spinner pendant la mise à jour

    try {
      // 🔒 Ré-authentification avec l'ancien mot de passe
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(credential);

      // Mise à jour de l'email si l'utilisateur a changé son email
      if (emailController.text.trim() != user.email) {
        await user.verifyBeforeUpdateEmail(emailController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('email modifié avec succée.')),
        );
      }

      // Mise à jour du mot de passe si un nouveau mot de passe a été renseigné
      if (passwordController.text.isNotEmpty) {
        await user.updatePassword(passwordController.text.trim());
      }

      // Mise à jour des données utilisateur dans Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
      });

      // Message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès')),
      );

      // Redirection vers le dashboard étudiant
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardEtudiant()),
      );
    } on FirebaseAuthException catch (e) {
      // Gestion des erreurs Firebase Auth
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.message}')),
      );
    } catch (e) {
      // Gestion des erreurs inattendues
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur inattendue : $e')),
      );
    } finally {
      setState(() => isLoading = false); // Désactive le spinner
    }
  }

  // Méthode build : construit l'interface utilisateur
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6DD5C9), // Couleur de fond de la page
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Affiche un loader si isLoading = true
          : Column(
        children: [
          // Partie supérieure avec icône et titre
          Container(
            width: double.infinity, // Le container prend toute la largeur de l'écran
            decoration: const BoxDecoration(color: Color(0xFF6DD5C9)),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 20),
                child: Column(
                  children: [
                    const Icon(Icons.person, size: 80, color: Colors.white), // Icône utilisateur
                    const SizedBox(height: 5),
                    Text(
                      'Modifier votre profil',
                      style: GoogleFonts.fredoka(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Partie formulaire
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
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 35),
                  child: Column(
                    children: [
                      // Champ Nom complet
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: "Nom complet",
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Champ Email
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: "Email",
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Champ Téléphone
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Téléphone",
                          prefixIcon: const Icon(Icons.phone_outlined),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Champ Mot de passe actuel
                      TextField(
                        controller: oldPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Mot de passe actuel *",
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Champ Nouveau mot de passe (optionnel)
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Nouveau mot de passe (optionnel)",
                          prefixIcon: const Icon(Icons.lock_open),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      // Bouton Enregistrer les modifications
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: OutlinedButton(
                          onPressed: _modifierProfile, // Appelle la méthode pour modifier le profil
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF6DD5C9), width: 4),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Enregistrer les modifications',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6DD5C9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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

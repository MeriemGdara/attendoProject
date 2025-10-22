import 'package:attendo/dashboard_enseignant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Déclaration du widget principal de la page
class ModifierProfileEnseignant extends StatefulWidget { //statefulwidget : indique une interface qui peut etre changer
  const ModifierProfileEnseignant({super.key});

  @override
  State<ModifierProfileEnseignant> createState() => _ModifierProfileEnseignantState();
}

// Classe d’état du widget (là où toute la logique et les données se trouvent)
class _ModifierProfileEnseignantState extends State<ModifierProfileEnseignant> {
  // Instances de Firebase
  final _auth = FirebaseAuth.instance; // Gère l’utilisateur connecté
  final _firestore = FirebaseFirestore.instance; // Accès à la base de données Firestore

  // Contrôleurs pour les champs de texte
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController oldPasswordController = TextEditingController();

  bool isLoading = false; // Indique si une opération est en cours (affiche le loader)

  @override
  void initState() {
    super.initState();
    _chargerDonneesUtilisateur(); // Au démarrage, on charge les infos de l’utilisateur
  }

  // Fonction pour charger les données de l’utilisateur connecté depuis Firestore
  Future<void> _chargerDonneesUtilisateur() async {
    final user = _auth.currentUser; // Récupère l’utilisateur actuel
    if (user != null) {
      // Va chercher le document de cet utilisateur dans la collection "users"
      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      if (snapshot.exists) {
        final data = snapshot.data()!;
        // Remplit les champs de texte avec les données récupérées
        setState(() {
          nameController.text = data['name'] ?? '';
          emailController.text = user.email ?? '';
          phoneController.text = data['phone'] ?? '';
        });
      }
    }
  }

  // Fonction pour modifier le profil de l’utilisateur
  Future<void> _modifierProfile() async {
    final user = _auth.currentUser; // Utilisateur connecté
    if (user == null) return;

    // Vérifie que tous les champs obligatoires sont remplis
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tous les champs doivent être remplis")),
      );
      return;
    }

    // Vérifie que l’ancien mot de passe est saisi pour réauthentifier l’utilisateur
    if (oldPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre mot de passe actuel')),
      );
      return;
    }

    setState(() => isLoading = true); // Affiche le loader pendant le traitement

    try {
      //Ré-authentification : nécessaire avant toute mise à jour sensible
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(credential);

      //  Mise à jour de l’email si l’utilisateur l’a modifié
      if (emailController.text.trim() != user.email) {
        await user.verifyBeforeUpdateEmail(emailController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('emailchangé avec succés.')),
        );
      }

      // Mise à jour du mot de passe si un nouveau est renseigné
      if (passwordController.text.isNotEmpty) {
        await user.updatePassword(passwordController.text.trim());
      }

      // Mise à jour des informations dans Firestore (nom + téléphone)
      await _firestore.collection('users').doc(user.uid).update({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
      });

      // Message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès')),
      );

      // ✅ Redirection vers le tableau de bord enseignant après mise à jour
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardEnseignant()),
      );
    } on FirebaseAuthException catch (e) {
      // Gestion des erreurs liées à FirebaseAuth
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.message}')),
      );
    } catch (e) {
      // Gestion d’une erreur inattendue
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur inattendue : $e')),
      );
    } finally {
      setState(() => isLoading = false); // Cache le loader
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6DD5C9), // Couleur de fond principale
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Loader si opération en cours
          : Column(
        children: [
          // En-tête de la page (haut)
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: Color(0xFF6DD5C9)),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 20),
                child: Column(
                  children: [
                    const Icon(Icons.person, size: 80, color: Colors.white),
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

          //Contenu principal (formulaire)
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
                      // Champ Nom
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

                      // Champ ancien mot de passe
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

                      // Champ nouveau mot de passe (optionnel)
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

                      // Bouton d’enregistrement
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: OutlinedButton(
                          onPressed: _modifierProfile, // Appel de la fonction principale
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

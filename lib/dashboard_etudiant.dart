import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardEtudiant extends StatelessWidget {
  const DashboardEtudiant({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          "Hello Étudiant 👩‍🎓",
          style: GoogleFonts.fredoka(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      ),
    );
  }
}

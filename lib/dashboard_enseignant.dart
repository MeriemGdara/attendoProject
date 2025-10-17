import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardEnseignant extends StatelessWidget {
  const DashboardEnseignant({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          "Hello Enseignant 👨‍🏫",
          style: GoogleFonts.fredoka(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
      ),
    );
  }
}

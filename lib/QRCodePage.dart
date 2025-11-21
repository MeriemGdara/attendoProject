import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class QRCodePage extends StatelessWidget {
  final String code;

  const QRCodePage({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF58B6B3),
        title: Text(
          "QR Code de la séance",
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w700,
            fontSize: 25,
            color: Colors.black,
          ),
        ),
      ),
      body: Stack(
        children: [
          // 🌆 Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/Attendo.png"), // 🔥 Mets ta photo ici
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🌫️ Slight overlay for readability
          Container(
            color: Colors.white.withOpacity(0.15),
          ),

          // 🌟 Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const SizedBox(height: 30),

                // 🟦 QR Card
                Container(
                  padding: const EdgeInsets.all(80),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: code,
                    size: 230,
                    backgroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  "Code : $code",
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A3C40),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

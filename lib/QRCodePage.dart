import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodePage extends StatelessWidget {
  final String code;

  const QRCodePage({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("QR Code de la séance"),
        backgroundColor: Color(0xFF58B6B3),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Scannez pour enregistrer votre présence",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 20),

            // 🔥 Le QR Code
            QrImageView(
              data: code,
              size: 250,
              backgroundColor: Colors.white,
            ),

            SizedBox(height: 20),
            Text(
              "Code : $code",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}

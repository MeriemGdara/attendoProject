import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatefulWidget {
  @override
  _ScannerPageState createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scanner le QR Code")),
      body: MobileScanner(
        onDetect: (capture) {
          if (scanned) return; // empêcher double scan
          scanned = true;

          final code = capture.barcodes.first.rawValue;

          Navigator.pop(context, code); // on retourne le code scanné
        },
      ),
    );
  }
}

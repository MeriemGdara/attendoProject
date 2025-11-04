import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SeanceDetailPage extends StatefulWidget {
  final String seanceId;
  final String nomCours;
  final String description;
  final Timestamp horaire;
  final int dureeMinutes;
  final String classe;
  final String groupe;

  const SeanceDetailPage({
    super.key,
    required this.seanceId,
    required this.nomCours,
    required this.description,
    required this.horaire,
    required this.dureeMinutes,
    required this.classe,
    required this.groupe,
  });

  @override
  State<SeanceDetailPage> createState() => _SeanceDetailPageState();
}

class _SeanceDetailPageState extends State<SeanceDetailPage> {
  late Duration remaining;
  Timer? _timer;
  bool _canMark = false;
  final TextEditingController codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    remaining = widget.horaire.toDate().difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        remaining = widget.horaire.toDate().difference(DateTime.now());
        _canMark = remaining.isNegative || remaining.inSeconds == 0;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    codeController.dispose();
    super.dispose();
  }

  String getCountdown() {
    if (remaining.isNegative) return "00:00:00";
    final h = remaining.inHours.toString().padLeft(2, '0');
    final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  Future<void> markPresent() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final presencesRef = FirebaseFirestore.instance.collection('presences');

    final existing = await presencesRef
        .where('userId', isEqualTo: userId)
        .where('seanceId', isEqualTo: widget.seanceId)
        .get();

    if (existing.docs.isEmpty) {
      await presencesRef.add({
        'userId': userId,
        'seanceId': widget.seanceId,
        'date': Timestamp.now(),
        'classe': widget.classe,
        'groupe': widget.groupe,
        'etat': 'Présent',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Présence enregistrée !')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous êtes déjà présent.')),
      );
    }
  }

  void _checkCode() {
    if (!_canMark) return;

    String inputCode = codeController.text.trim();
    if (inputCode == widget.seanceId) {
      markPresent();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code incorrect')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final horaireStr = DateFormat('HH:mm').format(widget.horaire.toDate());
    final finStr = DateFormat('HH:mm')
        .format(widget.horaire.toDate().add(Duration(minutes: widget.dureeMinutes)));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nomCours),
        backgroundColor: const Color(0xFF78c8c0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(widget.nomCours,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text("Description: ${widget.description}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Horaire: $horaireStr - $finStr | Durée: ${widget.dureeMinutes} min",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            Text(getCountdown(),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Entrez le code de la séance',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _canMark ? _checkCode : null,
              child: const Text("Marquer présence"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                backgroundColor: _canMark ? const Color(0xFF814B4B) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

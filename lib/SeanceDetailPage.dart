import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class SeanceDetailPage extends StatefulWidget {
  final String seanceId;
  final String nomCours;
  final String description;
  final Timestamp horaire;
  final int dureeMinutes;
  final String classe;
  final String groupe;
  final String codeSeance;

  const SeanceDetailPage({
    super.key,
    required this.seanceId,
    required this.nomCours,
    required this.description,
    required this.horaire,
    required this.dureeMinutes,
    required this.classe,
    required this.groupe,
    required this.codeSeance,
  });

  @override
  State<SeanceDetailPage> createState() => _SeanceDetailPageState();
}

class _SeanceDetailPageState extends State<SeanceDetailPage> {
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;
  bool _isSessionActive = false;
  bool _isPresent = false;
  DateTime? _attendanceTime;
  final TextEditingController codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkSessionStatus();

    // Vérifie l'état de la séance chaque seconde
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _checkSessionStatus();
      });
      _autoMarkAbsent();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    codeController.dispose();
    super.dispose();
  }

  void _checkSessionStatus() {
    final now = DateTime.now();
    final sessionStart = widget.horaire.toDate();
    final sessionEnd = sessionStart.add(Duration(minutes: widget.dureeMinutes));
    final wasActive = _isSessionActive;
    _isSessionActive = now.isAfter(sessionStart) && now.isBefore(sessionEnd);

    // Si la séance vient de devenir active → démarrer le suivi GPS
    if (_isSessionActive && !wasActive) {
      _startPositionTracking();
    }

    // Si la séance se termine → arrêter le suivi
    if (!_isSessionActive && wasActive) {
      _stopPositionTracking();
    }
  }

  void _autoMarkAbsent() {
    final now = DateTime.now();
    final sessionStart = widget.horaire.toDate();
    final maxDuration = sessionStart.add(const Duration(minutes: 15));
    if (_isSessionActive && !_isPresent && now.isAfter(maxDuration)) {
      markAbsent();
    }
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

      setState(() {
        _isPresent = true;
        _attendanceTime = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Présence enregistrée automatiquement !'),
            backgroundColor: Color(0xFF78c8c0),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> markAbsent() async {
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
        'etat': 'Absent',
      });
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activez le GPS pour continuer.')),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission de localisation refusée.')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permission de localisation refusée définitivement. Activez-la dans les paramètres.',
          ),
        ),
      );
      return false;
    }

    return true;
  }

  /// 🔁 Suivi automatique de la position de l'étudiant
  void _startPositionTracking() async {
    bool hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // mise à jour si déplacement de 1 mètre
      ),
    ).listen((Position position) async {
      if (_isPresent) return; // déjà présent → stop
      await _checkDistanceAndMark(position);
    });
  }

  void _stopPositionTracking() {
    _positionStream?.cancel();
  }

  /// Vérifie la distance en continu et marque la présence si proche
  Future<void> _checkDistanceAndMark(Position etudiantPos) async {
    final seanceDoc = await FirebaseFirestore.instance
        .collection('séances')
        .doc(widget.seanceId)
        .get();

    if (!seanceDoc.exists) return;
    final enseignantId = seanceDoc['enseignantId'] as String;

    final enseignantDoc = await FirebaseFirestore.instance
        .collection('positions_enseignants')
        .doc(enseignantId)
        .get();

    if (!enseignantDoc.exists) return;

    final enseignantData = enseignantDoc.data()!;
    final enseignantLat = enseignantData['latitude'] as double;
    final enseignantLon = enseignantData['longitude'] as double;

    double distance = Geolocator.distanceBetween(
      enseignantLat,
      enseignantLon,
      etudiantPos.latitude,
      etudiantPos.longitude,
    );

    print("📍 Distance étu/ens : ${distance.toStringAsFixed(2)} m");

    if (distance <= 5) {
      await markPresent();
      _stopPositionTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final horaireStr = DateFormat('HH:mm').format(widget.horaire.toDate());
    final finStr = DateFormat('HH:mm')
        .format(widget.horaire.toDate().add(Duration(minutes: widget.dureeMinutes)));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF78c8c0),
        centerTitle: true,
        title: Text(
          "Marquer la Présence",
          style: GoogleFonts.fredoka(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.nomCours,
                style: GoogleFonts.fredoka(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Horaire : $horaireStr - $finStr",
                style: GoogleFonts.fredoka(fontSize: 18),
              ),
              const SizedBox(height: 25),
              Text(
                _isPresent
                    ? "✅ Présence enregistrée !"
                    : _isSessionActive
                    ? "⏳ Vérification automatique en cours..."
                    : "🕒 En attente du début de la séance...",
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  color: _isPresent ? Colors.green : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 30),
              if (!_isPresent)
                const CircularProgressIndicator(
                  color: Color(0xFF78c8c0),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

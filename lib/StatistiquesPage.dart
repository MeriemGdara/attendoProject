import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class StatistiquesPage extends StatefulWidget {
  const StatistiquesPage({super.key});

  @override
  State<StatistiquesPage> createState() => _StatistiquesPageState();
}

class _StatistiquesPageState extends State<StatistiquesPage> {
  final Color primaryTeal = const Color(0xFF78c8c0);
  final Color darkText = const Color(0xFF1A2B4A);
  final Color lightBg = Colors.white;
  final Color presentColor = const Color(0xFF26C6DA);
  final Color absentColor = const Color(0xFFFF6B6B);

  String? selectedClass;
  bool loading = true;
  bool showStudents = false;
  String? selectedStudentId;
  String? currentTeacherId;

  List<String> classes = [];
  List<Map<String, dynamic>> students = [];
  Map<String, List<Map<String, dynamic>>> studentPresences = {};
  List<Map<String, dynamic>> allSeances = [];

  Map<String, dynamic> stats = {
    'totalSeances': 0,
    'presents': 0,
    'absents': 0,
    'etudiants': 0,
    'tauxPresence': 0.0,
  };

  @override
  void initState() {
    super.initState();
    getCurrentTeacher();
  }

  Future<void> getCurrentTeacher() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        currentTeacherId = user.uid;
        print("[v0] currentTeacherId = $currentTeacherId");
        await loadClasses();
      }
    } catch (e) {
      print("[v0] Erreur lors de la récupération de l'enseignant: $e");
    }
  }

  Future<void> loadClasses() async {
    setState(() => loading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('classes').get();
      classes = snapshot.docs.map((doc) => doc.id).toList();
      print("[v0] Classes chargées: $classes");
      if (classes.isNotEmpty) {
        selectedClass = classes.first;
        await loadAllData();
      }
    } catch (e) {
      print("[v0] Erreur lors du chargement des classes: $e");
    }
    setState(() => loading = false);
  }

  Future<List<String>> getStudentGroups() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('classe', isEqualTo: selectedClass)
          .get();

      Set<String> groups = {};
      for (var doc in snapshot.docs) {
        final groupe = doc['groupe'] as String?;
        if (groupe != null && groupe.isNotEmpty) {
          groups.add(groupe);
        }
      }
      print("[v0] Groupes trouvés pour $selectedClass: $groups");
      return groups.toList();
    } catch (e) {
      print("[v0] Erreur lors de la récupération des groupes: $e");
      return [];
    }
  }

  List<String> buildClasseGroupeKeys(List<String> groups) {
    List<String> keys = [];
    for (var groupe in groups) {
      keys.add('${selectedClass}_$groupe');
    }
    print("[v0] Clés classe_groupe: $keys");
    return keys;
  }

  Future<void> loadAllData() async {
    if (selectedClass == null || currentTeacherId == null) return;

    setState(() {
      loading = true;
      students = [];
      studentPresences = {};
      allSeances = [];
      stats = {
        'totalSeances': 0,
        'presents': 0,
        'absents': 0,
        'etudiants': 0,
        'tauxPresence': 0.0,
      };
    });

    try {
      final studentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('classe', isEqualTo: selectedClass)
          .get();

      students = studentSnapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['name'] ?? 'Étudiant'})
          .toList();

      print("[v0] Étudiants trouvés: ${students.length}");

      final userIds = students.map((e) => e['id']).toList();

      final groups = await getStudentGroups();
      final classeGroupeKeys = buildClasseGroupeKeys(groups);

      final seancesSnapshot = await FirebaseFirestore.instance
          .collection('séances')
          .where('enseignantId', isEqualTo: currentTeacherId)
          .get();

      allSeances = seancesSnapshot.docs
          .where((doc) {
        final classes = (doc['classes'] as List<dynamic>? ?? []);
        return classeGroupeKeys.any((key) => classes.contains(key));
      })
          .map((doc) => {'id': doc.id, 'name': doc['nom'] ?? doc.id})
          .toList();

      print("[v0] Séances trouvées: ${allSeances.length}");

      if (userIds.isNotEmpty) {
        final presenceSnapshot = await FirebaseFirestore.instance
            .collection('presences')
            .where('userId', whereIn: userIds)
            .get();

        print("[v0] Présences trouvées: ${presenceSnapshot.docs.length}");

        for (var doc in presenceSnapshot.docs) {
          final data = doc.data();
          if (allSeances.any((s) => s['id'] == data['seanceId'])) {
            final userId = data['userId'] as String;
            if (!studentPresences.containsKey(userId)) {
              studentPresences[userId] = [];
            }
            studentPresences[userId]!.add(data);
          }
        }
      }

      stats = calculateStats();
      print("[v0] Stats calculées: $stats");
    } catch (e) {
      print("[v0] Erreur lors du chargement des données: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Map<String, dynamic> calculateStats() {
    int totalSeances = allSeances.length;
    int totalPresents = 0;

    studentPresences.forEach((userId, presences) {
      for (var presence in presences) {
        if (presence['etat'] == 'Présent') totalPresents++;
      }
    });

    int totalExpected = totalSeances * students.length;
    int totalAbsents = totalExpected - totalPresents;
    double tauxPresence = totalExpected == 0 ? 0 : (totalPresents / totalExpected) * 100;

    return {
      'totalSeances': totalSeances,
      'presents': totalPresents,
      'absents': totalAbsents,
      'etudiants': students.length,
      'tauxPresence': tauxPresence,
    };
  }

  List<Map<String, dynamic>> getStudentDetails(String studentId) {
    List<Map<String, dynamic>> details = [];

    final presences = studentPresences[studentId] ?? [];
    for (var seance in allSeances) {
      final presence = presences.firstWhere(
            (p) => p['seanceId'] == seance['id'],
        orElse: () => {},
      );

      details.add({
        'seanceId': seance['name'],
        'etat': presence['etat'] ?? 'Absent',
      });
    }

    return details;
  }

  Map<String, dynamic> getStudentStats(String studentId) {
    final presences = studentPresences[studentId] ?? [];
    int presents = presences.where((p) => p['etat'] == 'Présent').length;
    int total = allSeances.length;
    double percentage = total > 0 ? (presents / total) * 100 : 0;

    return {
      'presents': presents,
      'total': total,
      'percentage': percentage,
    };
  }

  List<PieChartSectionData> getPieChartData() {
    int presents = stats['presents'] as int? ?? 0;
    int absents = stats['absents'] as int? ?? 0;
    int total = presents + absents;

    if (total == 0) {
      return [
        PieChartSectionData(
          color: const Color(0xFFD9D9D9),
          value: 1,
          title: 'Aucune\ndonnée',
          radius: 50,
          titleStyle: GoogleFonts.fredoka(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    }

    double percent(int value) => (value / total * 100);

    return [
      PieChartSectionData(
        color: presentColor,
        value: presents.toDouble(),
        // Affiche nombre + pourcentage
        title: '$presents\n(${percent(presents).toStringAsFixed(1)}%)',
        radius: 50,
        titleStyle: GoogleFonts.fredoka(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: absentColor,
        value: absents.toDouble(),
        title: '$absents\n(${percent(absents).toStringAsFixed(1)}%)',
        radius: 50,
        titleStyle: GoogleFonts.fredoka(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }


  int getPresencesCount(String seanceId) {
    int count = 0;
    studentPresences.forEach((userId, presences) {
      if (presences.any((p) => p['seanceId'] == seanceId && p['etat'] == 'Présent')) {
        count++;
      }
    });
    return count;
  }

  List<Map<String, dynamic>> getUniqueSeances() {
    final seen = <String>{};
    final uniqueSeances = <Map<String, dynamic>>[];

    for (var seance in allSeances) {
      if (!seen.contains(seance['id'])) {
        seen.add(seance['id']);
        uniqueSeances.add(seance);
      }
    }

    return uniqueSeances;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: lightBg,
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF78c8c0))),
      );
    }

    return Scaffold(
      backgroundColor: lightBg,
      body: Column(
        children: [
          // Top white section with logo placeholder
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.only(top: 20, bottom: 10, left: 10, right: 10),
            child: Row(
              children: [
                // Flèche de retour
                IconButton(
                  onPressed: () {
                    Navigator.pop(context); // revient à la page précédente
                  },
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2B4A)),
                  iconSize: 28,
                ),
                const Spacer(), // espace avant le titre
                Text(
                  'Statistiques',
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A2B4A),
                  ),
                ),
                const Spacer(flex: 2), // espace après le titre pour centrer
              ],
            ),
          ),

          // Main teal content area
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF78c8c0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: DropdownButton<String>(
                          value: selectedClass,
                          onChanged: (value) async {
                            if (value != null) {
                              setState(() {
                                selectedClass = value;
                                showStudents = false;
                                selectedStudentId = null;
                              });
                              await loadAllData();
                            }
                          },
                          items: classes.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 15),
                                child: Text(
                                  'Classe: $c',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: darkText,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 15),
                            child: Icon(Icons.arrow_drop_down, color: Color(0xFF78c8c0)),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          StatCard(
                            title: 'Séances',
                            value: stats['totalSeances'].toString(),
                            icon: Icons.calendar_today,
                          ),
                          StatCard(
                            title: 'Présence',
                            value: '${(stats['tauxPresence'] as num).toDouble().toStringAsFixed(1)}%',
                            icon: Icons.check_circle,
                          ),
                          StatCard(
                            title: 'Étudiants',
                            value: stats['etudiants'].toString(),
                            icon: Icons.people,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Pie Chart
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Répartition des présences et absences de la classe $selectedClass',
                               textAlign: TextAlign.center,
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                  color:const Color(0xFF1A2B4A)
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sections: getPieChartData(),
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Container(width: 12, height: 12, color: presentColor),
                                    const SizedBox(width: 5),
                                    Text('Présent', style: GoogleFonts.fredoka(fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Row(
                                  children: [
                                    Container(width: 12, height: 12, color: absentColor),
                                    const SizedBox(width: 5),
                                    Text('Absent', style: GoogleFonts.fredoka(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Bar Chart for sessions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Progression des Présences par séance',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:const Color(0xFF1A2B4A)
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              height: 220,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: students.isNotEmpty ? students.length.toDouble() : 10,
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          int index = value.toInt();
                                          final uniqueSeances = getUniqueSeances();
                                          if (index >= 0 && index < uniqueSeances.length) {
                                            return Text(
                                              'S${index + 1}',
                                              style: GoogleFonts.fredoka(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey,
                                              ),
                                            );
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            '${value.toInt()}',
                                            style: GoogleFonts.fredoka(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey.withOpacity(0.1),
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  barGroups: getUniqueSeances()
                                      .asMap()
                                      .entries
                                      .map((entry) => BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: getPresencesCount(entry.value['id']).toDouble(),
                                        color: primaryTeal,
                                        width: 14,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                      )
                                    ],
                                  ))
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            showStudents = !showStudents;
                            if (!showStudents) {
                              selectedStudentId = null;
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkText,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              showStudents ? 'Masquer les étudiants' : 'Voir les étudiants',
                              style: GoogleFonts.fredoka(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Students list
                    if (showStudents && selectedStudentId == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'Étudiants - ${selectedClass}',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: students.length,
                                itemBuilder: (context, index) {
                                  final student = students[index];
                                  final studentStats = getStudentStats(student['id']);
                                  final taux = (studentStats['percentage'] as num).toDouble();

                                  final couleur = taux >= 85
                                      ? presentColor
                                      : taux >= 70
                                      ? const Color(0xFFFFC107)
                                      : absentColor;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            student['name'],
                                            style: GoogleFonts.fredoka(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: darkText,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: couleur.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${studentStats['presents']}/${studentStats['total']}',
                                            style: GoogleFonts.fredoka(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: couleur,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              selectedStudentId = student['id'];
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryTeal,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.info_outline,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        ),
                      ),

                    // Student details view
                    if (selectedStudentId != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      selectedStudentId = null;
                                    });
                                  },
                                  icon: const Icon(Icons.arrow_back),
                                  label: Text(
                                    'Retour',
                                    style: GoogleFonts.fredoka(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: darkText,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    students.firstWhere(
                                          (s) => s['id'] == selectedStudentId,
                                      orElse: () => {'name': 'Étudiant'},
                                    )['name'],
                                    style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: darkText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Text(
                                      'Historique des présences',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: darkText,
                                      ),
                                    ),
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: getStudentDetails(selectedStudentId!).length,
                                    itemBuilder: (context, index) {
                                      final detail = getStudentDetails(selectedStudentId!)[index];
                                      final isPresent = detail['etat'] == 'Présent';

                                      final bgColor = isPresent
                                          ? presentColor.withOpacity(0.1)
                                          : absentColor.withOpacity(0.1);
                                      final textColor = isPresent ? presentColor : absentColor;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: bgColor,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                detail['seanceId'],
                                                style: GoogleFonts.fredoka(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: darkText,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: textColor.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(15),
                                                ),
                                                child: Text(
                                                  detail['etat'],
                                                  style: GoogleFonts.fredoka(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: textColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 15),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6), // <-- espace entre les cartes
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF78c8c0), size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A2B4A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.fredoka(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF78c8c0),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class StatistiquesPage extends StatefulWidget {
  const StatistiquesPage({super.key});

  @override
  State<StatistiquesPage> createState() => _StatistiquesPageState();
}

class _StatistiquesPageState extends State<StatistiquesPage> {
  String selectedClass = 'GL3';
  String? selectedStudent;
  bool showEtudiants = false;

  final classes = ['GL3', 'GL4', 'GL2'];

  final classStats = {
    'GL3': {
      'totalSeances': 12,
      'tauxPresence': 85.5,
      'etudiants': 30,
      'presents': 25,
      'absents': 5,
    },
    'GL4': {
      'totalSeances': 10,
      'tauxPresence': 90.0,
      'etudiants': 30,
      'presents': 27,
      'absents': 3,
    },
    'GL2': {
      'totalSeances': 15,
      'tauxPresence': 78.5,
      'etudiants': 28,
      'presents': 22,
      'absents': 6,
    },
  };

  final etudiantsData = {
    'GL3': [
      {'name': 'Ali Ben Salah', 'presence': 11, 'total': 12, 'taux': 91.7},
      {'name': 'Fatima Karim', 'presence': 10, 'total': 12, 'taux': 83.3},
    ],
    'GL4': [
      {'name': 'Mohammed Ahmed', 'presence': 12, 'total': 12, 'taux': 100},
      {'name': 'Leila Samir', 'presence': 8, 'total': 12, 'taux': 66.7},
    ],
    'GL2': [
      {'name': 'Hamza Khalil', 'presence': 11, 'total': 12, 'taux': 91.7},
      {'name': 'Noor Ismail', 'presence': 9, 'total': 12, 'taux': 75.0},
    ],
  };

  final studentAttendanceDetails = {
    'GL3': {
      'Ali Ben Salah': [
        {'seance': 'S1', 'status': 'Présent'},
        {'seance': 'S2', 'status': 'Présent'},
        {'seance': 'S3', 'status': 'Absent'},
        {'seance': 'S4', 'status': 'Présent'},
        {'seance': 'S5', 'status': 'Présent'},
        {'seance': 'S6', 'status': 'Présent'},
        {'seance': 'S7', 'status': 'Présent'},
        {'seance': 'S8', 'status': 'Présent'},
        {'seance': 'S9', 'status': 'Présent'},
        {'seance': 'S10', 'status': 'Présent'},
        {'seance': 'S11', 'status': 'Présent'},
        {'seance': 'S12', 'status': 'Absent'},
      ],
      'Fatima Karim': [
        {'seance': 'S1', 'status': 'Présent'},
        {'seance': 'S2', 'status': 'Absent'},
        {'seance': 'S3', 'status': 'Présent'},
        {'seance': 'S4', 'status': 'Présent'},
        {'seance': 'S5', 'status': 'Présent'},
        {'seance': 'S6', 'status': 'Présent'},
        {'seance': 'S7', 'status': 'Absent'},
        {'seance': 'S8', 'status': 'Présent'},
        {'seance': 'S9', 'status': 'Présent'},
        {'seance': 'S10', 'status': 'Présent'},
        {'seance': 'S11', 'status': 'Présent'},
        {'seance': 'S12', 'status': 'Présent'},
      ],
    },
    'GL4': {
      'Mohammed Ahmed': [
        {'seance': 'S1', 'status': 'Présent'},
        {'seance': 'S2', 'status': 'Présent'},
        {'seance': 'S3', 'status': 'Présent'},
        {'seance': 'S4', 'status': 'Présent'},
        {'seance': 'S5', 'status': 'Présent'},
        {'seance': 'S6', 'status': 'Présent'},
        {'seance': 'S7', 'status': 'Présent'},
        {'seance': 'S8', 'status': 'Présent'},
        {'seance': 'S9', 'status': 'Présent'},
        {'seance': 'S10', 'status': 'Présent'},
        {'seance': 'S11', 'status': 'Présent'},
        {'seance': 'S12', 'status': 'Présent'},
      ],
      'Leila Samir': [
        {'seance': 'S1', 'status': 'Absent'},
        {'seance': 'S2', 'status': 'Présent'},
        {'seance': 'S3', 'status': 'Absent'},
        {'seance': 'S4', 'status': 'Présent'},
        {'seance': 'S5', 'status': 'Absent'},
        {'seance': 'S6', 'status': 'Présent'},
        {'seance': 'S7', 'status': 'Présent'},
        {'seance': 'S8', 'status': 'Absent'},
        {'seance': 'S9', 'status': 'Présent'},
        {'seance': 'S10', 'status': 'Présent'},
        {'seance': 'S11', 'status': 'Absent'},
        {'seance': 'S12', 'status': 'Présent'},
      ],
    },
    'GL2': {
      'Hamza Khalil': [
        {'seance': 'S1', 'status': 'Présent'},
        {'seance': 'S2', 'status': 'Présent'},
        {'seance': 'S3', 'status': 'Présent'},
        {'seance': 'S4', 'status': 'Présent'},
        {'seance': 'S5', 'status': 'Présent'},
        {'seance': 'S6', 'status': 'Présent'},
        {'seance': 'S7', 'status': 'Absent'},
        {'seance': 'S8', 'status': 'Présent'},
        {'seance': 'S9', 'status': 'Présent'},
        {'seance': 'S10', 'status': 'Présent'},
        {'seance': 'S11', 'status': 'Présent'},
        {'seance': 'S12', 'status': 'Présent'},
      ],
      'Noor Ismail': [
        {'seance': 'S1', 'status': 'Présent'},
        {'seance': 'S2', 'status': 'Absent'},
        {'seance': 'S3', 'status': 'Présent'},
        {'seance': 'S4', 'status': 'Absent'},
        {'seance': 'S5', 'status': 'Présent'},
        {'seance': 'S6', 'status': 'Absent'},
        {'seance': 'S7', 'status': 'Présent'},
        {'seance': 'S8', 'status': 'Présent'},
        {'seance': 'S9', 'status': 'Absent'},
        {'seance': 'S10', 'status': 'Présent'},
        {'seance': 'S11', 'status': 'Présent'},
        {'seance': 'S12', 'status': 'Présent'},
      ],
    },
  };

  final progressionPresence = {
    'GL3': [
      {'seance': 'S1', 'presence': 28},
      {'seance': 'S2', 'presence': 26},
      {'seance': 'S3', 'presence': 29},
    ],
    'GL4': [
      {'seance': 'S1', 'presence': 27},
      {'seance': 'S2', 'presence': 28},
      {'seance': 'S3', 'presence': 26},
    ],
    'GL2': [
      {'seance': 'S1', 'presence': 22},
      {'seance': 'S2', 'presence': 24},
      {'seance': 'S3', 'presence': 23},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final stats = classStats[selectedClass] as Map<String, dynamic>;
    final etudiants = etudiantsData[selectedClass] ?? [];
    final progression = progressionPresence[selectedClass] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.only(top: 30, bottom: 1),
            child: Center(
              child: Image.asset(
                'assets/images/ATTEND.png',
                width: 250,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
          ),
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
                    const SizedBox(height: 15),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'Statistiques',
                          style: GoogleFonts.fredoka(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 2
                              ..color = const Color(0xFF1c2942),
                          ),
                        ),
                        Text(
                          'Statistiques',
                          style: GoogleFonts.fredoka(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
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
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedClass = newValue;
                                showEtudiants = false;
                                selectedStudent = null;
                              });
                            }
                          },
                          items: classes.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 15),
                                child: Text(
                                  'Classe: $value',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1c2942),
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
                              'Répartition Présences/Absences',
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1c2942),
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      color: const Color(0xFF4A90E2),
                                      value: (stats['presents'] as num).toDouble(),
                                      title: '${stats['presents']} présents',
                                      radius: 80,
                                      titleStyle: GoogleFonts.fredoka(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      color: const Color(0xFFE57373),
                                      value: (stats['absents'] as num).toDouble(),
                                      title: '${stats['absents']} absents',
                                      radius: 80,
                                      titleStyle: GoogleFonts.fredoka(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
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
                              'Progression des Présences',
                              style: GoogleFonts.fredoka(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1c2942),
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              height: 220,
                              child: LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          if (value >= 0 && value < progression.length) {
                                            return Text(
                                              progression[value.toInt()]['seance'] as String,
                                              style: GoogleFonts.fredoka(
                                                fontSize: 10,
                                                color: const Color(0xFF1c2942),
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
                                              color: const Color(0xFF1c2942),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: List.generate(
                                        progression.length,
                                            (index) => FlSpot(
                                          index.toDouble(),
                                          (progression[index]['presence'] as num).toDouble(),
                                        ),
                                      ),
                                      isCurved: true,
                                      color: const Color(0xFFFF9800),
                                      barWidth: 3,
                                      dotData: const FlDotData(show: true),
                                    ),
                                  ],
                                  minY: 0,
                                  maxY: stats['etudiants'].toDouble(),
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
                            showEtudiants = !showEtudiants;
                            if (!showEtudiants) {
                              selectedStudent = null;
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1c2942),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          showEtudiants ? 'Masquer les étudiants' : 'Voir les étudiants',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    if (showEtudiants && selectedStudent == null)
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
                                    color: const Color(0xFF1c2942),
                                  ),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: etudiants.length,
                                itemBuilder: (context, index) {
                                  final etudiant = etudiants[index];
                                  final taux = (etudiant['taux'] as num).toDouble();
                                  final couleur = taux >= 85
                                      ? const Color(0xFF4A90E2)
                                      : taux >= 70
                                      ? const Color(0xFFFF9800)
                                      : const Color(0xFFE57373);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            etudiant['name'] as String,
                                            style: GoogleFonts.fredoka(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1c2942),
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
                                            '${taux.toStringAsFixed(1)}%',
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
                                              selectedStudent = etudiant['name'] as String;
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF78c8c0),
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

                    if (showEtudiants && selectedStudent != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        selectedStudent = null;
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
                                      backgroundColor: const Color(0xFF1c2942),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Text(
                                      selectedStudent ?? '',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1c2942),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                                      'Détails de Présence/Absence',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1c2942),
                                      ),
                                    ),
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: (studentAttendanceDetails[selectedClass]?[selectedStudent] as List?)?.length ?? 0,
                                    itemBuilder: (context, index) {
                                      final record = (studentAttendanceDetails[selectedClass]?[selectedStudent] as List?)?[index] as Map?;
                                      if (record == null) return const SizedBox();

                                      final isPresent = record['status'] == 'Présent';
                                      final bgColor = isPresent
                                          ? const Color(0xFF4A90E2).withOpacity(0.1)
                                          : const Color(0xFFE57373).withOpacity(0.1);
                                      final textColor = isPresent
                                          ? const Color(0xFF4A90E2)
                                          : const Color(0xFFE57373);

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
                                                record['seance'] as String,
                                                style: GoogleFonts.fredoka(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF1c2942),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: textColor.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(15),
                                                ),
                                                child: Text(
                                                  record['status'] as String,
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
    return Container(
      width: 100,
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
              color: const Color(0xFF1c2942),
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
    );
  }
}

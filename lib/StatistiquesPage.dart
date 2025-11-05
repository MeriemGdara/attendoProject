import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatistiquesPage extends StatefulWidget {
  const StatistiquesPage({super.key});

  @override
  State<StatistiquesPage> createState() => _StatistiquesPageState();
}

class _StatistiquesPageState extends State<StatistiquesPage> {
  String? selectedClass;
  String? selectedStudent;
  bool showEtudiants = false;
  bool loading = true;

  List<String> classes = [];
  List<Map<String, dynamic>> students = [];
  Map<String, dynamic>? stats;
  Map<String, List<Map<String, String>>> studentAttendanceDetails = {};
  List<Map<String, dynamic>> progressionPresence = [];

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  Future<void> loadClasses() async {
    setState(() => loading = true);
    final snapshot = await FirebaseFirestore.instance.collection('classes').get();
    classes = snapshot.docs.map((doc) => doc.id).toList();
    if (classes.isNotEmpty) {
      selectedClass = classes.first;
      await loadData();
    }
    setState(() => loading = false);
  }

  Future<void> loadData() async {
    if (selectedClass == null) return;

    setState(() => loading = true);

    // Étudiants
    final studentSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('classe', isEqualTo: selectedClass)
        .get();
    students = studentSnapshot.docs.map((doc) => {'id': doc.id, 'name': doc['name']}).toList();

    // Présences
    final userIds = students.map((e) => e['id']).toList();
    List<Map<String, dynamic>> presences = [];
    if (userIds.isNotEmpty) {
      final presenceSnapshot = await FirebaseFirestore.instance
          .collection('presences')
          .where('userId', whereIn: userIds)
          .get();
      presences = presenceSnapshot.docs.map((doc) => doc.data()).toList();
    }

    // Statistiques globales
    stats = calculateStats(presences, students.length);

    // Détails par étudiant
    studentAttendanceDetails = buildStudentDetails(students, presences);

    // Progression des présences par séance
    progressionPresence = buildProgression(presences, stats!['totalSeances'] ?? 0);

    setState(() => loading = false);
  }

  Map<String, dynamic> calculateStats(List<Map<String, dynamic>> presences, int totalStudents) {
    final seanceIds = presences.map((e) => e['seanceId']).toSet();
    int totalSeances = seanceIds.length;
    int presents = presences.where((e) => e['etat'] == 'Présent').length;
    int absents = presences.where((e) => e['etat'] == 'Absent').length;
    double tauxPresence = totalSeances * totalStudents == 0
        ? 0
        : (presents / (totalSeances * totalStudents)) * 100;

    return {
      'totalSeances': totalSeances,
      'presents': presents,
      'absents': absents,
      'etudiants': totalStudents,
      'tauxPresence': tauxPresence,
    };
  }

  Map<String, List<Map<String, String>>> buildStudentDetails(
      List<Map<String, dynamic>> students, List<Map<String, dynamic>> presences) {
    Map<String, List<Map<String, String>>> studentDetails = {};
    for (var student in students) {
      final userId = student['id'];
      final userPresences = presences
          .where((p) => p['userId'] == userId)
          .map((p) => {
        'seance': p['seanceId'].toString(),
        'status': p['etat'].toString(),
      })
          .toList();
      studentAttendanceDetails[student['name']] = userPresences;

      studentDetails[student['name']] = userPresences;
    }
    return studentDetails;
  }

  List<Map<String, dynamic>> buildProgression(List<Map<String, dynamic>> presences, int totalSeances) {
    final seanceSet = presences.map((e) => e['seanceId']).toSet().toList();
    seanceSet.sort(); // Tri des séances par nom/id
    List<Map<String, dynamic>> progression = [];

    for (var seanceId in seanceSet) {
      final count = presences
          .where((p) => p['seanceId'] == seanceId && p['etat'] == 'Présent')
          .length;
      progression.add({'seance': seanceId, 'presence': count});
    }
    return progression;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final etudiants = students.map((s) {
      final details = studentAttendanceDetails[s['name']] ?? [];
      int presents = details.where((e) => e['status'] == 'Présent').length;
      int total = details.length;
      double taux = total == 0 ? 0 : (presents / total) * 100;
      return {'name': s['name'], 'presence': presents, 'total': total, 'taux': taux};
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.only(top: 40, bottom: 10, left: 10, right: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1c2942), size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Image.asset(
                  'assets/images/ATTEND.png',
                  width: 200,
                  height: 90,
                  fit: BoxFit.contain,
                ),
                const Spacer(),
              ],
            ),
          ),

          // Body
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

                    // Dropdown Classes
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
                          onChanged: (String? newValue) async {
                            if (newValue != null) {
                              setState(() {
                                selectedClass = newValue;
                                showEtudiants = false;
                                selectedStudent = null;
                              });
                              await loadData();
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

                    // Stat Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          StatCard(
                            title: 'Séances',
                            value: stats!['totalSeances'].toString(),
                            icon: Icons.calendar_today,
                          ),
                          StatCard(
                            title: 'Présence',
                            value: '${(stats!['tauxPresence'] as num).toDouble().toStringAsFixed(1)}%',
                            icon: Icons.check_circle,
                          ),
                          StatCard(
                            title: 'Étudiants',
                            value: stats!['etudiants'].toString(),
                            icon: Icons.people,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // PieChart Présence/Absence
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
                                      value: (stats!['presents'] as num).toDouble(),
                                      title: '${stats!['presents']} présents',
                                      radius: 80,
                                      titleStyle: GoogleFonts.fredoka(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      color: const Color(0xFFE57373),
                                      value: (stats!['absents'] as num).toDouble(),
                                      title: '${stats!['absents']} absents',
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

                    // LineChart Progression
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
                                          if (value >= 0 && value < progressionPresence.length) {
                                            return Text(
                                              progressionPresence[value.toInt()]['seance'] as String,
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
                                        progressionPresence.length,
                                            (index) => FlSpot(
                                          index.toDouble(),
                                          (progressionPresence[index]['presence'] as num).toDouble(),
                                        ),
                                      ),
                                      isCurved: true,
                                      color: const Color(0xFFFF9800),
                                      barWidth: 3,
                                      dotData: const FlDotData(show: true),
                                    ),
                                  ],
                                  minY: 0,
                                  maxY: stats!['etudiants'].toDouble(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Bouton Voir/Masquer étudiants
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            showEtudiants = !showEtudiants;
                            if (!showEtudiants) selectedStudent = null;
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

                    // Liste étudiants
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
                                  'Étudiants - $selectedClass',
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
                                  final etu = etudiants[index];
                                  return ListTile(
                                    title: Text(
                                      etu['name'],
                                      style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                        'Présences: ${etu['presence']}/${etu['total']} (${etu['taux'].toStringAsFixed(1)}%)'),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                                    onTap: () {
                                      setState(() {
                                        selectedStudent = etu['name'];
                                      });
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Détails étudiant
                    if (selectedStudent != null)
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
                                  'Détails de $selectedStudent',
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
                                itemCount:
                                studentAttendanceDetails[selectedStudent!]!.length,
                                itemBuilder: (context, index) {
                                  final detail =
                                  studentAttendanceDetails[selectedStudent!]![index];
                                  return ListTile(
                                    title: Text('Séance: ${detail['seance']}'),
                                    subtitle: Text('Statut: ${detail['status']}'),
                                  );
                                },
                              ),
                              const SizedBox(height: 15),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedStudent = null;
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
                                  'Retour à la liste',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
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

// Carte statistique
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({super.key, required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF78c8c0), size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1c2942),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1c2942),
            ),
          ),
        ],
      ),
    );
  }
}

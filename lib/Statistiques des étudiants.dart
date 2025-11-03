import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class SuivreStatistiquesPage extends StatefulWidget {
  const SuivreStatistiquesPage({super.key});

  @override
  State<SuivreStatistiquesPage> createState() => _SuivreStatistiquesPageState();
}

class _SuivreStatistiquesPageState extends State<SuivreStatistiquesPage> {
  bool chargement = true;

  Map<String, int> etudiantsParClasse = {};
  Map<String, Map<String, int>> groupesParClasse = {};
  String classePlusPeuplee = "";
  String groupeMajoritaire = "";

  Future<void> chargerDonnees() async {
    try {
      final etudiantsSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'etudiant')
          .get();

      for (var e in etudiantsSnap.docs) {
        final data = e.data();
        final classe = data['classe'] ?? "Inconnue";
        final groupe = data['groupe'] ?? "Sans groupe";

        etudiantsParClasse[classe] = (etudiantsParClasse[classe] ?? 0) + 1;

        groupesParClasse.putIfAbsent(classe, () => {});
        groupesParClasse[classe]![groupe] =
            (groupesParClasse[classe]![groupe] ?? 0) + 1;
      }

      if (etudiantsParClasse.isNotEmpty) {
        classePlusPeuplee = etudiantsParClasse.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      Map<String, int> totalGroupes = {};
      for (var classeData in groupesParClasse.values) {
        classeData.forEach((g, v) {
          totalGroupes[g] = (totalGroupes[g] ?? 0) + v;
        });
      }
      if (totalGroupes.isNotEmpty) {
        groupeMajoritaire =
            totalGroupes.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }

      setState(() => chargement = false);
    } catch (e) {
      debugPrint("🔥 Erreur Firestore : $e");
      setState(() => chargement = false);
    }
  }

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF5fc2ba),
        title: Text(
          "Statistiques des étudiants",
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: chargement
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF5fc2ba)),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // === BAR CHART ===
            Text(
              "Répartition par classe",
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(height: 260, child: _buildBarChart()),

            const SizedBox(height: 40),

            // === PIE CHARTS ===
            Text(
              "Répartition par groupe ",
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // défilement horizontal
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: groupesParClasse.entries.map((entry) {
                  final classe = entry.key;
                  final groupes = entry.value;

                  return Container(
                    width: 250,
                    height: 250,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Classe : $classe",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: 130,
                          height: 130,
                          child: _buildPieChart(groupes),

                        ),

                      ],
                    ),
                  );
                }).toList(),
              ),

            ),

            const SizedBox(height:50),

            // === ANALYSES ===
            Text(
              "💡 Analyses automatiques",
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            _buildInsightCard(
                "Classe la plus peuplée", classePlusPeuplee, Icons.school),
            const SizedBox(height: 10),
            _buildInsightCard(
                "Groupe majoritaire", groupeMajoritaire, Icons.group),
          ],
        ),
      ),
    );
  }

  // === 📊 BAR CHART ===
  Widget _buildBarChart() {
    final barSpots = etudiantsParClasse.entries.toList();

    if (barSpots.isEmpty) {
      return const Center(child: Text("Aucune donnée disponible"));
    }

    return BarChart(
      BarChartData(
        barGroups: barSpots.asMap().entries.map((entry) {
          int i = entry.key;
          int value = entry.value.value;
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: value.toDouble(),
              width: 20,
              borderRadius: BorderRadius.circular(6),
              color: const Color(0xFF5fc2ba),
            ),
          ]);
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, _) {
                if (value.toInt() < barSpots.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      barSpots[value.toInt()].key,
                      style: GoogleFonts.fredoka(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  // === 🥧 PIE CHART ===
  Widget _buildPieChart(Map<String, int> groupes) {
    final pieSpots = groupes.entries.toList();
    if (pieSpots.isEmpty) {
      return const Center(child: Text("Aucune donnée disponible"));
    }

    final couleurs = [
      const Color(0xFF54aea6),
      const Color(0xFF67b3ee),
      const Color(0xFFf6b26b),
      const Color(0xFFd46a6a),
    ];

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 35,
        sections: pieSpots.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final total = pieSpots.map((e) => e.value).reduce((a, b) => a + b);
          final pourcentage = ((data.value / total) * 100).toStringAsFixed(1);

          return PieChartSectionData(
            color: couleurs[index % couleurs.length],
            value: data.value.toDouble(),
            title: "${data.key}\n$pourcentage%",
            radius: 50, // ✅ légèrement plus petit pour bien tenir dans la carte
            titleStyle: GoogleFonts.fredoka(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          );
        }).toList(),
      ),
    );
  }

  // === 💡 INSIGHT CARD ===
  Widget _buildInsightCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF5fc2ba), size: 30),
        title: Text(
          title,
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          value,
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

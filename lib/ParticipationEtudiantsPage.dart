import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ParticipationEtudiantsPage extends StatelessWidget {
  const ParticipationEtudiantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tauxGlobal = 0.85;

    final etudiants = [
      {'nom': 'Amira Bennani', 'classe': 'L2-IA', 'present': 32, 'total': 36, 'taux': 0.89},
      {'nom': 'Mohamed Aziz', 'classe': 'L2-IA', 'present': 34, 'total': 36, 'taux': 0.94},
      {'nom': 'Fatima Rayan', 'classe': 'L2-IA', 'present': 28, 'total': 36, 'taux': 0.78},
      {'nom': 'Karim Salah', 'classe': 'L2-IA', 'present': 30, 'total': 36, 'taux': 0.83},
      {'nom': 'Nora Mahmoud', 'classe': 'L2-Web', 'present': 35, 'total': 36, 'taux': 0.97},
      {'nom': 'Youssef Ali', 'classe': 'L2-Web', 'present': 29, 'total': 36, 'taux': 0.81},
      {'nom': 'Sara Karim', 'classe': 'L2-Web', 'present': 33, 'total': 36, 'taux': 0.92},
      {'nom': 'Hassan Khaled', 'classe': 'L2-Mobile', 'present': 26, 'total': 36, 'taux': 0.72},
    ];

    final classes = [
      {'nom': 'L2-IA', 'present': 124, 'total': 144, 'taux': 0.86},
      {'nom': 'L2-Web', 'present': 97, 'total': 108, 'taux': 0.90},
      {'nom': 'L2-Mobile', 'present': 26, 'total': 36, 'taux': 0.72},
    ];

    final cours = [
      {'nom': 'Intelligence Artificielle', 'taux': 0.88},
      {'nom': 'Développement Web', 'taux': 0.91},
      {'nom': 'Développement Mobile', 'taux': 0.79},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text(
          'Participation des étudiants',
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF5fc2ba),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GlobalProgressChart(tauxGlobal: tauxGlobal),
            const SizedBox(height: 32),

            _SectionHeader(title: 'Résumé Global'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Taux Global',
                    value: '${(tauxGlobal * 100).toStringAsFixed(0)}%',
                    color: const Color(0xFF5fc2ba),
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Étudiants',
                    value: '${etudiants.length}',
                    color: const Color(0xFF67b3ee),
                    icon: Icons.people,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Classes',
                    value: '${classes.length}',
                    color: const Color(0xFFf9c178),
                    icon: Icons.class_,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Cours',
                    value: '${cours.length}',
                    color: const Color(0xFFf58ea8),
                    icon: Icons.book,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            _SectionHeader(title: 'Participation par Classe'),
            const SizedBox(height: 16),
            _BarChartClasses(classes: classes),
            const SizedBox(height: 32),
            ...classes.map((classe) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProgressCard(
                label: classe['nom'] as String,
                value: '${((classe['taux'] as double) * 100).toStringAsFixed(1)}%',

                stats: '${classe['present']}/${classe['total']} présences',
                percentage: classe['taux'] as double,
                color: const Color(0xFF67b3ee),
              ),
            )),

            const SizedBox(height: 32),
            _SectionHeader(title: 'Participation par Cours'),
            const SizedBox(height: 16),
            _CourseChartWidget(cours: cours),
            const SizedBox(height: 32),
            ...cours.map((course) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProgressCard(
                label: course['nom'] as String,
                value: '${((course['taux'] as double) * 100).toStringAsFixed(1)}%',

                stats: 'Taux moyen',
                percentage: course['taux'] as double,
                color: const Color(0xFFf9c178),
              ),
            )),

            const SizedBox(height: 32),
            _SectionHeader(title: 'Détail par Étudiant'),
            const SizedBox(height: 16),
            ...etudiants.map((etudiant) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StudentCard(
                nom: etudiant['nom'] as String,
                classe: etudiant['classe'] as String,
                present: etudiant['present'] as int,
                total: etudiant['total'] as int,
                taux: etudiant['taux'] as double,
              ),
            )),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _GlobalProgressChart extends StatelessWidget {
  final double tauxGlobal;

  const _GlobalProgressChart({required this.tauxGlobal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Taux de Participation Global',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1c2942),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: CircularProgressPainter(
                    progress: tauxGlobal,
                    backgroundColor: const Color(0xFFe8f0f5),
                    foregroundColor: const Color(0xFF5fc2ba),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(tauxGlobal * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.fredoka(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5fc2ba),
                      ),
                    ),
                    Text(
                      'Présent',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartClasses extends StatelessWidget {
  final List<Map<String, dynamic>> classes;

  const _BarChartClasses({required this.classes});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF5fc2ba),
      const Color(0xFF67b3ee),
      const Color(0xFFf9c178),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(classes.length, (index) {
                final taux = classes[index]['taux'] as double;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 50,
                      height: taux * 150,
                      decoration: BoxDecoration(
                        color: colors[index],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(taux * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors[index],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      classes[index]['nom'] as String,
                      style: GoogleFonts.fredoka(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> cours;

  const _CourseChartWidget({required this.cours});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF5fc2ba),
      const Color(0xFF67b3ee),
      const Color(0xFFf9c178),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(cours.length, (index) {
          final course = cours[index];
          final taux = course['taux'] as double;
          return Padding(
            padding: EdgeInsets.only(bottom: index < cours.length - 1 ? 16 : 0),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[index],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    course['nom'] as String,
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1c2942),
                    ),
                  ),
                ),
                Text(
                  '${(taux * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors[index],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.fredoka(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1c2942),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String label;
  final String value;
  final String stats;
  final double percentage;
  final Color color;

  const _ProgressCard({
    required this.label,
    required this.value,
    required this.stats,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1c2942),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: const Color(0xFFe8f0f5),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stats,
            style: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final String nom;
  final String classe;
  final int present;
  final int total;
  final double taux;

  const _StudentCard({
    required this.nom,
    required this.classe,
    required this.present,
    required this.total,
    required this.taux,
  });

  Color _getColorByTaux(double taux) {
    if (taux >= 0.85) return const Color(0xFF5fc2ba);
    if (taux >= 0.70) return const Color(0xFFf9c178);
    return const Color(0xFFf58ea8);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorByTaux(taux);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                nom[0],
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1c2942),
                  ),
                ),
                Text(
                  classe,
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(taux * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '$present/$total',
                style: GoogleFonts.fredoka(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF667085),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color foregroundColor;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = backgroundColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      2 * 3.14159 * progress,
      false,
      Paint()
        ..color = foregroundColor
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

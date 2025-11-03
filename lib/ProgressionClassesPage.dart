import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressionClassesPage extends StatefulWidget {
  const ProgressionClassesPage({super.key});

  @override
  State<ProgressionClassesPage> createState() => _ProgressionClassesPageState();
}

class _ProgressionClassesPageState extends State<ProgressionClassesPage> {
  final chargement = false;

  final classes = [
    ClasseProgression(
      nom: 'L2-IA',
      tauxCompletion: 0.86,
      nombreEtudiants: 36,
      coursTermines: 24,
      coursTotal: 28,
      couleur: const Color(0xFF5fc2ba),
    ),
    ClasseProgression(
      nom: 'L2-Web',
      tauxCompletion: 0.90,
      nombreEtudiants: 32,
      coursTermines: 26,
      coursTotal: 28,
      couleur: const Color(0xFF67b3ee),
    ),
    ClasseProgression(
      nom: 'L2-Mobile',
      tauxCompletion: 0.72,
      nombreEtudiants: 28,
      coursTermines: 18,
      coursTotal: 28,
      couleur: const Color(0xFFf9c178),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final averageCompletion = classes.fold<double>(0, (sum, c) => sum + c.tauxCompletion) / classes.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text(
          "Progression des classes",
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suivi de progression',
                style: GoogleFonts.fredoka(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1c2942),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Progression globale de chaque classe',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF7a8fa3),
                ),
              ),
              const SizedBox(height: 32),

              _ClassDistributionChart(classes: classes),
              const SizedBox(height: 32),

              _OverviewCard(
                totalClasses: classes.length,
                averageCompletion: averageCompletion,
              ),
              const SizedBox(height: 32),

              Text(
                'Détails par classe',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1c2942),
                ),
              ),
              const SizedBox(height: 16),

              ...classes.map((classe) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ClasseProgressionCard(classe: classe),
                );
              }).toList(),

              const SizedBox(height: 32),
              _ComparisonChart(classes: classes),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassDistributionChart extends StatelessWidget {
  final List<ClasseProgression> classes;

  const _ClassDistributionChart({required this.classes});

  @override
  Widget build(BuildContext context) {
    final totalEtudiants = classes.fold<int>(0, (sum, c) => sum + c.nombreEtudiants);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Distribution des étudiants',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1c2942),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  child: CustomPaint(
                    size: const Size(160, 160),
                    painter: PieChartPainter(
                      classes: classes,
                      totalEtudiants: totalEtudiants,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(classes.length, (index) {
                      final classe = classes[index];
                      final percentage = (classe.nombreEtudiants / totalEtudiants * 100).toStringAsFixed(1);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: classe.couleur,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                classe.nom,
                                style: GoogleFonts.fredoka(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1c2942),
                                ),
                              ),
                            ),
                            Text(
                              '$percentage%',
                              style: GoogleFonts.fredoka(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: classe.couleur,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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

class _ComparisonChart extends StatelessWidget {
  final List<ClasseProgression> classes;

  const _ComparisonChart({required this.classes});

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparaison des progressions',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1c2942),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(classes.length, (index) {
                final classe = classes[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 60,
                      height: classe.tauxCompletion * 150,
                      decoration: BoxDecoration(
                        color: classe.couleur,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${(classe.tauxCompletion * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.fredoka(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: classe.couleur,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      classe.nom,
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
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

class ClasseProgression {
  final String nom;
  final double tauxCompletion;
  final int nombreEtudiants;
  final int coursTermines;
  final int coursTotal;
  final Color couleur;

  ClasseProgression({
    required this.nom,
    required this.tauxCompletion,
    required this.nombreEtudiants,
    required this.coursTermines,
    required this.coursTotal,
    required this.couleur,
  });
}

class _OverviewCard extends StatelessWidget {
  final int totalClasses;
  final double averageCompletion;

  const _OverviewCard({
    required this.totalClasses,
    required this.averageCompletion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF5fc2ba).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.class_rounded,
                  color: Color(0xFF5fc2ba),
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                totalClasses.toString(),
                style: GoogleFonts.fredoka(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1c2942),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Classes',
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7a8fa3),
                ),
              ),
            ],
          ),
          Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF67b3ee).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF67b3ee),
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${(averageCompletion * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.fredoka(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1c2942),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Moyenne',
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7a8fa3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClasseProgressionCard extends StatelessWidget {
  final ClasseProgression classe;

  const _ClasseProgressionCard({required this.classe});

  String _getStatutProgression(double taux) {
    if (taux >= 0.8) return 'Excellent';
    if (taux >= 0.6) return 'Bon';
    if (taux >= 0.4) return 'Moyen';
    return 'À améliorer';
  }

  Color _getCouleurStatut(double taux) {
    if (taux >= 0.8) return const Color(0xFF5fc2ba);
    if (taux >= 0.6) return const Color(0xFF67b3ee);
    if (taux >= 0.4) return const Color(0xFFf9c178);
    return const Color(0xFFf58ea8);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe8f0f5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: classe.couleur.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: classe.couleur,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classe.nom,
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1c2942),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${classe.nombreEtudiants} étudiants',
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7a8fa3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCouleurStatut(classe.tauxCompletion)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatutProgression(classe.tauxCompletion),
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getCouleurStatut(classe.tauxCompletion),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression',
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1c2942),
                ),
              ),
              Text(
                '${(classe.tauxCompletion * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: classe.couleur,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: classe.tauxCompletion,
              minHeight: 8,
              backgroundColor: const Color(0xFFe8f0f5),
              valueColor: AlwaysStoppedAnimation<Color>(classe.couleur),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                icon: Icons.book_rounded,
                label: 'Cours',
                value: '${classe.coursTermines}/${classe.coursTotal}',
                color: classe.couleur,
              ),
              _StatItem(
                icon: Icons.people_alt_rounded,
                label: 'Étudiants',
                value: classe.nombreEtudiants.toString(),
                color: classe.couleur,
              ),
              _StatItem(
                icon: Icons.check_circle_rounded,
                label: 'Complété',
                value: '${(classe.tauxCompletion * 100).toStringAsFixed(0)}%',
                color: classe.couleur,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1c2942),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF7a8fa3),
            ),
          ),
        ],
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<ClasseProgression> classes;
  final int totalEtudiants;

  PieChartPainter({
    required this.classes,
    required this.totalEtudiants,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    var startAngle = -3.14159 / 2;

    for (final classe in classes) {
      final sweepAngle = 2 * 3.14159 * (classe.nombreEtudiants / totalEtudiants);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        Paint()..color = classe.couleur,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(PieChartPainter oldDelegate) => false;
}

// lib/features/student/screens/student_quizzes_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/ep_card.dart';
import 'student_quiz_attempt_screen.dart';

class StudentQuizzesTab extends StatelessWidget {
  const StudentQuizzesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StudentProvider>();
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                'Quizzes',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        if (sp.loading)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: EpLoadingShimmer(height: 96),
                ),
                childCount: 4,
              ),
            ),
          )
        else if (sp.quizzes.isEmpty)
          const SliverFillRemaining(
            child: EpEmptyState(
              icon: Icons.quiz_outlined,
              title: 'No quizzes yet',
              subtitle: 'Your teachers will publish quizzes here',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final q = sp.quizzes[i];
                  return FadeInUp(
                    delay: Duration(milliseconds: i * 60),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _QuizCard(quiz: q),
                    ),
                  );
                },
                childCount: sp.quizzes.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _QuizCard extends StatelessWidget {
  final QuizModel quiz;
  const _QuizCard({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final completed = quiz.status == 'completed';
    return EpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: completed
                      ? AppColors.emerald.withValues(alpha: 0.12)
                      : AppColors.indigo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  completed ? Icons.check_circle_rounded : Icons.quiz_rounded,
                  color: completed ? AppColors.emerald : AppColors.indigo,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      quiz.subjectName,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (completed && quiz.bestScore != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${quiz.bestScore}%',
                    style: const TextStyle(
                      color: AppColors.emerald,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(Icons.help_outline_rounded,
                  '${quiz.questionCount} questions'),
              const SizedBox(width: 10),
              _InfoChip(Icons.timer_outlined, '${quiz.timeMinutes} min'),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final detail =
                  await context.read<StudentProvider>().fetchQuizDetail(quiz.id);
              if (detail != null && context.mounted) {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, a, b) =>
                        StudentQuizAttemptScreen(quiz: detail),
                    transitionsBuilder: (_, animation, __, child) =>
                        SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                          parent: animation,
                          curve: const Cubic(0.22, 1, 0.36, 1))),
                      child: child,
                    ),
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              }
            },
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: completed
                    ? const LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF10B981)])
                    : AppColors.indigoGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  completed ? 'Retake Quiz' : 'Start Quiz',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cardBgAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

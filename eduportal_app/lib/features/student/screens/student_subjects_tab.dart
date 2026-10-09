// lib/features/student/screens/student_subjects_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../shared/widgets/ep_card.dart';
import 'student_lessons_screen.dart';
import 'student_profile_tab.dart';

class StudentSubjectsTab extends StatelessWidget {
  const StudentSubjectsTab({super.key});

  static const List<Color> _subjectColors = [
    AppColors.indigo,
    AppColors.teal,
    AppColors.amber,
    AppColors.rose,
    AppColors.emerald,
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
  ];

  static const List<IconData> _subjectIcons = [
    Icons.functions_rounded,
    Icons.science_rounded,
    Icons.menu_book_rounded,
    Icons.history_edu_rounded,
    Icons.public_rounded,
    Icons.palette_rounded,
    Icons.computer_rounded,
    Icons.fitness_center_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StudentProvider>();
    final user = context.watch<AuthProvider>().user;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user?.fullName.split(' ').first ?? 'Student'} 👋',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Your Subjects',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      // Profile avatar
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StudentProfileTab(),
                            ),
                          );
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.amberGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.amber.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              (user?.fullName.isNotEmpty == true)
                                  ? user!.fullName[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Stats row
                  if (!sp.loading && sp.subjects.isNotEmpty)
                    Text(
                      '${sp.subjects.length} subjects assigned',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        if (sp.loading)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) => const EpLoadingShimmer(height: 140, borderRadius: 20),
                childCount: 4,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
            ),
          )
        else if (sp.subjects.isEmpty)
          const SliverFillRemaining(
            child: EpEmptyState(
              icon: Icons.book_outlined,
              title: 'No subjects yet',
              subtitle: 'Your admin will assign subjects soon',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final subject = sp.subjects[i];
                  final color = _subjectColors[i % _subjectColors.length];
                  final icon = _subjectIcons[i % _subjectIcons.length];
                  return FadeInUp(
                    delay: Duration(milliseconds: i * 60),
                    child: EpSubjectCard(
                      name: subject.name,
                      className: subject.className,
                      accentColor: color,
                      icon: icon,
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, a, b) => StudentLessonsScreen(
                            subject: subject,
                            accentColor: color,
                          ),
                          transitionsBuilder: (_, animation, __, child) =>
                              SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                                parent: animation,
                                curve: const Cubic(0.22, 1, 0.36, 1))),
                            child: child,
                          ),
                          transitionDuration: const Duration(milliseconds: 350),
                        ),
                      ),
                    ),
                  );
                },
                childCount: sp.subjects.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

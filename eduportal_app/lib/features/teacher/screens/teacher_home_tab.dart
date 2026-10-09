// lib/features/teacher/screens/teacher_home_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/teacher_provider.dart';
import '../../../core/models/models.dart';
import '../../../shared/widgets/ep_card.dart';
import 'teacher_subject_detail_screen.dart';

class TeacherHomeTab extends StatelessWidget {
  const TeacherHomeTab({super.key});

  static const List<Color> _classColors = [
    AppColors.teal,
    AppColors.indigo,
    AppColors.amber,
    AppColors.rose,
    AppColors.emerald,
    Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TeacherProvider>();
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
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${user?.fullName.split(' ').first ?? 'Teacher'} 👋',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Your Classes',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Logout
                      GestureDetector(
                        onTap: () => _confirmLogout(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Icon(Icons.logout_rounded,
                              size: 18, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stats row
                  if (!tp.loading && tp.subjects.isNotEmpty) ...[
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.class_rounded,
                          label: '${tp.subjects.length} Subjects',
                          color: AppColors.teal,
                        ),
                        const SizedBox(width: 10),
                        _StatChip(
                          icon: Icons.library_books_rounded,
                          label: '${tp.subjects.map((s) => s.classId).toSet().length} Classes',
                          color: AppColors.indigo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (tp.loading)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: EpLoadingShimmer(height: 120, borderRadius: 20),
                ),
                childCount: 3,
              ),
            ),
          )
        else if (tp.subjects.isEmpty)
          const SliverFillRemaining(
            child: EpEmptyState(
              icon: Icons.class_outlined,
              title: 'No subjects assigned',
              subtitle: 'The admin will assign your subjects soon',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final subject = tp.subjects[i];
                  final color = _classColors[i % _classColors.length];
                  return FadeInUp(
                    delay: Duration(milliseconds: i * 80),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _TeacherSubjectCard(
                        subject: subject,
                        accentColor: color,
                        onTap: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, a, b) =>
                                TeacherSubjectDetailScreen(
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
                            transitionDuration:
                                const Duration(milliseconds: 350),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: tp.subjects.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('You will be returned to the login screen.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
            },
            child: const Text('Sign Out',
                style: TextStyle(color: AppColors.rose)),
          ),
        ],
      ),
    );
  }
}

class _TeacherSubjectCard extends StatefulWidget {
  final SubjectModel subject;
  final Color accentColor;
  final VoidCallback onTap;

  const _TeacherSubjectCard({
    required this.subject,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_TeacherSubjectCard> createState() => _TeacherSubjectCardState();
}

class _TeacherSubjectCardState extends State<_TeacherSubjectCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.subject;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.accentColor,
                          widget.accentColor.withValues(alpha: 0.7)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.code,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      s.className,
                      style: TextStyle(
                        color: widget.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  _ActionHint(Icons.library_books_rounded, 'Manage Lessons',
                      widget.accentColor),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionHint extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ActionHint(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// lib/features/admin/screens/admin_home_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/admin_provider.dart';
import '../../../shared/widgets/ep_card.dart';
import '../../auth/screens/role_select_screen.dart';
import '../widgets/admin_dialogs.dart';

class AdminHomeTab extends StatelessWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const AdminHomeTab({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();
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
                            const Text(
                              'Admin Panel',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.fullName ?? 'Administrator',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Logout button
                      GestureDetector(
                        onTap: () async {
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, a, b) =>
                                    const RoleSelectScreen(),
                                transitionsBuilder:
                                    (_, animation, __, child) =>
                                        FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              ),
                              (r) => false,
                            );
                          }
                        },
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
                  const SizedBox(height: 28),

                  // Stats grid
                  FadeInUp(
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.school_rounded,
                            label: 'Students',
                            value: '${ap.students.length}',
                            gradient: AppColors.amberGradient,
                            onTap: () => onNavigateTab?.call(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.person_pin_rounded,
                            label: 'Teachers',
                            value: '${ap.teachers.length}',
                            gradient: AppColors.tealGradient,
                            onTap: () => onNavigateTab?.call(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    delay: const Duration(milliseconds: 80),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.class_rounded,
                            label: 'Classes',
                            value: '${ap.classes.length}',
                            gradient: AppColors.indigoGradient,
                            onTap: () => onNavigateTab?.call(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.book_rounded,
                            label: 'Subjects',
                            value: '${ap.subjects.length}',
                            gradient: AppColors.roseGradient,
                            onTap: () => onNavigateTab?.call(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Quick actions
                  FadeInUp(
                    delay: const Duration(milliseconds: 140),
                    child: const Text(
                      'Quick Actions',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeInUp(
                    delay: const Duration(milliseconds: 180),
                    child: _QuickActionGrid(ap: ap, onNavigateTab: onNavigateTab),
                  ),
                  const SizedBox(height: 32),

                  // Recent users
                  FadeInUp(
                    delay: const Duration(milliseconds: 220),
                    child: const EpSectionHeader(title: 'Recent Users'),
                  ),
                  const SizedBox(height: 14),
                  if (ap.loading)
                    ...List.generate(
                      3,
                      (i) => const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: EpLoadingShimmer(height: 64),
                      ),
                    )
                  else
                    ...ap.users.take(5).map((u) {
                      final roleColor = u.role == 'teacher'
                          ? AppColors.teal
                          : u.role == 'admin'
                              ? AppColors.indigo
                              : AppColors.amber;
                      return FadeInUp(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: EpCard(
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: roleColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      u.fullName.isNotEmpty
                                          ? u.fullName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: roleColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u.fullName,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '@${u.username}',
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: roleColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    u.role[0].toUpperCase() +
                                        u.role.substring(1),
                                    style: TextStyle(
                                      color: roleColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Gradient gradient;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  final AdminProvider ap;
  final void Function(int tabIndex)? onNavigateTab;

  const _QuickActionGrid({required this.ap, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action(
        'Add Student',
        Icons.person_add_rounded,
        AppColors.amberGradient,
        () => AdminDialogs.showAddStudentSheet(context, ap),
      ),
      _Action(
        'Add Teacher',
        Icons.person_pin_rounded,
        AppColors.tealGradient,
        () => AdminDialogs.showAddTeacherSheet(context, ap),
      ),
      _Action(
        'New Class',
        Icons.add_box_rounded,
        AppColors.indigoGradient,
        () => AdminDialogs.showAddClassSheet(context, ap),
      ),
      _Action(
        'New Subject',
        Icons.library_add_rounded,
        AppColors.roseGradient,
        () => AdminDialogs.showAddSubjectSheet(context, ap),
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: actions.map((a) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: a.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: a.gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(a.icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    a.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Action {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _Action(this.label, this.icon, this.gradient, this.onTap);
}


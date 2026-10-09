// lib/features/auth/screens/role_select_screen.dart
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import 'login_screen.dart';
import '../widgets/api_server_settings.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                // Logo & Badge
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            gradient: AppColors.indigoGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.indigo.withValues(alpha: 0.4),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.indigo.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.indigo.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'PROJECT SCOPE: CLASSES 6–10',
                            style: TextStyle(
                              color: AppColors.indigo,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Heading
                FadeInDown(
                  delay: const Duration(milliseconds: 150),
                  duration: const Duration(milliseconds: 600),
                  child: const Center(
                    child: Column(
                      children: [
                        Text(
                          'AcademyAlys',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Educational Learning Management Platform',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () => ApiServerSettings.show(context),
                    icon: Icon(
                      ApiService().isConfigured
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_off_outlined,
                    ),
                    label: Text(
                      ApiService().isConfigured
                          ? 'Change live backend'
                          : 'Connect live backend',
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Role select label
                FadeInUp(
                  delay: const Duration(milliseconds: 250),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Your Portal',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '3 Portals',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 1. Admin Portal
                FadeInUp(
                  delay: const Duration(milliseconds: 320),
                  child: _RoleButton(
                    label: 'Admin Portal',
                    subtitle: 'Define academic structure, classes 6-10 & permissions',
                    icon: Icons.admin_panel_settings_rounded,
                    gradient: AppColors.indigoGradient,
                    glowColor: AppColors.indigo,
                    badgeText: 'System Management',
                    onTap: () => _navigateToLogin(context, 'admin'),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Teacher Portal
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: _RoleButton(
                    label: 'Teacher Portal',
                    subtitle: 'Content management within assigned classes & subjects',
                    icon: Icons.school_rounded,
                    gradient: AppColors.tealGradient,
                    glowColor: AppColors.teal,
                    badgeText: 'Content Management',
                    onTap: () => _navigateToLogin(context, 'teacher'),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Student Portal
                FadeInUp(
                  delay: const Duration(milliseconds: 480),
                  child: _RoleButton(
                    label: 'Student Portal',
                    subtitle: 'Learning interface for assigned class & authorized content',
                    icon: Icons.person_rounded,
                    gradient: AppColors.amberGradient,
                    glowColor: AppColors.amber,
                    badgeText: 'Learning Experience',
                    onTap: () => _navigateToLogin(context, 'student'),
                  ),
                ),

                const SizedBox(height: 36),

                // Bottom Principle Hint (Section 1)
                FadeInUp(
                  delay: const Duration(milliseconds: 540),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Text(
                        'ADMIN  →  PERMISSIONS  →  TEACHER  →  CONTENT  →  STUDENT',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context, String role) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => LoginScreen(role: role),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.22, 1, 0.36, 1))),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }
}

class _RoleButton extends StatefulWidget {
  final String label;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final Gradient gradient;
  final Color glowColor;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_RoleButton> createState() => _RoleButtonState();
}

class _RoleButtonState extends State<_RoleButton>
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
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(18.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.label,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: widget.glowColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.badgeText,
                              style: TextStyle(
                                color: widget.glowColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

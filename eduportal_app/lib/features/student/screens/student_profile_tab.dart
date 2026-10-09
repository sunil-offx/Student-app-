// lib/features/student/screens/student_profile_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../shared/widgets/ep_button.dart';
import '../../../shared/widgets/ep_appbar.dart';
import '../../auth/screens/role_select_screen.dart';

class StudentProfileTab extends StatefulWidget {
  const StudentProfileTab({super.key});

  @override
  State<StudentProfileTab> createState() => _StudentProfileTabState();
}

class _StudentProfileTabState extends State<StudentProfileTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _regNumCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  DateTime? _selectedDob;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _regNumCtrl = TextEditingController(text: user?.rollNumber ?? 'REG-2026-1042');
    _phoneCtrl = TextEditingController(text: user?.contactNumber ?? '+91 98765 43210');
    _emailCtrl = TextEditingController(text: user?.email ?? '');

    if (user?.dateOfBirth != null && user!.dateOfBirth!.isNotEmpty) {
      try {
        _selectedDob = DateTime.parse(user.dateOfBirth!);
      } catch (_) {
        _selectedDob = DateTime(2008, 5, 14);
      }
    } else {
      _selectedDob = DateTime(2008, 5, 14);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().fetchProfile();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _regNumCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2008, 1, 1),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.amber,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ), dialogTheme: const DialogThemeData(backgroundColor: AppColors.cardBg),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final dobString = _selectedDob != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDob!)
        : '2008-05-14';

    final auth = context.read<AuthProvider>();
    final success = await auth.updateStudentProfile(
      fullName: _nameCtrl.text.trim(),
      registerNumber: _regNumCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      dateOfBirth: dobString,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Student profile updated successfully! 🎉'),
            ],
          ),
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to update profile'),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.rose, size: 24),
            SizedBox(width: 10),
            Text('Sign Out', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of EduPortal?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, b) => const RoleSelectScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final studentProfile = context.watch<StudentProvider>().profile ?? user;
    final formattedDob = _selectedDob != null
        ? DateFormat('dd MMM yyyy').format(_selectedDob!)
        : 'Select Date of Birth';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EpAppBar(
        title: 'Student Profile',
        subtitle: 'Manage your personal & academic info',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Avatar & Badges
                FadeInDown(
                  child: Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: AppColors.amberGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.amber.withValues(alpha: 0.35),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
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
                                    fontWeight: FontWeight.w800,
                                    fontSize: 42,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.amber, width: 2),
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: AppColors.amber,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.fullName ?? 'Student',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
                              ),
                              child: const Text(
                                'Role: Student',
                                style: TextStyle(
                                  color: AppColors.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.indigo.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.indigo.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                studentProfile?.className ?? 'Class 10th',
                                style: const TextStyle(
                                  color: AppColors.indigo,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Section: Personal Information
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: const Text(
                    'Personal & Academic Details',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Input Card
                FadeInUp(
                  delay: const Duration(milliseconds: 150),
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
                        // Student Name
                        _buildFieldLabel('Full Name'),
                        TextFormField(
                          controller: _nameCtrl,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: _inputDecoration(
                            hint: 'Enter your full name',
                            icon: Icons.person_outline_rounded,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                        ),
                        const SizedBox(height: 18),

                        // Register Number
                        _buildFieldLabel('Register Number / Roll No'),
                        TextFormField(
                          controller: _regNumCtrl,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: _inputDecoration(
                            hint: 'e.g. REG-2026-1042',
                            icon: Icons.badge_outlined,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Register number is required' : null,
                        ),
                        const SizedBox(height: 18),

                        // Phone Number
                        _buildFieldLabel('Phone Number'),
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: _inputDecoration(
                            hint: 'e.g. +91 98765 43210',
                            icon: Icons.phone_outlined,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
                        ),
                        const SizedBox(height: 18),

                        // Email ID
                        _buildFieldLabel('Email Address'),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: _inputDecoration(
                            hint: 'e.g. rahul@student.eduportal.com',
                            icon: Icons.email_outlined,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Enter a valid email address';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Date of Birth Field
                        _buildFieldLabel('Date of Birth'),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: AppColors.amber, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    formattedDob,
                                    style: TextStyle(
                                      color: _selectedDob != null ? AppColors.textPrimary : AppColors.textMuted,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.edit_calendar_rounded, color: AppColors.textMuted, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Section 33.1: Academic Progression & Historical Enrollment
                FadeInUp(
                  delay: const Duration(milliseconds: 175),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Academic Enrollment History',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Preserved History',
                              style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            if (studentProfile?.enrollmentHistory.isNotEmpty == true) ...[
                              ...studentProfile!.enrollmentHistory.map((h) => _buildEnrollmentTimelineTile(
                                year: h.academicYear,
                                className: h.className,
                                section: h.sectionName ?? '',
                                isActive: h.status == 'active',
                              )),
                            ] else ...[
                              _buildEnrollmentTimelineTile(
                                year: '2026-2027',
                                className: studentProfile?.className ?? 'Class 10',
                                section: studentProfile?.sectionName ?? 'Section A',
                                isActive: true,
                              ),
                              _buildEnrollmentTimelineTile(
                                year: '2025-2026',
                                className: 'Class 9',
                                section: 'Section A',
                                isActive: false,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Save Profile Button
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: EpGradientButton(
                    label: 'Save Profile Changes',
                    gradient: AppColors.amberGradient,
                    loading: _isSaving,
                    onTap: _saveProfile,
                  ),
                ),
                const SizedBox(height: 16),

                // Logout Button
                FadeInUp(
                  delay: const Duration(milliseconds: 250),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _confirmLogout,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.rose.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.rose.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: AppColors.rose, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              color: AppColors.rose,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnrollmentTimelineTile({
    required String year,
    required String className,
    required String section,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.amber.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? AppColors.amber.withValues(alpha: 0.5) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.amber.withValues(alpha: 0.2) : AppColors.cardBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.verified_rounded : Icons.history_rounded,
              color: isActive ? AppColors.amber : AppColors.textMuted,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$className • $section',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Academic Year: $year',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isActive ? AppColors.emerald.withValues(alpha: 0.15) : AppColors.cardBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isActive ? 'Active' : 'Completed',
              style: TextStyle(
                color: isActive ? AppColors.emerald : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
      ),
    );
  }
}

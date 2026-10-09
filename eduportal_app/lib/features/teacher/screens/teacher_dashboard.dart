// lib/features/teacher/screens/teacher_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/teacher_provider.dart';
import 'teacher_home_tab.dart';
import 'teacher_upload_tab.dart';
import 'teacher_quiz_tab.dart';
import 'teacher_assignments_tab.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;

  final _tabs = const [
    TeacherHomeTab(),
    TeacherUploadTab(),
    TeacherQuizTab(),
    TeacherAssignmentsTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeacherProvider>().fetchSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.teal.withValues(alpha: 0.15),
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.teal),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.upload_file_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.upload_file_rounded, color: AppColors.teal),
                label: 'Upload',
              ),
              NavigationDestination(
                icon: Icon(Icons.quiz_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.quiz_rounded, color: AppColors.teal),
                label: 'Quiz',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.assignment_rounded, color: AppColors.teal),
                label: 'Assignments',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

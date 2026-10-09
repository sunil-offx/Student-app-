// lib/features/student/screens/student_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/student_provider.dart';
import 'student_subjects_tab.dart';
import 'student_assignments_tab.dart';
import 'student_quizzes_tab.dart';
import 'student_profile_tab.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  final _tabs = const [
    StudentSubjectsTab(),
    StudentAssignmentsTab(),
    StudentQuizzesTab(),
    StudentProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = context.read<StudentProvider>();
      sp.fetchSubjects();
      sp.fetchAssignments();
      sp.fetchQuizzes();
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
            indicatorColor: AppColors.amber.withValues(alpha: 0.15),
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.book_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.book_rounded, color: AppColors.amber),
                label: 'Subjects',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.assignment_rounded, color: AppColors.amber),
                label: 'Assignments',
              ),
              NavigationDestination(
                icon: Icon(Icons.quiz_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.quiz_rounded, color: AppColors.amber),
                label: 'Quizzes',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.person_rounded, color: AppColors.amber),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

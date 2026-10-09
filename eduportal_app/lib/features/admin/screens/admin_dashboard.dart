// lib/features/admin/screens/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/admin_provider.dart';
import 'admin_home_tab.dart';
import 'admin_users_tab.dart';
import 'admin_classes_tab.dart';
import 'admin_subjects_tab.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  List<Widget> get _tabs => [
    AdminHomeTab(onNavigateTab: (i) => setState(() => _currentIndex = i)),
    const AdminUsersTab(),
    const AdminClassesTab(),
    const AdminSubjectsTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAll();
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
            indicatorColor: AppColors.indigo.withValues(alpha: 0.15),
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.home_rounded, color: AppColors.indigo),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.people_rounded, color: AppColors.indigo),
                label: 'Users',
              ),
              NavigationDestination(
                icon: Icon(Icons.class_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.class_rounded, color: AppColors.indigo),
                label: 'Classes',
              ),
              NavigationDestination(
                icon: Icon(Icons.book_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.book_rounded, color: AppColors.indigo),
                label: 'Subjects',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

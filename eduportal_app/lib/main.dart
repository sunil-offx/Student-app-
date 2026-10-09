// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/student_provider.dart';
import 'core/providers/teacher_provider.dart';
import 'core/providers/admin_provider.dart';
import 'core/services/api_service.dart';
import 'features/auth/screens/role_select_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().initialize();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0C0E1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const EduPortalApp());
}

class EduPortalApp extends StatelessWidget {
  const EduPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => TeacherProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'AcademyAlys',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const RoleSelectScreen(),
      ),
    );
  }
}

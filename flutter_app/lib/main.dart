
import 'package:flutter/material.dart';
import 'screen/login_screen.dart';
import 'services/auth_service.dart';
import 'screen/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý công việc nhóm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService authService = AuthService();
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    try {
      final token = await authService.getToken();

      if (token != null && token.isNotEmpty) {
        final result = await authService.getProfile();

        if (result['success'] == true) {
          isLoggedIn = true;
        }
      }
    } catch (e) {
      isLoggedIn = false;
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isLoggedIn) {
      return LoginScreen(
        onLoginSuccess: () {
          setState(() {
            isLoggedIn = true;
          });
        },
      );
    }

    return ProfileScreen(
      onLogout: () {
        setState(() {
          isLoggedIn = false;
        });
      },
    );
  }
}

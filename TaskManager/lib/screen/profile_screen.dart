
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService authService = AuthService();

  Map<String, dynamic>? user;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final result = await authService.getProfile();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          user = Map<String, dynamic>.from(
            result['user'] ?? {},
          );
        });
      } else {
        setState(() {
          error = result['message'] ?? 'Không tải được thông tin';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Không thể kết nối đến server';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> editProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const EditProfileScreen(),
      ),
    );

    if (result == true) {
      await loadProfile();
    }
  }

  Future<void> changePassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChangePasswordScreen(),
      ),
    );
  }

  Future<void> logout() async {
    await authService.logout();

    if (!mounted) return;

    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài khoản'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!),
            ElevatedButton(
              onPressed: loadProfile,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 45,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              user?['name']?.toString() ?? 'Người dùng',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              user?['email']?.toString() ?? '',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Chỉnh sửa thông tin'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: editProfile,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Đổi mật khẩu'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: changePassword,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Đăng xuất',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

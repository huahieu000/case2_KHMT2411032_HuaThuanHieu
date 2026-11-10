
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
  bool isLoggingOut = false;
  String? error;

  static const Color navy = Color(0xFF202B50);
  static const Color blue = Color(0xFF536DFE);
  static const Color background = Color(0xFFF4F6FC);

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

      setState(() {
        user = Map<String, dynamic>.from(result);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Không thể tải thông tin tài khoản.';
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
    if (isLoggingOut) return;

    setState(() {
      isLoggingOut = true;
    });

    try {
      await authService.logout();

      if (!mounted) return;

      widget.onLogout();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng xuất thất bại. Vui lòng thử lại.'),
        ),
      );
    }
  }

  Widget buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = blue,
    bool isDanger = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 5,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDanger ? Colors.red.shade600 : navy,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.blueGrey,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.blueGrey,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Quản lý tài khoản',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 45,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(error!),
            const SizedBox(height: 12),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          children: [
            // Thông tin tài khoản
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    navy,
                    Color(0xFF3D5594),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: navy.withValues(alpha: 0.18),
                    blurRadius: 15,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white70,
                        width: 2,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 43,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    user?['name']?.toString() ?? 'Người dùng',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    user?['email']?.toString() ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user,
                          size: 15,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Tài khoản đang hoạt động',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'CÀI ĐẶT TÀI KHOẢN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  letterSpacing: 1,
                ),
              ),
            ),

            // Các chức năng tài khoản
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  buildMenuItem(
                    icon: Icons.edit_outlined,
                    title: 'Chỉnh sửa thông tin',
                    subtitle: 'Cập nhật tên và thông tin cá nhân',
                    onTap: editProfile,
                  ),
                  const Divider(height: 1, indent: 70),
                  buildMenuItem(
                    icon: Icons.lock_outline,
                    title: 'Đổi mật khẩu',
                    subtitle: 'Thay đổi mật khẩu tài khoản',
                    onTap: changePassword,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'KHÁC',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  letterSpacing: 1,
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),
                ),
                title: const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                subtitle: const Text(
                  'Đăng xuất khỏi tài khoản hiện tại',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey,
                  ),
                ),
                trailing: isLoggingOut
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.chevron_right,
                  color: Colors.red,
                ),
                onTap: isLoggingOut ? null : logout,
              ),
            ),

            const SizedBox(height: 25),

            const Center(
              child: Text(
                'ỨNG DỤNG QUẢN LÝ CÔNG VIỆC NHÓM',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blueGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

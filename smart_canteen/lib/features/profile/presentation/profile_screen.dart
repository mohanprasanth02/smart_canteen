import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/data/auth_provider.dart';
import '../../../core/socket/socket_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _ipController = TextEditingController();
  bool _isEditingIp = false;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  Future<void> _loadSavedIp() async {
    final savedIp = await _storage.read(key: 'server_ip');
    setState(() {
      _ipController.text = savedIp ?? ApiConstants.baseIp;
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _saveIp() async {
    final newIp = _ipController.text.trim();
    await _storage.write(key: 'server_ip', value: newIp);

    setState(() {
      ApiConstants.baseIp = newIp;
      _isEditingIp = false;
    });
    
    // Reconfigure api client
    ref.read(apiClientProvider).dio.options.baseUrl = 'http://$newIp:5000';
    
    // Reconnect sockets with new IP
    final user = ref.read(authStateProvider).user;
    if (user != null) {
      ref.read(socketServiceProvider).disconnect();
      ref.read(socketServiceProvider).connect(userId: user['id']);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server IP updated to: $newIp'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Header
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.darkSurface,
                    child: Icon(Icons.person, size: 60, color: AppColors.primaryNeon),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?['full_name'] ?? 'College Student',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?['register_number'] ?? 'N/A',
                    style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // College details list
            GlassmorphicCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileRow('Department', user?['department'] ?? 'Computer Science'),
                  _buildProfileRow('Current Year', '${user?['year'] ?? 1} Year'),
                  _buildProfileRow('College Email', user?['email'] ?? ''),
                  _buildProfileRow('Mobile Number', user?['mobile_number'] ?? ''),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Support section
            const Text(
              'Help & Support',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            GlassmorphicCard(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(Icons.support_agent_rounded, color: AppColors.primaryNeon, size: 28),
                title: const Text('Live Support Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Chat with canteen staff regarding orders', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryNeon, size: 16),
                onTap: () => context.push('/support-chat'),
              ),
            ),
            const SizedBox(height: 20),

            // Wi-Fi Local Host config section
            const Text(
              'Local Network Configurations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            GlassmorphicCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi, color: AppColors.primaryNeon, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _isEditingIp
                            ? TextField(
                                controller: _ipController,
                                decoration: const InputDecoration(
                                  labelText: 'Host Server IP',
                                  hintText: '192.168.x.x',
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Server Base IP', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  Text(ApiConstants.baseIp, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                      IconButton(
                        icon: Icon(_isEditingIp ? Icons.check : Icons.edit, color: AppColors.primaryNeon),
                        onPressed: () {
                          if (_isEditingIp) {
                            _saveIp();
                          } else {
                            setState(() => _isEditingIp = true);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Log out button
            GradientButton(
              text: 'Log Out',
              gradient: const LinearGradient(
                colors: [AppColors.error, Color(0xFFC00050)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

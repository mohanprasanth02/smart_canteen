import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../data/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isAdminMode = false;
  bool _obscurePassword = true;

  void _showIpConfigDialog(BuildContext context) async {
    const storage = FlutterSecureStorage();
    final currentIp = await storage.read(key: 'server_ip') ?? ApiConstants.baseIp;
    final controller = TextEditingController(text: currentIp);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Server Configuration', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter host laptop IP address on the Wi-Fi network:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Server Host IP',
                hintText: 'e.g. 192.168.1.15',
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newIp = controller.text.trim();
              await storage.write(key: 'server_ip', value: newIp);
              
              // Apply globally
              ApiConstants.baseIp = newIp;
              ref.read(apiClientProvider).dio.options.baseUrl = 'http://$newIp:5000';
              
              // Clear current auth state error to allow retry
              ref.read(authStateProvider.notifier).checkAuthentication();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Server IP updated to $newIp. Retrying connection...'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Save & Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authStateProvider.notifier);
    bool success;

    if (_isAdminMode) {
      success = await authNotifier.adminLogin(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      success = await authNotifier.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }

    if (success && mounted) {
      if (_isAdminMode) {
        context.go('/admin-dashboard');
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryNeon.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNeon.withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentCyan.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentCyan.withOpacity(0.12),
                    blurRadius: 120,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          
          // Server Settings Icon (Top-Right)
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 26),
                onPressed: () => _showIpConfigDialog(context),
              ),
            ),
          ),

          // Main Layout
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo/Header
                    const Icon(
                      Icons.restaurant_menu_rounded,
                      size: 70,
                      color: AppColors.primaryNeon,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Smart Canteen',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isAdminMode ? 'Staff Control Center' : 'Fresh food delivered to your department',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 40),

                    // Login Card
                    GlassmorphicCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isAdminMode ? 'Admin Portal' : 'Student Login',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Email / Username field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: _isAdminMode ? TextInputType.text : TextInputType.emailAddress,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  _isAdminMode ? Icons.person_outline : Icons.alternate_email_outlined,
                                  color: AppColors.primaryNeon,
                                ),
                                labelText: _isAdminMode ? 'Username' : 'College Email',
                                hintText: _isAdminMode ? 'Enter admin username' : 'student@college.edu',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return _isAdminMode ? 'Enter username' : 'Enter email';
                                }
                                if (!_isAdminMode && !val.contains('@')) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.lock_open_outlined,
                                  color: AppColors.primaryNeon,
                                ),
                                labelText: 'Password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppColors.textDarkSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Enter password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            if (authState.error != null) ...[
                              Text(
                                authState.error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.error, fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Action Button
                            GradientButton(
                              text: 'Sign In',
                              isLoading: authState.isLoading,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Toggle admin portal
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isAdminMode = !_isAdminMode;
                          _formKey.currentState?.reset();
                          _emailController.clear();
                          _passwordController.clear();
                        });
                      },
                      child: Text(
                        _isAdminMode ? 'Switch to Student View' : 'Access Canteen Staff Admin Portal',
                        style: const TextStyle(
                          color: AppColors.primaryNeon,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    if (!_isAdminMode) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          GestureDetector(
                            onTap: () => context.push('/register'),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: AppColors.primaryNeon,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

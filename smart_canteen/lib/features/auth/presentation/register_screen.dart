import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../data/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regNumController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedDept = 'Computer Science';
  int _selectedYear = 1;
  bool _obscurePassword = true;

  final List<String> _departments = [
    'Computer Science',
    'Information Technology',
    'Electronics & Communication',
    'Electrical & Electronics',
    'Mechanical Engineering',
    'Civil Engineering',
    'Business Administration',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _regNumController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authStateProvider.notifier).register(
          fullName: _nameController.text.trim(),
          registerNumber: _regNumController.text.trim().toUpperCase(),
          department: _selectedDept,
          year: _selectedYear,
          mobileNumber: _mobileController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryNeon.withOpacity(0.12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNeon.withOpacity(0.12),
                    blurRadius: 100,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // Content Form
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Join the College Canteen Ecosystem',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textDarkSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),

                  GlassmorphicCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Full Name
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryNeon),
                              labelText: 'Full Name',
                              hintText: 'John Doe',
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter full name' : null,
                          ),
                          const SizedBox(height: 16),

                          // Register Number
                          TextFormField(
                            controller: _regNumController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primaryNeon),
                              labelText: 'Register Number / ID',
                              hintText: 'e.g. 26CSE0412',
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter registration/ID number' : null,
                          ),
                          const SizedBox(height: 16),

                          // Department Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedDept,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.school_outlined, color: AppColors.primaryNeon),
                              labelText: 'Department',
                            ),
                            dropdownColor: AppColors.darkSurface,
                            items: _departments.map((String dept) {
                              return DropdownMenuItem<String>(
                                value: dept,
                                child: Text(dept, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedDept = val;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Year Slider or Selection Row
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Current Year',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ),
                              Row(
                                children: List.generate(4, (index) {
                                  final yearNum = index + 1;
                                  final isSelected = _selectedYear == yearNum;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedYear = yearNum),
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primaryNeon : AppColors.darkSurface,
                                        border: Border.all(
                                          color: isSelected ? Colors.transparent : AppColors.darkBorder,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$yearNum',
                                          style: TextStyle(
                                            color: isSelected ? Colors.black : Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Mobile Number
                          TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primaryNeon),
                              labelText: 'Mobile Number',
                              hintText: '10-digit number',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter mobile number';
                              if (val.trim().length < 10) return 'Enter valid 10-digit number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.alternate_email, color: AppColors.primaryNeon),
                              labelText: 'Email Address',
                              hintText: 'student@college.edu',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter email';
                              if (!val.contains('@')) return 'Enter valid email address';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_open, color: AppColors.primaryNeon),
                              labelText: 'Password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppColors.textDarkSecondary,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Enter password';
                              if (val.length < 6) return 'Password must be at least 6 characters';
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

                          // Action Register Button
                          GradientButton(
                            text: 'Sign Up',
                            isLoading: authState.isLoading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

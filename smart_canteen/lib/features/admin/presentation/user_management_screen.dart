import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../data/admin_provider.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersVal = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Directory'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: usersVal.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users registered.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, idx) {
              final student = users[idx];
              final isActive = student['is_active'] == true;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GlassmorphicCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.darkSurface,
                        child: Icon(Icons.person, color: AppColors.primaryNeon),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student['full_name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reg: ${student['register_number']} • ${student['department']}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isActive,
                        onChanged: (val) {
                          ref.read(adminUsersProvider.notifier).toggleUser(student['id']);
                        },
                        activeColor: AppColors.success,
                        inactiveThumbColor: AppColors.error,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryNeon)),
        error: (_, __) => const Center(child: Text('Error loading users')),
      ),
    );
  }
}

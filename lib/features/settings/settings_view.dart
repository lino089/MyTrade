import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengaturan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 24),

          // Account Configuration
          Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Akun Trading',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Beralih ke akun trading yang lain',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(selectedAccountProvider.notifier).selectAccount(null);
                      // Router notifier will automatically redirect back to /accounts
                    },
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: const Text('Ganti Akun'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // User Info & Sign Out
          Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sesi Pengguna',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authState.email ?? 'Tidak terhubung',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (authState.userId != null)
                    OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(selectedAccountProvider.notifier).selectAccount(null);
                        await ref.read(authNotifierProvider.notifier).signOut();
                        if (mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout_rounded, color: AppColors.loss),
                      label: const Text('Keluar', style: TextStyle(color: AppColors.loss)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.loss),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

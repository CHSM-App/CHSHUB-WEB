import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../widgets/app_widgets.dart';

/// Account details, password change and sign out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _buildProfileCard(user?.name, user?.username, user?.userType),
            const SizedBox(height: 20),
            if (user?.societyName != null) ...[
              Text('Society', style: AppTheme.title),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  children: [
                    _row('Name', user!.societyName!),
                    if (user.societyId != null) _row('Code', user.societyId!),
                    if (user.email != null) _row('Email', user.email!),
                    if (user.contactNo != null)
                      _row('Contact', user.contactNo!),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text('Account', style: AppTheme.title),
            const SizedBox(height: 8),
            MenuTile(
              icon: Icons.lock_outline,
              color: AppTheme.primary,
              title: 'Change password',
              subtitle: 'Choose a new password for this account',
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => const _ChangePasswordForm(),
              ),
            ),
            MenuTile(
              icon: Icons.logout,
              color: AppTheme.error,
              title: 'Sign out',
              subtitle: 'End this session on this device',
              onTap: () => _confirmSignOut(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String? name, String? username, String? role) {
    return GradientPanel(
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd + 2),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              initialsOf(name ?? 'Secretary'),
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppTheme.white,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'Secretary',
                  style: AppTheme.title.copyWith(
                    color: AppTheme.white,
                    fontSize: 17,
                  ),
                ),
                if (username != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    username,
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.onGradientMuted,
                    ),
                  ),
                ],
                if (role != null) ...[
                  const SizedBox(height: 6),
                  StatusChip(
                    label: role,
                    color: AppTheme.white,
                    onSurface: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: AppTheme.caption)),
          Expanded(child: Text(value, style: AppTheme.body2)),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to continue.',
      confirmLabel: 'Sign out',
      cancelLabel: 'Stay signed in',
      destructive: true,
    );

    if (!confirmed) return;

    // AuthGate watches tokenProvider and swaps back to the login screen once
    // the tokens are cleared, so no navigation is needed here.
    await ref.read(authViewModelProvider.notifier).logout();
  }
}

class _ChangePasswordForm extends ConsumerStatefulWidget {
  const _ChangePasswordForm();

  @override
  ConsumerState<_ChangePasswordForm> createState() =>
      _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<_ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref
        .read(authViewModelProvider.notifier)
        .changePassword(_newController.text);

    if (!mounted) return;

    showAppSnack(
      context,
      ok
          ? 'Password changed.'
          : (ref.read(authViewModelProvider).error ??
                'Could not change the password.'),
      success: ok,
    );

    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authViewModelProvider).isLoading;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Change password', style: AppTheme.headline),
              const SizedBox(height: 20),
              // No "current password" field: the API does not ask for one —
              // a valid access token already proves possession of the account,
              // and requiring the old password locked out anyone who had
              // forgotten it.
              TextFormField(
                controller: _newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
                validator: (v) => (v == null || v.length < 8)
                    ? 'Use at least 8 characters'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
                validator: (v) =>
                    v != _newController.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.white,
                        ),
                      )
                    : const Text('Change password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

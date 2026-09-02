import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../widgets/app_widgets.dart';

/// The dialog the profile screen opens to set a new password.
///
/// A dialog rather than a bottom sheet: this is a short, focused form with a
/// clear commit/cancel pair, and it is the same shape `_VendorDialog` uses for
/// a form of this size. Sheets in this app are for the taller, scrolling forms.
class ChangePasswordForm extends ConsumerStatefulWidget {
  const ChangePasswordForm({super.key});

  @override
  ConsumerState<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure = true;

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

    return AlertDialog(
      // The plate carries the same violet the profile screen's Change password
      // tile uses, so the dialog reads as that tile opening rather than as an
      // unrelated prompt.
      title: Row(
        children: [
          const IconPlate(
            icon: Icons.lock_outline,
            color: AppTheme.violet,
            size: 38,
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change password',
                  style: AppTheme.headline.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 2),
                Text('Use at least 8 characters.', style: AppTheme.caption),
              ],
            ),
          ),
        ],
      ),
      // Two fields plus their validation messages are taller than a small
      // phone once the keyboard is up, and an AlertDialog does not scroll its
      // own content. The width matches _VendorDialog so forms in this app do
      // not each pick a different size on a tablet.
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // No "current password" field: the API does not ask for one —
                // a valid access token already proves possession of the
                // account, and requiring the old password locked out anyone
                // who had forgotten it.
                TextFormField(
                  controller: _newController,
                  obscureText: _obscure,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    prefixIcon: const Icon(Icons.key_outlined),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 8)
                      ? 'Use at least 8 characters'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!isLoading) _submit();
                  },
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                  validator: (v) => v != _newController.text
                      ? 'Passwords do not match'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Disabled while the request is in flight: dismissing here would leave
        // a change the user believes they cancelled to land anyway.
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(minimumSize: const Size(112, 44)),
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
    );
  }
}

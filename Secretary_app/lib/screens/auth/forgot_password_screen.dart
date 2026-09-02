import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import 'auth_shell.dart';

/// Reset a forgotten password.
///
/// One step, not the usual send-a-code-then-reset pair: the API takes the email
/// address and the new password together. Identity is proved out of band — the
/// existing flow verifies the resident over SMS before they get here — so there
/// is no code to enter.
///
/// The server answers identically whether or not the address is registered, so
/// the confirmation below is deliberately worded as "if that address has an
/// account". Saying the password *was* changed would leak which addresses
/// exist, and would be a lie for a typo.
///
/// Shares [AuthShell] with the login screen. It used to be a white page under a
/// default AppBar, which looked like a different app the moment you tapped
/// through from the gradient.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure = true;

  /// Swaps the form for the confirmation panel. The screen does not pop on
  /// success any more: a reset is the end of a task, and popping straight back
  /// to a sign-in form left it ambiguous whether anything had happened.
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // Redraws the strength meter as the password is typed.
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() => setState(() {});

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final ok = await ref
        .read(authViewModelProvider.notifier)
        .forgotPassword(_emailController.text.trim(), _passwordController.text);

    if (!mounted) return;

    if (ok) {
      setState(() => _done = true);
      return;
    }

    // Failures stay on the form so the typed values survive.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authViewModelProvider).error ??
                'Could not reset the password.',
          ),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 5),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authViewModelProvider).isLoading;

    return AuthShell(
      // The pitch belongs on the way in, not mid-task.
      showTagline: false,
      card: _done ? _buildDone() : _buildForm(isLoading),
    );
  }

  Widget _buildForm(bool isLoading) {
    return AuthCard(
      onBack: () => Navigator.pop(context),
      eyebrow: 'Forgot your password?',
      title: 'Reset it here',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the email address on your account and the password you '
              'would like to use.',
              style: AppTheme.body2.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppTheme.space6),
            AuthField(
              label: 'Email address',
              controller: _emailController,
              icon: Icons.mail_outline_rounded,
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              autofill: const [AutofillHints.email],
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Enter your email address';
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.space5),
            AuthField(
              label: 'New password',
              controller: _passwordController,
              icon: Icons.lock_outline_rounded,
              hint: 'At least 8 characters',
              obscure: _obscure,
              autofill: const [AutofillHints.newPassword],
              suffix: IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppTheme.lightText,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              // Matches the server's own minimum, so a too-short password is
              // caught before the round trip.
              validator: (v) => (v == null || v.length < 8)
                  ? 'Use at least 8 characters'
                  : null,
            ),
            if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space3),
              _StrengthMeter(password: _passwordController.text),
            ],
            const SizedBox(height: AppTheme.space5),
            AuthField(
              label: 'Confirm new password',
              controller: _confirmController,
              icon: Icons.lock_outline_rounded,
              hint: 'Type it again',
              obscure: _obscure,
              onSubmitted: (_) {
                if (!isLoading) _submit();
              },
              validator: (v) => v != _passwordController.text
                  ? 'Passwords do not match'
                  : null,
            ),
            const SizedBox(height: AppTheme.space6),
            AuthSubmit(
              label: 'Reset password',
              busy: isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  /// Shown after the server accepts the request.
  ///
  /// Worded around "if that address has an account" for the reason in the class
  /// doc: the endpoint answers the same either way, so a flat "done" would be
  /// both a disclosure and, for a mistyped address, untrue.
  Widget _buildDone() {
    return AuthCard(
      title: 'Check your details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space4),
            decoration: BoxDecoration(
              color: AppTheme.successSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppTheme.success,
                  size: 22,
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: Text(
                    'If that address has an account, its password has been '
                    'changed. You can now sign in with the new password.',
                    style: AppTheme.body2.copyWith(
                      color: AppTheme.darkText,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            'Resetting a password signs the account out everywhere else, so '
            'any other device will ask for the new one.',
            style: AppTheme.caption.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppTheme.space6),
          AuthSubmit(
            label: 'Back to sign in',
            busy: false,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

/// A three-step read on the typed password.
///
/// Advisory only — the server's rule is the 8-character minimum the field
/// already enforces. This exists so someone choosing a new password gets a
/// nudge toward a better one at the moment they are choosing it, which is the
/// only moment the nudge is useful.
class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.password});

  final String password;

  /// 0 weak, 1 fair, 2 strong.
  int get _score {
    var points = 0;
    if (password.length >= 8) points++;
    if (password.length >= 12) points++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      points++;
    }
    if (RegExp(r'\d').hasMatch(password)) points++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) points++;

    if (points <= 2) return 0;
    if (points <= 3) return 1;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;
    const labels = ['Weak', 'Fair', 'Strong'];
    const colors = [AppTheme.error, AppTheme.warning, AppTheme.success];

    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              decoration: BoxDecoration(
                color: i <= score ? colors[score] : AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
        const SizedBox(width: AppTheme.space3),
        SizedBox(
          width: 46,
          child: Text(
            labels[score],
            style: AppTheme.caption.copyWith(
              color: colors[score],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../presentation/providers/viewmodel_provider.dart';
import '../../widgets/app_widgets.dart';
import 'auth_shell.dart';
import 'forgot_password_screen.dart';

/// Sign in.
///
/// Laid out the way CHSHUB_app's login page is: a full-bleed vertical
/// gradient, the product name in large white type over it, and a white card
/// carrying the form. The three staged animations are CHSHUB's too — the page
/// fades and rises, the wordmark springs in 300ms later, the card follows at
/// 600ms.
///
/// The fields differ because the APIs do. CHSHUB signs a resident in with a
/// phone number and an OTP; the website API this app talks to
/// (/api/web/auth/login) takes a username and password, so that is what the
/// card asks for.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  // ── Animation ────────────────────────────────────────────────────────

  late final AnimationController _pageController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  late final AnimationController _logoController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  late final AnimationController _cardController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _pageFade = CurvedAnimation(
    parent: _pageController,
    curve: Curves.easeInOut,
  );

  late final Animation<Offset> _pageSlide =
      Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _pageController, curve: Curves.easeOutCubic),
      );

  late final Animation<double> _logoScale = Tween<double>(
    begin: 0.5,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));

  late final Animation<double> _cardScale = Tween<double>(begin: 0.9, end: 1.0)
      .animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
      );

  late final Animation<double> _cardFade = CurvedAnimation(
    parent: _cardController,
    curve: Curves.easeIn,
  );

  late final Animation<Offset> _cardSlide =
      Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
      );

  /// Held so they can be cancelled on dispose.
  ///
  /// CHSHUB stages these with bare `Future.delayed` and a `mounted` check,
  /// which leaves a live timer behind if the screen is popped first — enough
  /// to fail a widget test with "pending timers", and a real leak besides.
  Timer? _logoTimer;
  Timer? _cardTimer;

  @override
  void initState() {
    super.initState();
    _pageController.forward();

    // Staggered rather than simultaneous: the wordmark lands after the page
    // has settled, the card after the wordmark.
    _logoTimer = Timer(
      const Duration(milliseconds: 300),
      _logoController.forward,
    );
    _cardTimer = Timer(
      const Duration(milliseconds: 600),
      _cardController.forward,
    );
  }

  @override
  void dispose() {
    _logoTimer?.cancel();
    _cardTimer?.cancel();
    _pageController.dispose();
    _logoController.dispose();
    _cardController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Dismiss the keyboard so an error is not hidden behind it.
    FocusManager.instance.primaryFocus?.unfocus();

    final ok = await ref
        .read(authViewModelProvider.notifier)
        .login(_usernameController.text.trim(), _passwordController.text);

    // AuthGate watches tokenProvider and swaps the tree itself once the tokens
    // are saved, so a successful login needs no navigation here.
    if (!ok && mounted) {
      final error = ref.read(authViewModelProvider).error;
      if (error != null) showAppSnack(context, error, success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authViewModelProvider).isLoading;

    // The gradient, the responsive two-panel layout and the card chrome all
    // live in AuthShell, so this screen and the reset screen stay the same
    // place rather than drifting apart.
    return AuthShell(
      pageAnimation: (child) => FadeTransition(
        opacity: _pageFade,
        child: SlideTransition(position: _pageSlide, child: child),
      ),
      wordmarkAnimation: (child) =>
          ScaleTransition(scale: _logoScale, child: child),
      cardAnimation: (child) => SlideTransition(
        position: _cardSlide,
        child: FadeTransition(
          opacity: _cardFade,
          child: ScaleTransition(scale: _cardScale, child: child),
        ),
      ),
      card: _buildCard(isLoading),
    );
  }

  // ── Card ─────────────────────────────────────────────────────────────

  Widget _buildCard(bool isLoading) {
    return AuthCard(
      eyebrow: 'Welcome back,',
      title: 'Sign in to continue',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthField(
              label: 'Username',
              controller: _usernameController,
              icon: Icons.person_outline_rounded,
              hint: 'Enter your username',
              autofill: const [AutofillHints.username],
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter your username'
                  : null,
            ),
            const SizedBox(height: AppTheme.space5),
            AuthField(
              label: 'Password',
              controller: _passwordController,
              icon: Icons.lock_outline_rounded,
              hint: 'Enter your password',
              obscure: _obscure,
              autofill: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
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
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter your password' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                ),
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: AppTheme.space3),
            AuthSubmit(
              label: 'Sign in',
              busy: isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

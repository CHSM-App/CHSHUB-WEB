import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/responsive.dart';

/// The gradient page both auth screens sit on.
///
/// Extracted so Sign in and Reset password are visibly the same place: before
/// this, the login screen was a full-bleed gradient with an animated card and
/// the reset screen was a plain white page under a default AppBar, which read
/// as a different app.
///
/// The layout changes shape with the window rather than only capping its width:
///
///   phone   — brand above the card, one centred column
///   tablet+ — brand on the left, card on the right, side by side
///
/// The side-by-side arrangement is what stops the page from being a narrow
/// ribbon of content stranded in the middle of a desktop browser, which is what
/// a `maxWidth` cap on its own produces. The brand panel earns the space it
/// takes: on a wide window it carries the wordmark and a short list of what the
/// app is for, so the empty half is doing something.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.card,
    this.showTagline = true,
    this.cardAnimation,
    this.pageAnimation,
    this.wordmarkAnimation,
  });

  /// The form panel — a [AuthCard], usually.
  final Widget card;

  /// The three-line pitch under the wordmark on wide windows.
  final bool showTagline;

  /// Wraps the card, for the login screen's staged entrance. Kept as a
  /// callback rather than an Animation so a screen with no animation — the
  /// reset page — passes nothing and gets the card unwrapped.
  final Widget Function(Widget child)? cardAnimation;

  /// Wraps the whole page, and the wordmark, for the same staged entrance.
  ///
  /// Three separate hooks rather than one because the stages are offset: the
  /// page fades and rises first, the wordmark springs in after it, the card
  /// last. Collapsing them into a single wrapper would land all three at once.
  final Widget Function(Widget child)? pageAnimation;
  final Widget Function(Widget child)? wordmarkAnimation;

  Widget _wrapPage(Widget child) => pageAnimation?.call(child) ?? child;

  @override
  Widget build(BuildContext context) {
    final wide = !Breakpoints.isPhone(context);
    final wrapped = cardAnimation?.call(card) ?? card;

    return Scaffold(
      // The gradient is the page, not a header: it runs behind the status bar
      // and under the keyboard, so the card floats on it at every height.
      body: Container(
        decoration: const BoxDecoration(gradient: _authGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? AppTheme.space8 : 28,
                      vertical: AppTheme.space5,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: wide ? 1000 : 460,
                        ),
                        child: _wrapPage(
                          wide
                              ? _WideLayout(
                                  card: wrapped,
                                  showTagline: showTagline,
                                  wordmarkAnimation: wordmarkAnimation,
                                )
                              : _NarrowLayout(
                                  card: wrapped,
                                  wordmarkAnimation: wordmarkAnimation,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Deeper than the app's own primaryGradient: this is a full page of colour
/// rather than a band behind a title, and the darker foot is what keeps the
/// white card legible where the two meet.
const LinearGradient _authGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF2633C5), Color(0xFF232C93), Color(0xFF1B2593)],
);

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.card, this.wordmarkAnimation});

  final Widget card;
  final Widget Function(Widget child)? wordmarkAnimation;

  @override
  Widget build(BuildContext context) {
    const mark = AuthWordmark();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppTheme.space8),
        wordmarkAnimation?.call(mark) ?? mark,
        const SizedBox(height: 30),
        card,
        const SizedBox(height: AppTheme.space8),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.card,
    required this.showTagline,
    this.wordmarkAnimation,
  });

  final Widget card;
  final bool showTagline;
  final Widget Function(Widget child)? wordmarkAnimation;

  @override
  Widget build(BuildContext context) {
    const mark = AuthWordmark(alignStart: true);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: AppTheme.space8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                wordmarkAnimation?.call(mark) ?? mark,
                if (showTagline) ...[
                  const SizedBox(height: AppTheme.space8),
                  const _Highlights(),
                ],
              ],
            ),
          ),
        ),
        // Fixed rather than flexible: a form reads best at a constant width,
        // and letting it grow with the window would stretch the fields to a
        // length no one wants to type across.
        SizedBox(width: 440, child: card),
      ],
    );
  }
}

/// The three things the app does, as a short list beside the form.
class _Highlights extends StatelessWidget {
  const _Highlights();

  static const _items = <(IconData, String, String)>[
    (
      Icons.receipt_long_rounded,
      'Billing and receipts',
      'Generate bills, record payments, track defaulters.',
    ),
    (
      Icons.account_balance_wallet_rounded,
      'Accounts',
      'Cashbook, ledgers, expenses and vendor bills.',
    ),
    (
      Icons.groups_rounded,
      'Community',
      'Notices, helpdesk, visitors and facility bookings.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (icon, title, body) in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Icon(icon, color: AppTheme.white, size: 20),
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The mark and product name, over the gradient.
class AuthWordmark extends StatelessWidget {
  const AuthWordmark({super.key, this.alignStart = false});

  /// Left-aligned in the wide layout's brand panel, centred above the card on
  /// a phone.
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final cross = alignStart
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;

    return Column(
      crossAxisAlignment: cross,
      children: [
        Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(
            Icons.apartment_rounded,
            color: AppTheme.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 18),
        // ShaderMask so the type fades from white to a softer white down its
        // height rather than sitting flat on the gradient.
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Colors.white70],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: const Text(
            'SECRETARY',
            style: TextStyle(
              fontSize: 40,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Run your society, simply',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// The white panel the form sits in.
class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.title,
    required this.child,
    this.eyebrow,
    this.onBack,
  });

  /// The line above the title — 'Welcome back,' or similar.
  final String? eyebrow;
  final String title;
  final Widget child;

  /// Shows a back affordance in the card's header. The reset screen uses it
  /// instead of an AppBar, which would have meant a bar across the gradient.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          const BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
          // A faint light from above, so the card lifts off the gradient
          // rather than sitting on it.
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space2),
              child: _BackLink(onTap: onBack!),
            ),
          if (eyebrow != null) ...[
            Text(
              eyebrow!,
              style: AppTheme.body1.copyWith(color: AppTheme.lightText),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            title,
            style: AppTheme.headline.copyWith(
              fontSize: 24,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          child,
        ],
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Back to sign in',
                style: AppTheme.body2.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The soft-well text field both auth screens use.
///
/// Deliberately not the app-wide outlined input: on a white card floating over
/// a saturated gradient, a filled well reads as somewhere to type, where an
/// outline competes with the card's own edge.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    required this.hint,
    required this.validator,
    this.autofill,
    this.obscure = false,
    this.suffix,
    this.onSubmitted,
    this.keyboardType,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final String? Function(String?) validator;
  final List<String>? autofill;
  final bool obscure;
  final Widget? suffix;
  final void Function(String)? onSubmitted;
  final TextInputType? keyboardType;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.body2.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          autocorrect: false,
          autofocus: autofocus,
          autofillHints: autofill,
          keyboardType: keyboardType,
          onFieldSubmitted: onSubmitted,
          textInputAction: onSubmitted == null
              ? TextInputAction.next
              : TextInputAction.done,
          style: AppTheme.body1.copyWith(
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppTheme.deactivatedText,
              fontSize: 15,
            ),
            filled: true,
            fillColor: AppTheme.background,
            prefixIcon: Icon(icon, size: 20, color: AppTheme.lightText),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: _well(AppTheme.border),
            enabledBorder: _well(AppTheme.border),
            focusedBorder: _well(AppTheme.primary, width: 1.4),
            errorBorder: _well(AppTheme.error),
            focusedErrorBorder: _well(AppTheme.error, width: 1.4),
          ),
          validator: validator,
        ),
      ],
    );
  }

  static OutlineInputBorder _well(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// The full-width primary action at the foot of an auth card.
class AuthSubmit extends StatelessWidget {
  const AuthSubmit({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryDark,
          foregroundColor: AppTheme.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: busy
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppTheme.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

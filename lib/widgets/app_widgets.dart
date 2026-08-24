import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/responsive.dart';
import '../domain/models/json_utils.dart';
import '../presentation/viewModels/list_state.dart';

// ── Formatting ───────────────────────────────────────────────────────────

final _money = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);
final _moneyFlat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);
final _compactMoney = NumberFormat.compactCurrency(
  locale: 'en_IN',
  symbol: '₹',
);
final _dayMonth = DateFormat('dd MMM yyyy');
final _shortDate = DateFormat('dd MMM');

String money(dynamic v) => _money.format(asDoubleOr(v));

/// No paise. For headline figures, where the decimals are noise.
String moneyFlat(dynamic v) => _moneyFlat.format(asDoubleOr(v));

String compactMoney(dynamic v) => _compactMoney.format(asDoubleOr(v));

String prettyDate(dynamic v) {
  final d = asDate(v);
  return d == null ? '—' : _dayMonth.format(d);
}

String shortDate(dynamic v) {
  final d = asDate(v);
  return d == null ? '—' : _shortDate.format(d);
}

/// "today" / "3 days ago" / a date once it is old enough that the count stops
/// meaning anything.
String relativeDate(dynamic v) {
  final d = asDate(v);
  if (d == null) return '—';

  final now = DateTime.now();
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(d.year, d.month, d.day)).inDays;

  if (days == 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days > 1 && days < 7) return '$days days ago';
  if (days < 0) return _dayMonth.format(d);
  return _dayMonth.format(d);
}

/// The first non-empty value among [keys].
///
/// Stored procedures are not consistent about column names — a flat is
/// `flat_no` on one result and `unit_no` on another — so screens ask for every
/// spelling they know rather than picking one and rendering blanks.
String? pick(Map<String, dynamic> row, List<String> keys) {
  for (final k in keys) {
    final v = row[k];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString();
  }
  return null;
}

int? pickInt(Map<String, dynamic> row, List<String> keys) {
  for (final k in keys) {
    final v = asInt(row[k]);
    if (v != null) return v;
  }
  return null;
}

/// A stable accent for a name, so the same resident keeps the same avatar
/// colour across screens.
Color accentFor(String? seed) {
  if (seed == null || seed.isEmpty) return AppTheme.primary;
  final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
  return AppTheme.chartSeries[hash % AppTheme.chartSeries.length];
}

String initialsOf(String? name) {
  final parts = (name ?? '')
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty && RegExp(r'[A-Za-z0-9]').hasMatch(p))
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

// ── Surfaces ─────────────────────────────────────────────────────────────

/// A card. Keeps radius, border, shadow and padding identical everywhere.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppTheme.space4),
    this.margin = const EdgeInsets.only(bottom: AppTheme.space3),
    this.accent,
    this.elevated = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  /// Draws a coloured spine down the leading edge — used to mark a row's
  /// state without spending a whole chip on it.
  final Color? accent;

  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusMd);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: radius,
        border: Border.all(color: AppTheme.border),
        boxShadow: elevated ? AppTheme.shadowSm : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: accent == null
              ? Padding(padding: padding, child: child)
              // IntrinsicHeight is what lets the spine match the card's height:
              // CrossAxisAlignment.stretch alone leaves the Row's height
              // unbounded, which is an error inside a vertical list. It is only
              // paid for when a spine is actually asked for.
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 4, color: accent),
                      Expanded(
                        child: Padding(padding: padding, child: child),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// A panel with the brand gradient — the hero at the top of a screen.
class GradientPanel extends StatelessWidget {
  const GradientPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.space5),
    this.gradient = AppTheme.heroGradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        // Take the glow from the gradient's own end colour, so a crimson panel
        // does not sit on a blue shadow.
        boxShadow: AppTheme.glow(
          gradient.colors.isEmpty ? AppTheme.primary : gradient.colors.last,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Two soft circles bleeding off the corners give the panel some
          // depth without an image asset.
          Positioned(
            right: -40,
            top: -50,
            child: _Blob(size: 150, opacity: 0.10),
          ),
          Positioned(
            left: -30,
            bottom: -60,
            child: _Blob(size: 130, opacity: 0.07),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Headings ─────────────────────────────────────────────────────────────

/// A section heading with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.title.copyWith(fontSize: 17)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTheme.caption),
                ],
              ],
            ),
          ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel ?? 'View all'),
            ),
        ],
      ),
    );
  }
}

// ── Stats ────────────────────────────────────────────────────────────────

/// A labelled figure — the unit dashboards and list headers are built from.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.trend,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  /// A short qualifier under the figure — "3 overdue", "this month".
  final String? trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            // The tile is given a fixed aspect ratio by the grid around it, so
            // its content has to survive being a few pixels short rather than
            // overflowing — an overflow here aborts layout for the whole list.
            // FittedBox scales the column down instead, and the text lines are
            // each capped at one line so scaling stays gentle.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceFor(color),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                        child: Icon(icon, size: 17, color: color),
                      ),
                      if (onTap != null) ...[
                        const SizedBox(width: AppTheme.space2),
                        const Icon(
                          Icons.arrow_outward_rounded,
                          size: 15,
                          color: AppTheme.deactivatedText,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppTheme.space3),
                  Text(value, maxLines: 1, style: AppTheme.numeral),
                  const SizedBox(height: 2),
                  Text(label, maxLines: 1, style: AppTheme.caption),
                  if (trend != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      trend!,
                      maxLines: 1,
                      style: AppTheme.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A figure on a gradient panel, where the text must be white.
class HeroStat extends StatelessWidget {
  const HeroStat({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space3,
        vertical: AppTheme.space3,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm + 2),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: AppTheme.onGradientMuted),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onGradientMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: AppTheme.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chips & avatars ──────────────────────────────────────────────────────

/// A short status word, coloured by meaning.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.onSurface = false,
  });

  final String label;
  final Color color;
  final IconData? icon;

  /// Set when the chip sits on a coloured panel, where the usual tint would
  /// disappear — it switches to a translucent white plate instead.
  final bool onSurface;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: onSurface
            ? Colors.white.withValues(alpha: 0.18)
            : AppTheme.surfaceFor(color),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: onSurface ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: onSurface ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Initials in a tinted circle — cheaper than an image and always available.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.size = 40});

  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = accentFor(name);
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(color),
        shape: BoxShape.circle,
      ),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// A rounded plate behind a leading icon.
class IconPlate extends StatelessWidget {
  const IconPlate({
    super.key,
    required this.icon,
    required this.color,
    this.size = 42,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(color),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm + 2),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

// ── Navigation ───────────────────────────────────────────────────────────

/// A row in a hub screen.
class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// A count worth noticing before opening the screen.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          IconPlate(icon: icon, color: color),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppTheme.title.copyWith(fontSize: 15),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: AppTheme.space2),
                      StatusChip(label: badge!, color: color),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: AppTheme.caption),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space2),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.deactivatedText,
            size: 22,
          ),
        ],
      ),
    );
  }
}

// ── State widgets ────────────────────────────────────────────────────────

/// Empty and error states are built on a scrollable so pull-to-refresh still
/// works when there is nothing to scroll.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.deactivatedText;

    // Scrollable so pull-to-refresh still works with nothing to scroll — but
    // `shrinkWrap` with clamping physics so the same widget is also legal
    // inside an outer scrollable, where a greedy viewport would assert on
    // unbounded height.
    return ListView(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: 56,
      ),
      children: [
        Center(
          child: Container(
            height: 78,
            width: 78,
            decoration: BoxDecoration(
              color: AppTheme.surfaceFor(color),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: color),
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTheme.title.copyWith(fontSize: 17),
        ),
        if (message != null) ...[
          const SizedBox(height: AppTheme.space2),
          Text(message!, textAlign: TextAlign.center, style: AppTheme.caption),
        ],
        if (onAction != null) ...[
          const SizedBox(height: AppTheme.space5),
          Center(
            child: SizedBox(
              width: 190,
              child: ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel ?? 'Retry'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A shimmering placeholder block.
///
/// Used instead of a bare spinner on first load: showing the shape of what is
/// coming reads as faster than an empty screen, even at the same latency.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.height = 14,
    this.width,
    this.radius = AppTheme.radiusSm,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final block = Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppTheme.spacer,
              AppTheme.border,
              _controller.value,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );

        // With no explicit width the block wants to fill its parent, which is
        // an error inside a Row or any other horizontally-unbounded parent.
        // Expanding only when the parent offers a bounded width keeps both
        // uses safe.
        if (widget.width != null) return block;

        return LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            width: constraints.maxWidth.isFinite ? constraints.maxWidth : 120,
            child: block,
          ),
        );
      },
    );
  }
}

/// A few skeleton cards, shaped like the list they stand in for.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    // shrinkWrap because this is always rendered *inside* another scrollable
    // (RowsView's list). Without it the inner viewport tries to expand into
    // unbounded height and layout aborts for the whole page.
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        0,
        AppTheme.space2,
        0,
        AppTheme.space5,
      ),
      itemCount: count,
      itemBuilder: (context, index) => const AppCard(
        elevated: false,
        child: Row(
          children: [
            Skeleton(height: 42, width: 42, radius: AppTheme.radiusSm),
            SizedBox(width: AppTheme.space3),
            // Widths are given explicitly rather than left to the Column: a
            // Skeleton with a null width inside a Row has no bounded width to
            // size against, which aborts layout for the list.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Skeleton(height: 13, width: 150),
                  ),
                  SizedBox(height: AppTheme.space2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Skeleton(height: 11, width: 96),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppTheme.space3),
            Skeleton(height: 15, width: 62),
          ],
        ),
      ),
    );
  }
}

/// Renders one named collection: skeletons on cold load, the rows once there
/// are any, an empty state when the server returned none, and the mapped error
/// message on failure.
class RowsView extends StatelessWidget {
  const RowsView({
    super.key,
    required this.rows,
    required this.onRefresh,
    required this.builder,
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyAction,
    this.emptyActionLabel,
    this.constrained = true,
  });

  final Rows rows;
  final Future<void> Function() onRefresh;
  final Widget Function(List<Map<String, dynamic>> items) builder;
  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;
  final VoidCallback? emptyAction;
  final String? emptyActionLabel;

  /// Caps and centres the list on a wide window.
  final bool constrained;

  @override
  Widget build(BuildContext context) {
    final data = rows.value;

    // Show placeholders only when there is nothing cached; during a refresh
    // the existing rows stay on screen.
    final Widget child;
    if (rows.isLoading && data == null) {
      child = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
        children: const [ListSkeleton()],
      );
    } else if (rows.hasError && data == null) {
      child = StateMessage(
        icon: Icons.cloud_off_rounded,
        iconColor: AppTheme.error,
        title: 'Could not load',
        message: errorText(rows.error!),
        actionLabel: 'Try again',
        onAction: onRefresh,
      );
    } else if (data == null || data.items.isEmpty) {
      child = StateMessage(
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
        actionLabel: emptyActionLabel,
        onAction: emptyAction,
      );
    } else {
      child = builder(data.items);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      child: constrained ? PageConstraints(padded: false, child: child) : child,
    );
  }
}

// ── Inputs ───────────────────────────────────────────────────────────────

/// One choice in an [AppDropdown].
class AppOption<T> {
  const AppOption(this.value, this.label, {this.icon});

  final T value;
  final String label;

  /// Optional leading glyph, for menus where the choices are kinds of thing
  /// (payment modes, visitor types) rather than plain values.
  final IconData? icon;
}

/// A dropdown that matches the rest of the app.
///
/// DropdownButtonFormField styles its *field* from inputDecorationTheme like
/// any other input, but the menu it drops is not themable: it paints with
/// `canvasColor`, square corners and Material's default elevation, because it
/// predates DropdownMenuThemeData and does not read it. Worse, it gives the
/// selected row a flat grey band and pads every row to 48pt, so a year picker
/// opened as a tall grey-striped list that looked nothing like the app.
///
/// So the items are built here rather than passed in raw: each row is drawn
/// with the app's own selected state — a tinted pill and a check — and the
/// menu's colour, corners and elevation are set per widget, which is the only
/// place Material allows it.
///
/// `menuMaxHeight` matters on the month picker: twelve items otherwise open a
/// menu taller than a phone, which Material then anchors awkwardly over the
/// field instead of below it.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.label,
    this.hint,
    this.icon,
    this.helperText,
    this.validator,
    this.isDense = true,
    this.menuMaxHeight = 340,
    this.menuWidth,
  });

  final T? value;
  final List<AppOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final IconData? icon;
  final String? helperText;

  /// Form validation, for the dropdowns that sit inside a Form and must be
  /// answered before it submits.
  final String? Function(T?)? validator;

  /// Dense for filter bars, full height for form fields — a filter sits in a
  /// row of its own and wants to be compact, a form field lines up with the
  /// text fields above and below it.
  final bool isDense;

  final double menuMaxHeight;

  /// How wide the dropped menu is, leaving the field itself full width.
  ///
  /// Material defaults the menu to the field's own width, which is right when
  /// the labels are long (a flat and its owner's name) but leaves a list of
  /// years or months as a mostly-empty column spanning the whole field.
  ///
  /// DropdownButtonFormField cannot do this — it builds a private
  /// `DropdownButton._formField` and never forwards `menuWidth` — so setting
  /// this switches to a hand-built FormField wrapping a plain DropdownButton,
  /// which does expose it. The field looks identical either way; the same
  /// InputDecoration draws it.
  final double? menuWidth;

  @override
  Widget build(BuildContext context) {
    return menuWidth == null ? _buildField() : _buildNarrowMenuField(context);
  }

  Widget _buildField() {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      onChanged: onChanged,
      validator: validator,
      menuMaxHeight: menuMaxHeight,
      dropdownColor: AppTheme.white,
      // radiusLg, matching the cards: the menu is a floating surface of the
      // same family, and radiusMd left it looking closer to a raw popup.
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      // 2, not Material's 8. A heavy drop shadow under a white sheet on a
      // near-white page reads as a dialog; this is a menu.
      elevation: 2,
      // Left at Material's default. DropdownButtonFormField asserts
      // `itemHeight == null || itemHeight >= kMinInteractiveDimension`, so 48
      // is the floor and there is no tightening the rows this way — the row
      // is made to look less airy by insetting its own plate instead.
      style: AppTheme.body2,
      icon: const Icon(Icons.expand_more_rounded, size: 20),
      iconEnabledColor: AppTheme.lightText,

      selectedItemBuilder: _selectedItemBuilder,
      items: _menuItems(),
      decoration: _decoration(),
    );
  }

  /// The same control, but with the menu narrower than the field.
  ///
  /// Hand-rolled because DropdownButtonFormField will not forward menuWidth.
  /// A FormField supplies the validation and error plumbing it would have
  /// given us; InputDecorator draws the identical field; the plain
  /// DropdownButton inside is the one Material lets us size the menu on.
  Widget _buildNarrowMenuField(BuildContext context) {
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        // Keep the FormField's copy in step when the parent rebuilds with a
        // new value — otherwise validation reads whatever was first chosen.
        if (field.value != value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (field.mounted) field.didChange(value);
          });
        }

        return InputDecorator(
          decoration: _decoration().copyWith(errorText: field.errorText),
          isEmpty: value == null && hint != null,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: isDense,
              onChanged: onChanged == null
                  ? null
                  : (v) {
                      field.didChange(v);
                      onChanged!(v);
                    },
              menuMaxHeight: menuMaxHeight,
              menuWidth: menuWidth,
              dropdownColor: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              elevation: 2,
              style: AppTheme.body2,
              icon: const Icon(Icons.expand_more_rounded, size: 20),
              iconEnabledColor: AppTheme.lightText,
              selectedItemBuilder: _selectedItemBuilder,
              items: _menuItems(),
            ),
          ),
        );
      },
    );
  }

  /// What the *field* shows once a choice is made. Without this the field
  /// would render the menu row — pill, check and all — inside the input.
  List<Widget> _selectedItemBuilder(BuildContext context) => [
    for (final option in options)
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          option.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.body2.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
  ];

  List<DropdownMenuItem<T>> _menuItems() => [
    for (final option in options)
      DropdownMenuItem<T>(
        value: option.value,
        child: _MenuRow(
          label: option.label,
          icon: option.icon,
          selected: option.value == value,
        ),
      ),
  ];

  InputDecoration _decoration() {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      isDense: isDense,
      prefixIcon: icon == null ? null : Icon(icon, size: 18),
      // Only override the theme's padding when dense; a form field should
      // keep the same height as the TextFormFields it sits beside.
      contentPadding: isDense
          ? const EdgeInsets.symmetric(
              horizontal: AppTheme.space4,
              vertical: AppTheme.space3,
            )
          : null,
    );
  }
}

/// One row inside an [AppDropdown]'s menu.
///
/// Material would otherwise mark the current choice with a flat grey band
/// across the full width of the menu — the thing that made the year picker
/// look unfinished. This gives it the same treatment a selected chip gets
/// elsewhere in the app: a tinted rounded plate, the label in the primary
/// colour, and a check at the trailing edge so the state survives being read
/// without colour.
class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.label, required this.selected, this.icon});

  final String label;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Material fixes the row at 48pt (kMinInteractiveDimension) and asserts
    // against anything lower, so the height cannot be tightened. What is
    // controlled is the plate inside it: full width, generously padded, with
    // the label and the check at opposite ends.
    //
    // The plate deliberately fills the row rather than shrink-wrapping the
    // label. Sized to its text it came out as a small tab crammed against the
    // check — narrow menus made that worse, because there the text is most of
    // the width already.
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space2,
        vertical: 3,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space3),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: selected ? AppTheme.primarySurface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 17,
              color: selected ? AppTheme.primary : AppTheme.lightText,
            ),
            const SizedBox(width: AppTheme.space3),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body2.copyWith(
                fontSize: 14.5,
                height: 1.2,
                // darkerText, not the old lightText grey: the unselected
                // months were washed out enough to read as disabled.
                color: selected ? AppTheme.primary : AppTheme.darkerText,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ),
          // The check keeps its slot on every row — transparent when not
          // current — so labels do not shift as the selection moves. The gap
          // before it is fixed, so it never crowds a long label.
          const SizedBox(width: AppTheme.space3),
          Icon(
            Icons.check_rounded,
            size: 18,
            color: selected ? AppTheme.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

/// A search field. The debounce timer is owned by the caller's State so it can
/// be cancelled on dispose.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppTheme.body2,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space4,
          vertical: AppTheme.space3,
        ),
      ),
    );
  }
}

/// A search field in a sticky bar above a list.
class SearchBarArea extends StatelessWidget {
  const SearchBarArea({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search',
    this.trailing,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return PageConstraints(
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppTheme.space3,
          bottom: AppTheme.space2,
        ),
        child: Row(
          children: [
            Expanded(
              child: SearchField(
                controller: controller,
                onChanged: onChanged,
                hint: hint,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppTheme.space2),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// ── Status colour ────────────────────────────────────────────────────────

/// Colour for a free-text status. Falls back to grey for anything
/// unrecognised rather than guessing.
Color statusColor(String? status) {
  switch (status?.toLowerCase().trim()) {
    case 'paid':
    case 'closed':
    case 'resolved':
    case 'approved':
    case 'cleared':
    case 'deposited':
    case 'active':
    case 'completed':
      return AppTheme.success;
    case 'pending':
    case 'open':
    case 'opened':
    case 'partly paid':
    case 'partially paid':
    case 'in progress':
    case 'waiting':
    case 'bill generated':
      return AppTheme.warning;
    case 'unpaid':
    case 'overdue':
    case 'rejected':
    case 'cancelled':
    case 'returned':
    case 'bounced':
      return AppTheme.error;
    default:
      return AppTheme.lightText;
  }
}

// ── Feedback ─────────────────────────────────────────────────────────────

/// Shows the ViewModel's command result once, then clears it so a rebuild does
/// not show the same snackbar again.
void listenForFeedback(
  WidgetRef ref,
  BuildContext context,
  StateNotifierProvider<ListViewModel, ListState> provider,
) {
  ref.listen<ListState>(provider, (previous, next) {
    if (next.message != null && next.message != previous?.message) {
      showAppSnack(context, next.message!, success: true);
      ref.read(provider.notifier).clearMessage();
    }

    if (next.error != null && next.error != previous?.error) {
      showAppSnack(context, next.error!, success: false);
      ref.read(provider.notifier).clearError();
    }
  });
}

/// One snackbar style for the whole app, with an icon carrying the outcome so
/// it reads without relying on colour alone.
void showAppSnack(
  BuildContext context,
  String message, {
  required bool success,
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: success ? AppTheme.success : AppTheme.error,
        content: Row(
          children: [
            Icon(
              success
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
              size: 19,
            ),
            const SizedBox(width: AppTheme.space3),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

/// A confirm dialog. Returns true only on an explicit confirm.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        destructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
        color: destructive ? AppTheme.error : AppTheme.primary,
        size: 28,
      ),
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppTheme.space5,
        0,
        AppTheme.space5,
        AppTheme.space4,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: destructive ? AppTheme.error : AppTheme.primary,
            minimumSize: const Size(112, 44),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

/// Wraps a bottom sheet's content: grab handle, rounded top, keyboard inset
/// and a draggable scroll area.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.initialSize = 0.86,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final double initialSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: initialSize,
        maxChildSize: 0.95,
        minChildSize: 0.45,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: AppTheme.space3),
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space5,
                  AppTheme.space5,
                  AppTheme.space5,
                  AppTheme.space8,
                ),
                children: [
                  Text(title, style: AppTheme.headline.copyWith(fontSize: 21)),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppTheme.space1),
                    Text(subtitle!, style: AppTheme.caption),
                  ],
                  const SizedBox(height: AppTheme.space5),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An ElevatedButton that swaps its label for a spinner while busy.
class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.busy,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppTheme.white,
            ),
          )
        : Text(label);

    if (icon != null && !busy) {
      return ElevatedButton.icon(
        onPressed: busy ? null : onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label),
      );
    }

    return ElevatedButton(onPressed: busy ? null : onPressed, child: child);
  }
}

/// A number that counts up to its value when it first appears, and animates
/// between values on refresh.
///
/// The duration is fixed rather than scaled to the magnitude: a secretary
/// reads this figure repeatedly, and a count that runs longer because the
/// number happens to be larger reads as the app being slow.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final double value;
  final String Function(double) formatter;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animated, child) =>
          Text(formatter(animated), maxLines: 1, style: style),
    );
  }
}

/// A compact action on the dashboard — icon over a label, in a tinted plate.
class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.space3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceFor(color),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(icon, size: 21, color: color),
              ),
              const SizedBox(height: AppTheme.space2),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: AppTheme.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

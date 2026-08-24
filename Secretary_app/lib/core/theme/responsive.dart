import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Layout breakpoints.
///
/// The app runs on phones and in a browser, and a list laid out for a 390pt
/// phone becomes a row of text stretched across 1600pt of desktop. These are
/// the three widths the layouts actually branch on — anything finer would be
/// guesswork about devices nobody has.
enum FormFactor { phone, tablet, desktop }

class Breakpoints {
  Breakpoints._();

  static const double tablet = 720;
  static const double desktop = 1080;

  /// The widest a column of body content is allowed to get. Past roughly this,
  /// lines are too long to track back to the start comfortably.
  static const double readableWidth = 1180;

  static FormFactor of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktop) return FormFactor.desktop;
    if (width >= tablet) return FormFactor.tablet;
    return FormFactor.phone;
  }

  static bool isPhone(BuildContext context) => of(context) == FormFactor.phone;

  static bool isDesktop(BuildContext context) =>
      of(context) == FormFactor.desktop;

  /// True where a side rail replaces the bottom bar.
  static bool useRail(BuildContext context) => of(context) != FormFactor.phone;

  /// Columns for a grid of stat tiles or hub entries.
  static int gridColumns(BuildContext context, {int phone = 2}) {
    switch (of(context)) {
      case FormFactor.phone:
        return phone;
      case FormFactor.tablet:
        return 3;
      case FormFactor.desktop:
        return 4;
    }
  }

  /// Page padding. Tighter on a phone, where every point of width counts.
  static EdgeInsets pagePadding(BuildContext context) {
    switch (of(context)) {
      case FormFactor.phone:
        return const EdgeInsets.symmetric(horizontal: AppTheme.space4);
      case FormFactor.tablet:
        return const EdgeInsets.symmetric(horizontal: AppTheme.space6);
      case FormFactor.desktop:
        return const EdgeInsets.symmetric(horizontal: AppTheme.space8);
    }
  }
}

/// Centres and caps its child so content does not stretch across a wide
/// window, and applies the form factor's page padding.
class PageConstraints extends StatelessWidget {
  const PageConstraints({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.readableWidth,
    this.padded = true,
  });

  final Widget child;
  final double maxWidth;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final content = padded
        ? Padding(padding: Breakpoints.pagePadding(context), child: child)
        : child;

    // Constrain the width without touching the height.
    //
    // Center (and Align) size themselves to the child on *both* axes, which
    // hands an unbounded height down — fatal when the child is a scrollable,
    // as it is whenever this wraps a list. LayoutBuilder passes the incoming
    // height constraint straight through, so the child keeps whatever bound
    // its parent gave it and only the width is capped.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final capped = width > maxWidth ? maxWidth : width;
        final inset = (width - capped) / 2;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: content,
        );
      },
    );
  }
}

/// A responsive grid that keeps a target tile width rather than a fixed column
/// count, so tiles stay legible at every size instead of being squeezed.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 190,
    this.aspectRatio = 1.45,
    this.spacing = AppTheme.space3,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double aspectRatio;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Inside a horizontally-unbounded parent maxWidth is infinite, and
        // `infinity ~/ minTileWidth` is not a usable column count — fall back
        // to the screen width, which is bounded.
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        // Never more columns than there are children, and never fewer than
        // one. Computing the ceiling first matters: clamp(lo, hi) asserts when
        // lo > hi, which is what a single child would produce against a
        // hard-coded minimum of two.
        final maxColumns = children.length.clamp(1, 6);
        final fits = (available / minTileWidth).floor();

        // Two columns is the preferred minimum — a lone full-width stat tile
        // reads as a banner rather than one of a set — but only when there are
        // two children to fill them.
        final columns = fits.clamp(1, maxColumns) < 2
            ? maxColumns.clamp(1, 2)
            : fits.clamp(1, maxColumns);

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: aspectRatio,
          children: children,
        );
      },
    );
  }
}

/// Lays children out in one column on a phone and side by side above the
/// tablet breakpoint — the shape most of these screens want for a chart beside
/// a summary.
class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({
    super.key,
    required this.children,
    this.spacing = AppTheme.space4,
    this.flex,
  });

  final List<Widget> children;
  final double spacing;

  /// Relative widths when side by side. Defaults to equal.
  final List<int>? flex;

  @override
  Widget build(BuildContext context) {
    if (Breakpoints.isPhone(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(
            flex: flex != null && i < flex!.length ? flex![i] : 1,
            child: children[i],
          ),
        ],
      ],
    );
  }
}

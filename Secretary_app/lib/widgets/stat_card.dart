import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A solid-coloured figure card — the pair of stats inside the dashboard hero.
///
/// The colour is the point: green for money collected, red for money still
/// owed. That distinction is what a secretary reads first, and it only works
/// if the two cards differ from each other and from the white card holding
/// them.
///
/// Filled rather than frosted. An earlier version blurred the backdrop, but
/// on a white card there is nothing behind it worth blurring — the effect cost
/// a saveLayer and looked like flat translucency.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        // The glow takes the card's own hue — a grey shadow under a coloured
        // card reads as dirt.
        boxShadow: AppTheme.glow(
          gradient.colors.isEmpty ? AppTheme.primary : gradient.colors.last,
          opacity: 0.22,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space4,
              vertical: AppTheme.space3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 14, color: AppTheme.onGradientMuted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onGradientMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: AppTheme.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

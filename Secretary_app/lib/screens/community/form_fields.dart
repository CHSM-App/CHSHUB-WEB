import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

/// A titled card grouping a few related fields.
///
/// A phone reads a long textarea followed by two pickers as one undivided
/// block, so the announcement forms group their fields into cards — what the
/// item says, then when it happens — rather than one run of fields. Shared by
/// the notice, meeting and event forms so the three agree on the shape.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space4,
        AppTheme.space3,
        AppTheme.space4,
        AppTheme.space4,
      ),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.overline.copyWith(color: AppTheme.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          ...children,
        ],
      ),
    );
  }
}

/// A read-only field that opens a picker when tapped.
///
/// Styled as a text field so a form of typed fields and picked ones reads as
/// one form. [onClear] adds a clear button, for a value whose picker has no
/// way to express "unset" — a date picker cannot return "no date".
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: onClear == null
              ? const Icon(Icons.chevron_right_rounded, size: 20)
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Clear',
                  onPressed: onClear,
                ),
        ),
        child: Text(value, style: AppTheme.body2),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';

/// A collapsible profile section that expands/collapses smoothly on tap.
///
/// The body is removed from the tree while collapsed (so it is never laid out)
/// and its height is animated with [AnimatedSize]; the chevron rotates in sync.
class AccordionSection extends StatefulWidget {
  /// Creates an accordion section.
  const AccordionSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.initiallyExpanded = false,
    this.headerKey,
  });

  /// Section title shown in the always-visible header.
  final String title;

  /// Optional supporting line under the title.
  final String? subtitle;

  /// Optional leading glyph.
  final IconData? icon;

  /// Whether the section starts expanded.
  final bool initiallyExpanded;

  /// Key attached to the tappable header (for tests).
  final Key? headerKey;

  /// The collapsible body.
  final Widget child;

  @override
  State<AccordionSection> createState() => _AccordionSectionState();
}

class _AccordionSectionState extends State<AccordionSection> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: widget.headerKey,
            onTap: _toggle,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: AppColors.primary300, size: 22),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(widget.title),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          AppCaption(widget.subtitle!),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: const Icon(
                      Icons.expand_more,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/domain/body_projection/body_diagram_view_model.dart';
import '../../../core/domain/body_projection/segment_status.dart';
import '../../../core/theme/app_theme.dart';
import 'body_segment_palette.dart';

/// A flat, bordered blueprint annotation chip showing a label and a live value.
///
/// The chip is semantically a button, exposes its label/value to screen
/// readers and keeps a minimum 48x48 touch target (also enforced by the
/// placement math).
class BodyCalloutChip extends StatelessWidget {
  /// Creates a callout chip for [callout] in the colour of [status].
  const BodyCalloutChip({
    super.key,
    required this.callout,
    required this.status,
    this.onTap,
  });

  /// The annotation content.
  final BodyCallout callout;

  /// The status driving the border colour.
  final SegmentStatus status;

  /// Invoked when the chip is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = BodySegmentPalette.strokeFor(status);
    return Semantics(
      label: callout.label,
      value: callout.value,
      button: true,
      container: true,
      child: Material(
        color: AppColors.surface900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: borderColor, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    callout.label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textLow,
                    ),
                  ),
                  Text(
                    callout.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: borderColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

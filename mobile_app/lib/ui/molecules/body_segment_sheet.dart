import 'package:flutter/material.dart';

import '../../core/domain/body_projection/body_segment.dart';
import '../../core/state/body_detail_controller.dart';
import 'body_exercise_detail_sheet.dart';
import 'body_food_detail_sheet.dart';

/// Opens the detail popup for [segment]: the food list for the abdomen and the
/// exercise/gap advice sheet for every muscle segment.
///
/// Both the segment body and its callout route through this single entry point.
Future<void> showBodySegmentDetailSheet(
  BuildContext context, {
  required BodySegment segment,
  required BodyDetailController controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => segment.isAbdomen
        ? BodyFoodDetailSheet(controller: controller)
        : BodyExerciseDetailSheet(controller: controller, segment: segment),
  );
}

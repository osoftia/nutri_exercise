import 'package:flutter/material.dart';

import '../../core/domain/body_projection/body_segment.dart';
import '../../core/state/body_detail_controller.dart';
import '../../core/state/clinical_profile_controller.dart';
import 'body_exercise_detail_sheet.dart';
import 'body_food_detail_sheet.dart';

/// Opens the daily nutrition summary (the abdomen food sheet).
///
/// Mirrors [showBodySegmentDetailSheet] for the abdomen segment, so the
/// Nutrition tab and the blueprint callout share one surface.
Future<void> showNutritionSummarySheet(
  BuildContext context, {
  required BodyDetailController controller,
  ClinicalProfileController? clinicalProfileController,
}) {
  return showBodySegmentDetailSheet(
    context,
    segment: BodySegment.abdomen,
    controller: controller,
    clinicalProfileController: clinicalProfileController,
  );
}

/// Opens the detail popup for [segment]: the food list for the abdomen and the
/// exercise/gap advice sheet for every muscle segment.
///
/// Both the segment body and its callout route through this single entry point.
Future<void> showBodySegmentDetailSheet(
  BuildContext context, {
  required BodySegment segment,
  required BodyDetailController controller,
  ClinicalProfileController? clinicalProfileController,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => segment.isAbdomen
        ? BodyFoodDetailSheet(
            controller: controller,
            clinicalProfileController: clinicalProfileController,
          )
        : BodyExerciseDetailSheet(controller: controller, segment: segment),
  );
}

import 'package:flutter/material.dart';

import '../state/muscle_tamagotchi_state.dart';

/// Maps each tamagotchi group to the visual region ids (from
/// `muscle_vectors.dart`) it drives.
const Map<MuscleTamagotchiGroup, List<String>> tamagotchiGroupToRegions = {
  MuscleTamagotchiGroup.core: ['abs', 'back'],
  MuscleTamagotchiGroup.arms: ['arms', 'shoulders'],
  MuscleTamagotchiGroup.chest: ['chest'],
  MuscleTamagotchiGroup.legs: ['legs'],
};

/// Reverse lookup: the tamagotchi group that owns [regionId], if any.
MuscleTamagotchiGroup? tamagotchiGroupForRegion(String regionId) {
  for (final entry in tamagotchiGroupToRegions.entries) {
    if (entry.value.contains(regionId)) return entry.key;
  }
  return null;
}

/// Heatmap colour for a tier (C = red … S = gold).
Color tierColor(MuscleTier tier) {
  switch (tier) {
    case MuscleTier.c:
      return const Color(0xFFEF4444); // Red
    case MuscleTier.b:
      return const Color(0xFFEAB308); // Yellow
    case MuscleTier.a:
      return const Color(0xFF22C55E); // Green
    case MuscleTier.s:
      return const Color(0xFFFFD700); // Gold
  }
}

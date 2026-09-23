import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/state/muscle_tamagotchi_state.dart';
import 'body_map_geometry.dart';
import 'body_map_painter.dart';

/// Re-exported geometry/decision helpers so existing importers and tests keep
/// resolving `scaleForMass`, `coreRenderScale`, `selectionBaseColor`, etc.
export 'body_map_geometry.dart';
export 'body_map_painter.dart' show muscleAt;

class InteractiveBodyMap extends StatefulWidget {
  const InteractiveBodyMap({
    super.key,
    this.selectedMuscle,
    this.onMuscleSelected,
    this.activeRegions = const {},
    this.tamagotchiState,
    this.bodyWidthFactor = 1.0,
    this.animate = true,
  });

  final String? selectedMuscle;
  final ValueChanged<String?>? onMuscleSelected;
  final Set<String> activeRegions;
  final MuscleTamagotchiState? tamagotchiState;

  /// Baseline body width factor (from the user's BMI); `1.0` is neutral.
  final double bodyWidthFactor;

  /// Whether the selection glow animates. Disable for static captures (e.g.
  /// the hidden social share card) to avoid perpetual ticking.
  final bool animate;

  @override
  State<InteractiveBodyMap> createState() => _InteractiveBodyMapState();
}

class _InteractiveBodyMapState extends State<InteractiveBodyMap>
    with TickerProviderStateMixin {
  late String? _selected;
  late final AnimationController _glowController;
  late final AnimationController _bloatController;
  double _glow = 0;
  double _bloat = 0;
  bool _coreBloating = false;
  double _lastFullness = 0.0;
  MuscleTamagotchiState? _tamagotchiState;
  int _revision = 0;
  int _lastSeenMealCount = 0;
  bool _foodFlash = false;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedMuscle;
    _glowController = AnimationController(vsync: this, duration: kGlowDuration);
    if (widget.animate) {
      _glowController.repeat();
    }
    _glowController.addListener(() {
      setState(() => _glow = _glowController.value);
    });
    _bloatController = AnimationController(vsync: this, duration: kBloatDuration)
      ..addListener(() {
        setState(() => _bloat = _bloatController.value);
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _tamagotchiState?.settleCore();
        }
      });
    _listenToTamagotchi();
  }

  void _listenToTamagotchi() {
    _tamagotchiState?.removeListener(_onTamagotchiChanged);
    _tamagotchiState = widget.tamagotchiState;
    _tamagotchiState?.addListener(_onTamagotchiChanged);
    _lastSeenMealCount = _tamagotchiState?.mealCount ?? 0;
    _syncBloat();
  }

  void _onTamagotchiChanged() {
    setState(() => _revision++);
    _syncBloat();
    _syncFoodFlash();
  }

  /// M35 Task 1: stomach red-flash debug. Every food log bumps
  /// [MuscleTamagotchiState.mealCount]; on a bump the stomach flashes
  /// bright red for [MuscleTamagotchiState.foodFlashDuration], proving the
  /// bloat state → UI re-render path is live.
  void _syncFoodFlash() {
    final meals = _tamagotchiState?.mealCount ?? 0;
    if (meals <= _lastSeenMealCount) return;
    _lastSeenMealCount = meals;
    _flashTimer?.cancel();
    setState(() => _foodFlash = true);
    _flashTimer = Timer(MuscleTamagotchiState.foodFlashDuration, () {
      if (!mounted) return;
      setState(() => _foodFlash = false);
    });
  }

  void _syncBloat() {
    final state = _tamagotchiState;
    final bloat = state?.coreIsBloating ?? false;
    final fullness = state?.coreFullness ?? 0.0;
    if (shouldRestartBloat(
      bloating: bloat,
      fullness: fullness,
      lastFullness: _lastFullness,
      wasBloating: _coreBloating,
    )) {
      _bloatController.forward(from: 0.0);
    }
    _coreBloating = bloat;
    _lastFullness = fullness;
    if (!bloat) {
      _bloat = 0;
    }
  }

  @override
  void didUpdateWidget(InteractiveBodyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMuscle != oldWidget.selectedMuscle) {
      _selected = widget.selectedMuscle;
    }
    if (widget.tamagotchiState != oldWidget.tamagotchiState) {
      _listenToTamagotchi();
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _tamagotchiState?.removeListener(_onTamagotchiChanged);
    _glowController.dispose();
    _bloatController.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details) {
    final size = context.size;
    if (size == null) return;
    final hit = muscleAt(details.localPosition, size);
    if (hit == null) return;
    final next = hit.id == _selected ? null : hit.id;
    setState(() => _selected = next);
    widget.onMuscleSelected?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: kAspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: _handleTap,
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: BodyMapPainter(
                selectedMuscle: _selected,
                glow: _glow,
                activeRegions: widget.activeRegions,
                tamagotchiState: _tamagotchiState,
                revision: _revision,
                bodyWidthFactor: widget.bodyWidthFactor,
                coreBloating: _coreBloating,
                bloat: _bloat,
                foodFlash: _foodFlash,
              ),
            ),
          );
        },
      ),
    );
  }
}


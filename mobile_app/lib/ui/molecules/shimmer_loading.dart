import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    this.lineCount = 4,
    this.lineHeight = 16,
    this.spacing = AppSpacing.lg,
  });

  final int lineCount;
  final double lineHeight;
  final double spacing;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.lineCount; i++) ...[
          if (i > 0) SizedBox(height: widget.spacing),
          _ShimmerLine(
            controller: _controller,
            height: widget.lineHeight,
            widthFactor: const [1.0, 0.7, 0.95, 0.6, 0.85][i % 5],
          ),
        ],
      ],
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({
    required this.controller,
    required this.height,
    required this.widthFactor,
  });

  final AnimationController controller;
  final double height;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: const [
                    AppColors.surface800,
                    AppColors.surface700,
                    AppColors.surface800,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  transform: _SlidingGradientTransform(
                    controller.value * 3 - 3,
                  ),
                ).createShader(bounds);
              },
              child: Container(
                height: height,
                color: AppColors.surface800,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

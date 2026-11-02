import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

class AppSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.inner,
  });

  const AppSkeleton.card({
    super.key,
    this.width = double.infinity,
    this.height = 84.0,
    this.borderRadius = AppRadius.card,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.45, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted.withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

class AppSkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const AppSkeletonList({
    super.key,
    this.count = 4,
    this.itemHeight = 84.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.cardPadCompact),
            child: Row(
              children: [
                const AppSkeleton(width: 40, height: 40, borderRadius: 11),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSkeleton(width: 140, height: 14, borderRadius: 4),
                      const SizedBox(height: 6),
                      AppSkeleton(width: 200, height: 11, borderRadius: 4),
                    ],
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

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Custom Painter for 1px Specular Light-Catching Glass Border
class GlassBorderPainter extends CustomPainter {
  final double strokeWidth;
  final double radius;
  final Gradient gradient;

  const GlassBorderPainter({
    this.strokeWidth = 1.0,
    required this.radius,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = gradient.createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant GlassBorderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gradient != gradient;
  }
}

/// Universal Cross-Platform Liquid Glass Container
/// Replicates Apple iOS / VisionOS liquid glass aesthetic uniformly on iOS, Android, and Web:
/// 1. Highly translucent tinted background
/// 2. Heavy backdrop filter (ImageFilter.blur)
/// 3. Subtle 1px gradient border simulating specular edge light
/// 4. Layered ambient drop shadows for organic physical elevation
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tintColor;
  final Gradient? borderGradient;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.72,
    this.radius = 20.0,
    this.padding,
    this.margin,
    this.tintColor,
    this.borderGradient,
    this.borderWidth = 1.0,
    this.shadows,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTint = tintColor ?? Colors.white.withOpacity(opacity);
    final defaultBorderGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.75), // Top-left specular catch
        Colors.white.withOpacity(0.35), // Mid reflection
        Colors.white.withOpacity(0.12), // Bottom-right shadow fade
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    final effectiveShadows = shadows ?? [
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(0.06),
        blurRadius: 24,
        spreadRadius: -2,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(0.03),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: CustomPaint(
            foregroundPainter: GlassBorderPainter(
              strokeWidth: borderWidth,
              radius: radius,
              gradient: borderGradient ?? defaultBorderGradient,
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: effectiveTint,
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.20),
                    Colors.white.withOpacity(0.04),
                  ],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      );
    }
    return content;
  }
}

/// Floating Liquid Glass Navigation Item Model
class LiquidGlassNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String? badgeText;

  const LiquidGlassNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badgeText,
  });
}

/// Cross-Platform Morphing Liquid Glass Bottom Navigation Bar
/// Floating frosted glass island with smooth animated sliding indicator pill
class LiquidGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidGlassNavItem> items;
  final double blur;
  final EdgeInsetsGeometry margin;

  const LiquidGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.blur = 22.0,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: margin,
        child: LiquidGlassContainer(
          radius: 28.0,
          blur: blur,
          opacity: 0.85,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          shadows: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.09),
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: AppTheme.primaryDark.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / items.length;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Smooth Gliding Active Pill Indicator (Morphing Animation)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    left: currentIndex * itemWidth + 2,
                    width: itemWidth - 4,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryDark, AppTheme.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryDark.withOpacity(0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Interactive Navigation Items Row (Vertical stacking to prevent horizontal clipping)
                  Row(
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final isSelected = index == currentIndex;

                      return Expanded(
                        child: InkWell(
                          onTap: () => onTap(index),
                          borderRadius: BorderRadius.circular(20),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  duration: const Duration(milliseconds: 180),
                                  scale: isSelected ? 1.08 : 1.0,
                                  child: Icon(
                                    isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                                    size: 20,
                                    color: isSelected ? Colors.white : AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppTheme.textMuted,
                                    fontSize: 10.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.visible,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dynamic Scroll-Morphing Liquid Glass App Bar
/// Smoothly morphs from airy spacious header to a compact frosted glass island on scroll
class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget title;
  final List<Widget>? actions;
  final double scrollOffset;
  final double expandedHeight;
  final double collapsedHeight;

  const LiquidGlassAppBar({
    super.key,
    this.leading,
    required this.title,
    this.actions,
    this.scrollOffset = 0.0,
    this.expandedHeight = 64.0,
    this.collapsedHeight = 56.0,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        lerpDouble(expandedHeight, collapsedHeight, (scrollOffset / 100.0).clamp(0.0, 1.0)) ?? expandedHeight,
      );

  @override
  Widget build(BuildContext context) {
    final progress = (scrollOffset / 100.0).clamp(0.0, 1.0);
    final currentHeight = lerpDouble(expandedHeight, collapsedHeight, progress)!;
    final currentRadius = lerpDouble(0.0, 20.0, progress)!;
    final horizontalMargin = lerpDouble(0.0, 12.0, progress)!;
    final blurAmount = lerpDouble(14.0, 24.0, progress)!;
    final bgOpacity = lerpDouble(0.70, 0.88, progress)!;

    return SafeArea(
      bottom: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: progress * 4),
        height: currentHeight,
        child: LiquidGlassContainer(
          radius: currentRadius,
          blur: blurAmount,
          opacity: bgOpacity,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ],
              Expanded(child: title),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Tactile Liquid Glass Button
class LiquidGlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? tintColor;
  final Gradient? borderGradient;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double blur;

  const LiquidGlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.tintColor,
    this.borderGradient,
    this.radius = 14.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.blur = 16.0,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: LiquidGlassContainer(
          radius: widget.radius,
          blur: widget.blur,
          opacity: _isPressed ? 0.85 : 0.70,
          tintColor: widget.tintColor,
          borderGradient: widget.borderGradient,
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}

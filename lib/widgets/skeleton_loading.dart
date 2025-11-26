import 'package:flutter/material.dart';

/// A shimmer loading box widget for skeleton loading effects.
///
/// Use this widget to create placeholder loading animations that match
/// the shape and size of the content being loaded.
///
/// Example:
/// ```dart
/// ShimmerBox(
///   width: 100,
///   height: 20,
///   borderRadius: 4,
/// )
/// ```
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 4,
  });

  /// Width of the shimmer box. Use `double.infinity` for full width.
  final double width;

  /// Height of the shimmer box.
  final double height;

  /// Border radius for rounded corners.
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                colorScheme.surfaceContainerHighest,
                colorScheme.surfaceContainerLow,
                colorScheme.surfaceContainerHighest,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A circular shimmer loading widget, perfect for avatar placeholders.
///
/// Example:
/// ```dart
/// ShimmerCircle(radius: 24)
/// ```
class ShimmerCircle extends StatefulWidget {
  const ShimmerCircle({
    super.key,
    required this.radius,
  });

  /// Radius of the circle.
  final double radius;

  @override
  State<ShimmerCircle> createState() => _ShimmerCircleState();
}

class _ShimmerCircleState extends State<ShimmerCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.radius * 2,
          height: widget.radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                colorScheme.surfaceContainerHighest,
                colorScheme.surfaceContainerLow,
                colorScheme.surfaceContainerHighest,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Pre-built skeleton for a list item with avatar and text lines.
///
/// Useful for loading states in lists showing user/member info.
class SkeletonListItem extends StatelessWidget {
  const SkeletonListItem({
    super.key,
    this.avatarRadius = 24,
    this.titleWidth = 120,
    this.subtitleWidth = 80,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final double avatarRadius;
  final double titleWidth;
  final double subtitleWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          ShimmerCircle(radius: avatarRadius),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: titleWidth,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 6),
                ShimmerBox(
                  width: subtitleWidth,
                  height: 12,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pre-built skeleton for a card with header and content rows.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    this.headerIconSize = 20,
    this.headerTitleWidth = 60,
    this.contentRows = 1,
    this.showDivider = true,
  });

  final double headerIconSize;
  final double headerTitleWidth;
  final int contentRows;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ShimmerBox(
                  width: headerIconSize,
                  height: headerIconSize,
                  borderRadius: 4,
                ),
                const SizedBox(width: 8),
                ShimmerBox(
                  width: headerTitleWidth,
                  height: 16,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          // Content rows
          for (int i = 0; i < contentRows; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  ShimmerBox(
                    width: 34,
                    height: 34,
                    borderRadius: 8,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        width: 50,
                        height: 12,
                        borderRadius: 4,
                      ),
                      const SizedBox(height: 6),
                      ShimmerBox(
                        width: 90,
                        height: 14,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Pre-built skeleton for a members/users list section.
class SkeletonMembersList extends StatelessWidget {
  const SkeletonMembersList({
    super.key,
    this.itemCount = 3,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ShimmerBox(
                  width: 36,
                  height: 36,
                  borderRadius: 10,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(
                      width: 70,
                      height: 16,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 4),
                    ShimmerBox(
                      width: 50,
                      height: 12,
                      borderRadius: 4,
                    ),
                  ],
                ),
                const Spacer(),
                ShimmerBox(
                  width: 24,
                  height: 24,
                  borderRadius: 12,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          // Member items
          for (int i = 0; i < itemCount; i++)
            const SkeletonListItem(
              avatarRadius: 24,
              titleWidth: 120,
              subtitleWidth: 90,
            ),
        ],
      ),
    );
  }
}

/// Pre-built skeleton for a button.
class SkeletonButton extends StatelessWidget {
  const SkeletonButton({
    super.key,
    this.height = 52,
    this.borderRadius = 16,
  });

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: double.infinity,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

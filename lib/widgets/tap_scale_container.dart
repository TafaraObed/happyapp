import 'package:flutter/material.dart';

class TapScaleContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const TapScaleContainer({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.95, // How much to scale down
  });

  @override
  State<TapScaleContainer> createState() => _TapScaleContainerState();
}

class _TapScaleContainerState extends State<TapScaleContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100), // Speed of scale down/up
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    // Use a short delay before reversing to ensure the user sees the tap
    Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
            _controller.reverse();
        }
    });
    widget.onTap?.call(); // Trigger the original onTap
  }

  void _handleTapCancel() {
    // Use a short delay before reversing
    Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
            _controller.reverse();
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      // Use ScaleTransition for the animation
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
} 
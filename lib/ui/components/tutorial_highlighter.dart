import 'package:flutter/material.dart';

class TutorialHighlighter extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Color color;

  const TutorialHighlighter({
    super.key,
    required this.child,
    this.isActive = false,
    this.color = Colors.amber,
  });

  @override
  State<TutorialHighlighter> createState() => _TutorialHighlighterState();
}

class _TutorialHighlighterState extends State<TutorialHighlighter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
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
    if (!widget.isActive) return widget.child;

    return Stack(
      children: [
        // Glow Effect
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, // Assuming circular buttons mostly
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: _opacityAnimation.value),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Actual Child
        widget.child,
      ],
    );
  }
}

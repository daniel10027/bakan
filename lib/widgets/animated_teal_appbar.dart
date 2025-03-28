import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedTealAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const AnimatedTealAppBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + 20); // 👈 définit la hauteur

  @override
  State<AnimatedTealAppBar> createState() => _AnimatedTealAppBarState();
}

class _AnimatedTealAppBarState extends State<AnimatedTealAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _bubbles = List.generate(20, (_) => _Bubble());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          Container(
            height: widget.preferredSize.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF004D40), Color(0xFF00796B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return CustomPaint(
                painter: _BubblePainter(_bubbles, _controller.value),
                size: Size.infinite,
              );
            },
          ),
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(widget.title),
            actions: widget.actions,
          ),
        ],
      ),
    );
  }
}

class _Bubble {
  late double dx;
  late double dy;
  late double radius;
  late double speed;
  late Color color;

  _Bubble() {
    final rand = Random();
    dx = rand.nextDouble();
    dy = rand.nextDouble();
    radius = rand.nextDouble() * 10 + 4;
    speed = rand.nextDouble() * 0.003 + 0.001;
    color = Colors.white.withOpacity(0.08 + rand.nextDouble() * 0.1);
  }

  void move(double t) {
    dy -= speed;
    if (dy < 0) dy = 1.0;
  }
}

class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double progress;

  _BubblePainter(this.bubbles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final bubble in bubbles) {
      bubble.move(progress);
      final offset = Offset(
        bubble.dx * size.width,
        bubble.dy * size.height,
      );
      final paint = Paint()..color = bubble.color;
      canvas.drawCircle(offset, bubble.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart'; // পার্টিকল এনিমেশনের জন্য ইমপোর্ট করা হয়েছে

class CosmicBackground extends StatefulWidget {
  final Widget child;
  const CosmicBackground({super.key, required this.child});

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // তারাগুলোর টুইঙ্কলিং ইফেক্টের জন্য এনিমেশন কন্ট্রোলার
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // ডার্ক কসমিক ব্যাকগ্রাউন্ড
      body: Stack(
        children: [
          // ১. স্টার এনিমেশন লেয়ার (Custom Painter)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: StarFieldPainter(_controller.value),
                size: Size.infinite,
              );
            },
          ),

          // ২. মাইনিং পেজের ব্যাকগ্রাউন্ড লেয়ার (পার্টিকল এনিমেশন)
          // আপনার প্রথম ফাইলে দেওয়া ব্যাকগ্রাউন্ড লজিকটি এখানে যুক্ত করা হয়েছে
          AnimatedBackground(
            vsync: this,
            behaviour: RandomParticleBehaviour(
              options: ParticleOptions(
                baseColor: const Color(0xFF14F195).withOpacity(0.2),
                spawnOpacity: 0.1,
                opacityChangeRate: 0.25,
                minOpacity: 0.1,
                maxOpacity: 0.3,
                particleCount: 20,
                spawnMaxRadius: 15,
                spawnMinRadius: 5,
                spawnMaxSpeed: 20,
                spawnMinSpeed: 10,
              ),
            ),
            child: Container(),
          ),

          // ৩. আপনার অ্যাপের মেইন কন্টেন্ট (যা এই ব্যাকগ্রাউন্ডের উপরে থাকবে)
          widget.child,
        ],
      ),
    );
  }
}

// আপনার কাস্টম স্টার পেইন্টার লজিক
class StarFieldPainter extends CustomPainter {
  final double animationValue;
  StarFieldPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final paint = Paint()..color = Colors.white;

    for (int i = 0; i < 120; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double starSize = random.nextDouble() * 1.8;

      double individualOffset = random.nextDouble() * pi * 2;
      double opacity = (sin(animationValue * pi * 2 + individualOffset) + 1) / 2;

      canvas.drawCircle(
        Offset(x, y),
        starSize,
        paint..color = Colors.white.withOpacity(opacity * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

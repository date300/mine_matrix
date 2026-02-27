import 'dart:math';
import 'package:flutter/material.dart';

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
    // এনিমেশনটি লুপে চলার জন্য। ৩-৫ সেকেন্ড দিলে তারাগুলো খুব প্রফেশনালভাবে জ্বলবে-নিভবে।
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
      backgroundColor: const Color(0xFF020617), // আপনার নির্দিষ্ট ব্যাকগ্রাউন্ড কালার
      body: Stack(
        children: [
          // প্রফেশনাল স্টার এনিমেশন লেয়ার
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: StarFieldPainter(_controller.value),
                size: Size.infinite,
              );
            },
          ),
          // আপনার অ্যাপের কন্টেন্ট (HomeScreen)
          widget.child,
        ],
      ),
    );
  }
}

class StarFieldPainter extends CustomPainter {
  final double animationValue;
  StarFieldPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // তারাগুলোর পজিশন ফিক্সড রাখার জন্য
    final paint = Paint()..color = Colors.white;

    for (int i = 0; i < 120; i++) {
      // র‍্যান্ডম পজিশন
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      
      // তারার সাইজ (কিছু ছোট, কিছু বড় - এতে ডেপথ তৈরি হয়)
      double starSize = random.nextDouble() * 1.8;

      // প্রফেশনাল টুইঙ্কলিং লজিক (Fade in & Fade out)
      // সিনাসয়ডাল ওয়েভ ব্যবহার করা হয়েছে যাতে হঠাৎ করে অদৃশ্য না হয়ে ধীরে ধীরে হয়
      double individualOffset = random.nextDouble() * pi * 2;
      double opacity = (sin(animationValue * pi * 2 + individualOffset) + 1) / 2;

      // ঝকঝকে ইফেক্টের জন্য একটু গ্লো যোগ করা (ঐচ্ছিক)
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

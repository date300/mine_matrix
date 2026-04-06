import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../layout/layout.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final RxString _loadingStatus = "INITIALIZING MATRIX...".obs;

  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  void _handleNavigation() async {
    await Future.delayed(const Duration(seconds: 1));
    _loadingStatus.value = "CONNECTING TO NODES...";

    // Wallet init করো (token আগেই main() এ ready হয়ে গেছে)
    if (mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.initWallet(context);
    }

    if (!mounted) return;
    _loadingStatus.value = "SYNCING YOUR WALLET...";

    await Future.delayed(const Duration(milliseconds: 800));

    Get.off(
      () => const AppLayout(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 85.w,
              height: 85.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white10,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF14F195).withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: 8,
                  )
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/icon/icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Icon(
                    Icons.auto_awesome,
                    size: 45.sp,
                    color: const Color(0xFF14F195),
                  ),
                ),
              ),
            )
                .animate()
                .scale(duration: 1000.ms, curve: Curves.easeOutBack)
                .shimmer(
                    delay: 1000.ms,
                    duration: 1500.ms,
                    color: Colors.white24),

            SizedBox(height: 24.h),

            Text(
              "MINE MATRIX",
              style: GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 5,
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms)
                .slideY(begin: 0.2, end: 0, duration: 600.ms),

            SizedBox(height: 35.h),

            Obx(() => Text(
                  _loadingStatus.value,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF14F195).withOpacity(0.7),
                    letterSpacing: 1.5,
                  ),
                ))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(begin: 0.4, end: 1.0, duration: 800.ms),

            SizedBox(height: 16.h),

            SizedBox(
              width: 100.w,
              height: 1.5.h,
              child: const LinearProgressIndicator(
                backgroundColor: Colors.white10,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF14F195)),
              ),
            ).animate().fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}

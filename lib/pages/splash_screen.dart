import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ইমপোর্ট পাথগুলো আপনার প্রোজেক্ট অনুযায়ী
import '../main.dart'; 
import '../layout/layout.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // ৪ সেকেন্ড পর AppLayout-এ চলে যাবে (আগের টাইমার স্টাইল)
    Timer(const Duration(seconds: 4), () {
      Get.off(() => const AppLayout(), 
      transition: Transition.fadeIn, 
      duration: const Duration(milliseconds: 800));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // আপনার নিজস্ব লোগো assets/icon/icon.png
            Container(
              width: 110.w,
              height: 110.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.accentGreen, AppColors.accentPurple],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGreen.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(20.w), // লোগোটি গোল বৃত্তের মাঝে সুন্দর দেখানোর জন্য
                child: Image.asset(
                  'assets/icon/icon.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                ),
              ),
            ).animate()
             .scale(duration: 1000.ms, curve: Curves.bounceOut) // আপনার পছন্দের বাউন্স ইফেক্ট
             .shimmer(delay: 1200.ms, duration: 1500.ms),

            SizedBox(height: 24.h),

            // নতুন নাম: MINE MATRIX
            Text(
              "MINE MATRIX",
              style: GoogleFonts.inter(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

            SizedBox(height: 8.h),

            // লোডিং টেক্সট (এনিমেটেড)
            Text(
              "Initializing Core Matrix...",
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.white54,
              ),
            ).animate(onPlay: (c) => c.repeat())
             .fadeIn(duration: 1000.ms)
             .then()
             .fadeOut(duration: 1000.ms),
            
            SizedBox(height: 50.h),
            
            // নিচের ছোট লোডিং বার
            SizedBox(
              width: 150.w,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white10,
                color: AppColors.accentGreen,
                minHeight: 2,
              ),
            ).animate().fadeIn(delay: 1000.ms),
          ],
        ),
      ),
    );
  }
}

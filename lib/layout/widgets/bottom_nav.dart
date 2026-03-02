import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNav({Key? key, required this.currentIndex, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // স্ক্রিন সাইজ অনুযায়ী মার্জিন এবং উইডথ অ্যাডজাস্ট করা
    return Container(
      height: 110.h, // রেসপন্সিভ হাইট
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // ১. ফ্রস্টেড গ্লাস নেভিগেশন বেস
          GlassmorphicContainer(
            width: double.infinity,
            height: 65.h, // মডার্ন স্লিম লুক
            borderRadius: 30.r,
            blur: 20,
            alignment: Alignment.center,
            border: 1.5,
            linearGradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderGradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.25), Colors.transparent],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // সমান দূরত্ব বজায় রাখার জন্য
              children: [
                Expanded(child: _navItem(0, CupertinoIcons.square_grid_2x2_fill, "Home")),
                SizedBox(width: 70.w), // মাঝখানের বাটনের জন্য ডাইনামিক গ্যাপ
                Expanded(child: _navItem(2, CupertinoIcons.briefcase_fill, "Wallet")),
              ],
            ),
          ).animate().slideY(begin: 1, end: 0, duration: 800.ms, curve: Curves.easeOutCubic),

          // ২. ফ্লোটিং মাইনিং অ্যাকশন বাটন
          Positioned(
            bottom: 25.h, // সব ডিভাইসে বাটনের পজিশন ঠিক রাখার জন্য
            child: GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                onTap(1);
              },
              child: _miningActionBtn(currentIndex == 1),
            ),
          )
        ],
      ),
    );
  }

  // নেভিগেশন আইটেম (ফিক্সড দৃশ্যমানতা)
  Widget _navItem(int index, IconData icon, String label) {
    bool active = currentIndex == index;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(index);
          },
          child: Column(
            children: [
              Icon(
                icon,
                color: active ? const Color(0xFF14F195) : Colors.white.withOpacity(0.4),
                size: 24.sp,
              )
              .animate(target: active ? 1 : 0)
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 200.ms)
              .tint(color: const Color(0xFF14F195), end: 1), // শুধু অ্যাক্টিভ হলে রঙ বদলাবে
              
              SizedBox(height: 4.h),
              
              Text(
                label,
                style: GoogleFonts.inter(
                  color: active ? Colors.white : Colors.white.withOpacity(0.4),
                  fontSize: 10.sp,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // সেন্টার মাইনিং বাটন (রেস্পন্সিভ এবং এনিমেটেড)
  Widget _miningActionBtn(bool isActive) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0D0D12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 5,
          )
        ],
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isActive 
                ? [Colors.white, const Color(0xFFE0E0E0)] 
                : [const Color(0xFF14F195), const Color(0xFF0C945B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14F195).withOpacity(isActive ? 0.6 : 0.4),
              blurRadius: isActive ? 25 : 15,
              spreadRadius: isActive ? 4 : 1,
            )
          ],
        ),
        child: Icon(
          CupertinoIcons.bolt_fill,
          color: isActive ? const Color(0xFF14F195) : Colors.black,
          size: 26.sp,
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 2000.ms, color: Colors.white70),
      ),
    ).animate(target: isActive ? 1 : 0).scale(
      begin: const Offset(1, 1), 
      end: const Offset(1.1, 1.1),
      duration: 300.ms
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.h,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Bottom nav bar
          Container(
            width: double.infinity,
            height: 65.h,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D12),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: Colors.white10, width: 1),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navItem(0, CupertinoIcons.square_grid_2x2_fill, "Home"),
                _navItem(2, CupertinoIcons.person_2_fill, "Refer"),
                SizedBox(width: 60.w), // Mining button gap
                _navItem(3, CupertinoIcons.briefcase_fill, "Wallet"),
                _navItem(4, CupertinoIcons.money_dollar_circle_fill, "Cash"),
              ],
            ),
          ),

          // Mining center button
          Positioned(
            bottom: 20.h,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onTap(1);
              },
              child: _miningBtn(currentIndex == 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool active = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active
                ? const Color(0xFF14F195)
                : Colors.white.withOpacity(0.5),
            size: 22.sp,
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.inter(
              color: active ? Colors.white : Colors.white.withOpacity(0.5),
              fontSize: 10.sp,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ).animate(target: active ? 1 : 0).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 200.ms,
          ),
    );
  }

  Widget _miningBtn(bool isActive) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: const BoxDecoration(
        color: Color(0xFF1B1B22),
        shape: BoxShape.circle,
      ),
      child: Container(
        padding: EdgeInsets.all(15.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive
                ? [Colors.white, Colors.grey.shade400]
                : [const Color(0xFF14F195), const Color(0xFF9945FF)],
          ),
          boxShadow: [
            BoxShadow(
              color: (isActive ? Colors.white : const Color(0xFF14F195))
                  .withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          CupertinoIcons.bolt_fill,
          color: isActive ? const Color(0xFF0D0D12) : Colors.white,
          size: 28.sp,
        ),
      ),
    )
        .animate(target: isActive ? 1 : 0)
        .shimmer(duration: 1500.ms, color: Colors.white24)
        .shake(hz: 2, curve: Curves.easeInOut);
  }
}

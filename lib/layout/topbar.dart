import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  final Color accentGreen = const Color(0xFF14F195);
  final Color accentPurple = const Color(0xFF9945FF); // ওয়ালেটের জন্য একটু আলাদা কালার

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // টেক্সট সেকশন
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "WEB3",
                style: GoogleFonts.inter(
                  color: Colors.white60, 
                  fontSize: 12.sp, 
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                "MINE MATRIX",
                style: GoogleFonts.inter(
                  color: Colors.white, 
                  fontSize: 24.sp, 
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          
          // অ্যাকশন বাটন সেকশন (ওয়ালেট + নোটিফিকেশন)
          Row(
            children: [
              // ওয়ালেট কানেক্ট বাটন
              GestureDetector(
                onTap: () {
                  // এখানে ওয়ালেট কানেক্ট লজিক বসবে
                },
                child: GlassmorphicContainer(
                  width: 45.w,
                  height: 45.w,
                  borderRadius: 15.r,
                  blur: 15,
                  alignment: Alignment.center,
                  border: 1,
                  linearGradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
                  ),
                  borderGradient: LinearGradient(
                    colors: [accentPurple.withOpacity(0.5), Colors.transparent]
                  ),
                  child: Icon(
                    CupertinoIcons.link, // অথবা CupertinoIcons.creditcard
                    color: Colors.white, 
                    size: 20.sp
                  ),
                ),
              ),
              
              SizedBox(width: 12.w), // দুই বাটনের মাঝে গ্যাপ

              // নোটিফিকেশন বাটন
              GlassmorphicContainer(
                width: 45.w,
                height: 45.w,
                borderRadius: 15.r,
                blur: 15,
                alignment: Alignment.center,
                border: 1,
                linearGradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
                ),
                borderGradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.2), Colors.transparent]
                ),
                child: Icon(
                  CupertinoIcons.bell_fill, 
                  color: accentGreen, 
                  size: 22.sp
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

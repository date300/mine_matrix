import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../layout/layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // এখানে কোনো Scaffold বা Container (with color) ব্যবহার করা হয়নি
    // যাতে layout.dart এর AnimatedBackground সরাসরি দেখা যায়।
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Text(
            "Dashboard",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
            ),
          ).animate().fadeIn().slideX(),

          SizedBox(height: 20.h),

          // একটি স্বচ্ছ গ্লাস কার্ড
          _buildFeatureCard(
            "Active Miners",
            "1,240 Nodes",
            Icons.memory_rounded, // বিল্ড এরর এড়াতে মেটেরিয়াল আইকন
            AppColors.blue,
          ).animate().fadeIn(delay: 200.ms).scale(),

          SizedBox(height: 15.h),

          _buildFeatureCard(
            "Network Hashrate",
            "850.5 PH/s",
            Icons.insights_rounded, 
            AppColors.accentGreen,
          ).animate().fadeIn(delay: 400.ms).scale(),

          SizedBox(height: 25.h),

          Text(
            "Recent Activity",
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 15.h),

          _buildActivityItem("Daily Reward", "+0.45 VXL", "2 hours ago"),
          _buildActivityItem("Mining Started", "Session Active", "5 hours ago"),

          SizedBox(height: 100.h), 
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String value, IconData icon, Color color) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 100.h,
      borderRadius: 20.r,
      blur: 15, // হালকা ব্লার দিয়ে ব্যাকগ্রাউন্ড দৃশ্যমান রাখা হয়েছে
      alignment: Alignment.center,
      border: 0.5, // চিকন বর্ডার যাতে আরও প্রিমিয়াম লাগে
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.05), // অত্যন্ত স্বচ্ছ
          Colors.white.withOpacity(0.01),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          color.withOpacity(0.3),
          Colors.transparent,
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24.sp),
        ),
        title: Text(title, style: GoogleFonts.inter(color: Colors.white60, fontSize: 12.sp)),
        subtitle: Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildActivityItem(String title, String value, String time) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02), // সলিড কালারের বদলে হালকা অপাসিটি
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(time, style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp)),
            ],
          ),
          Text(value, style: GoogleFonts.inter(color: AppColors.accentGreen, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

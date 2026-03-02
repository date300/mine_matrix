import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// layout.dart থেকে AppColors পাওয়ার জন্য ইম্পোর্ট
import '../layout/layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          
          // মাইনিং স্ট্যাটাস কার্ড
          _buildFeatureCard(
            "Active Miners",
            "1,240 Nodes",
            CupertinoIcons.cpu,
            AppColors.blue,
          ).animate().fadeIn(delay: 200.ms).scale(),
          
          SizedBox(height: 15.h),
          
          _buildFeatureCard(
            "Network Hashrate",
            "850.5 PH/s",
            CupertinoIcons.waveform_path_ecg,
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
          
          // লিস্ট আইটেম
          _buildActivityItem("Daily Reward", "+0.45 VXL", "2 hours ago"),
          _buildActivityItem("Mining Started", "Session Active", "5 hours ago"),
          
          SizedBox(height: 100.h), // নিচের নেভবার এর জন্য গ্যাপ
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String value, IconData icon, Color color) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 100.h,
      borderRadius: 20.r,
      blur: 20,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.02)],
      ),
      borderGradient: LinearGradient(
        colors: [color.withOpacity(0.5), Colors.transparent],
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
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15.r),
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

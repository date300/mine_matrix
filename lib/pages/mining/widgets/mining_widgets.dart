import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/mining_constants.dart';
import '../controllers/mining_controller.dart';

// ============================================
// MAIN SCREEN - সব কন্টেন্ট উপরে
// ============================================

class MiningScreen extends StatelessWidget {
  final MiningController c;
  
  const MiningScreen({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================================
                // 1. HEADER - সবার উপরে
                // ============================================
                _buildHeader(),
                SizedBox(height: 16.h),
                
                // ============================================
                // 2. AUTO MINING STATUS CARD (NEW)
                // ============================================
                AutoMiningCard(c: c),
                SizedBox(height: 16.h),
                
                // ============================================
                // 3. LIVE EARNINGS CARD
                // ============================================
                LiveEarningsCard(c: c),
                SizedBox(height: 16.h),
                
                // ============================================
                // 4. SOLANA MINING CARD
                // ============================================
                SolanaLiveCard(c: c),
                SizedBox(height: 16.h),
                
                // ============================================
                // 5. CYCLE PROGRESS
                // ============================================
                CycleProgressSection(c: c),
                SizedBox(height: 16.h),
                
                // ============================================
                // 6. BOOST INFO
                // ============================================
                BoostInfoSection(
                  c: c, 
                  onBuyBoost: () => _showBoostDialog(context),
                ),
                SizedBox(height: 16.h),
                
                // ============================================
                // 7. MINING STATS GRID
                // ============================================
                _buildStatsGrid(),
                SizedBox(height: 16.h),
                
                // ============================================
                // 8. ACTION BUTTONS
                // ============================================
                _buildActionButtons(),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "MINING DASHBOARD",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              "Auto Mining Active",
              style: GoogleFonts.inter(
                color: AppColors.accentGreen,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.bgCard,
            border: Border.all(color: AppColors.accentPurple.withOpacity(0.3)),
          ),
          child: Icon(
            Icons.settings,
            color: Colors.white70,
            size: 20.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard("Hash Rate", "45.2 TH/s", AppLottie.bolt),
        _buildStatCard("Active Miners", "1,234", AppLottie.mining),
        _buildStatCard("Total Mined", "12.5 SOL", AppLottie.coin),
        _buildStatCard("Uptime", "99.9%", AppLottie.shield),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String lottieUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: AppColors.bgCard,
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24.w,
              height: 24.h,
              child: Lottie.network(lottieUrl),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            "WITHDRAW",
            AppColors.accentGreen,
            Icons.account_balance_wallet,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildActionButton(
            "BOOST",
            AppColors.accentPurple,
            Icons.rocket_launch,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, Color color, IconData icon) {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBoostDialog(BuildContext context) {
    // Boost dialog implementation
  }
}

// ============================================
// NEW: AUTO MINING CARD - সবার উপরে থাকবে
// ============================================

class AutoMiningCard extends StatelessWidget {
  final MiningController c;
  
  const AutoMiningCard({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final bool isAutoMining = c.isAutoMining; // আপনার controller থেকে নিন

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isAutoMining 
            ? [
                AppColors.accentGreen.withOpacity(0.3),
                AppColors.accentPurple.withOpacity(0.1),
                AppColors.bgCard,
              ]
            : [
                Colors.orange.withOpacity(0.2),
                AppColors.bgCard,
              ],
        ),
        border: Border.all(
          color: isAutoMining 
            ? AppColors.accentGreen.withOpacity(0.5)
            : Colors.orange.withOpacity(0.3),
          width: isAutoMining ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isAutoMining 
              ? AppColors.accentGreen.withOpacity(0.3)
              : Colors.orange.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                Row(
                  children: [
                    // Animated Mining Icon
                    Container(
                      width: 56.w,
                      height: 56.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isAutoMining
                            ? [AppColors.accentGreen, AppColors.accentPurple]
                            : [Colors.orange, Colors.deepOrange],
                        ),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 32.w,
                          height: 32.h,
                          child: Lottie.network(
                            AppLottie.mining,
                            repeat: true,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "AUTO MINING",
                                style: GoogleFonts.inter(
                                  color: isAutoMining 
                                    ? AppColors.accentGreen 
                                    : Colors.orange,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              if (isAutoMining)
                                Container(
                                  width: 8.w,
                                  height: 8.h,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accentGreen,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accentGreen.withOpacity(0.6),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            isAutoMining 
                              ? "Running 24/7 automatically"
                              : "Tap to enable auto mining",
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Toggle Switch
                    GestureDetector(
                      onTap: () {
                        // Toggle auto mining
                        c.toggleAutoMining();
                      },
                      child: Container(
                        width: 52.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          color: isAutoMining 
                            ? AppColors.accentGreen 
                            : Colors.white24,
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: isAutoMining 
                            ? Alignment.centerRight 
                            : Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.all(2.w),
                            child: Container(
                              width: 24.w,
                              height: 24.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAutoStat("Next Claim", "02:34:56", Icons.timer),
                    _buildAutoStat("Auto Rate", "+0.0005/s", Icons.speed),
                    _buildAutoStat("Streak", "7 Days", Icons.local_fire_department),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildAutoStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 16.sp),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 9.sp,
          ),
        ),
      ],
    );
  }
}

// ============================================
// PREVIOUS CLASSES (আগের কোড)
// ============================================

class LiveEarningsCard extends StatelessWidget {
  final MiningController c;
  const LiveEarningsCard({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentGreen.withOpacity(0.15),
            AppColors.accentPurple.withOpacity(0.05),
            AppColors.bgCard,
          ],
        ),
        border: Border.all(
          color: AppColors.accentGreen.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: Lottie.network(AppLottie.pulse, repeat: true),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "LIVE EARNINGS",
                      style: GoogleFonts.inter(
                        color: AppColors.accentGreen,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "\$${c.liveUSD.toStringAsFixed(4)}",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text(
                        "USD",
                        style: GoogleFonts.inter(
                          color: AppColors.accentGreen,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                  ),
                  child: Text(
                    "Withdrawable: \$${c.withdrawableUSD.toStringAsFixed(2)}  |  ${(c.cycleProgress * 100).clamp(0, 100).toStringAsFixed(1)}% to \$100",
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }
}

// SolanaLiveCard, CycleProgressSection, BoostInfoSection 
// এবং অন্যান্য ক্লাস আগের মতোই থাকবে...
// (আপনার আগের কোড এখানে পেস্ট করুন)

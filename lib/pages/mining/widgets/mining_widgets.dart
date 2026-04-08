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

// NOTE: AppColors is imported from mining_constants.dart
// Do NOT define AppColors here to avoid conflict

// --- Lottie Network URLs --------------------------------------------------------------
class AppLottie {
  static const String mining      = 'https://assets10.lottiefiles.com/packages/lf20_w51pcehl.json';
  static const String rocket      = 'https://assets10.lottiefiles.com/packages/lf20_96bovdur.json';
  static const String bolt        = 'https://assets10.lottiefiles.com/packages/lf20_7z8wtyb0.json';
  static const String coin        = 'https://assets10.lottiefiles.com/packages/lf20_6wutsrox.json';
  static const String pulse       = 'https://assets10.lottiefiles.com/packages/lf20_b88nh30c.json';
  static const String success     = 'https://assets10.lottiefiles.com/packages/lf20_pqnfmkj9.json';
  static const String confetti    = 'https://assets10.lottiefiles.com/packages/lf20_u4yrau.json';
  static const String loading     = 'https://assets10.lottiefiles.com/packages/lf20_7fwvvesa.json';
  static const String error       = 'https://assets10.lottiefiles.com/packages/lf20_kcsr6fcp.json';
  static const String empty       = 'https://assets10.lottiefiles.com/packages/lf20_s8pbrcfw.json';
  static const String chart       = 'https://assets10.lottiefiles.com/packages/lf20_qmfs6c3i.json';
  static const String shield      = 'https://assets10.lottiefiles.com/packages/lf20_5njp3vgg.json';
  static const String hammer      = 'https://assets10.lottiefiles.com/packages/lf20_3s913D.json';
}

// --- Pulse Dot with Lottie --------------------------------------------------------------
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulseDot({super.key, required this.color, this.size = 6});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: widget.size.w,
          height: widget.size.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.6),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Compact Boost Info Section (FIRST - TOP PRIORITY) --------------------------------------------------------------
class CompactBoostInfoSection extends StatelessWidget {
  final MiningController c;
  final VoidCallback onBuyBoost;
  const CompactBoostInfoSection({super.key, required this.c, required this.onBuyBoost});

  @override
  Widget build(BuildContext context) {
    final double boostPercent =
        ((c.boostMultiplier - 1.0) / (kNormalDays / kBoostDays - 1.0))
            .clamp(0.0, 1.0);
    final bool maxed = c.boostAmount >= 50;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [
            AppColors.accentPurple.withOpacity(0.2),
            AppColors.accentPurple.withOpacity(0.05),
            AppColors.bgCard,
          ],
        ),
        border: Border.all(
          color: AppColors.accentPurple.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: Lottie.network(AppLottie.rocket),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      "BOOST",
                      style: GoogleFonts.inter(
                        color: AppColors.accentPurple,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    "${c.boostMultiplier.toStringAsFixed(2)}x",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8.h),
            
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: boostPercent,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                minHeight: 4.h,
              ),
            ),
            
            SizedBox(height: 8.h),
            
            // Bottom Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "\$${c.boostAmount.toStringAsFixed(0)}/50 invested",
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 9.sp,
                  ),
                ),
                GestureDetector(
                  onTap: maxed ? null : onBuyBoost,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      gradient: maxed
                          ? null
                          : const LinearGradient(
                              colors: [AppColors.accentPurple, Color(0xFFCC44FF)],
                            ),
                      color: maxed ? Colors.white12 : null,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      maxed ? "MAXED" : "+ BUY",
                      style: GoogleFonts.inter(
                        color: maxed ? Colors.white38 : Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }
}

// --- Compact Auto Mining Card (SECOND) --------------------------------------------------------------
class CompactAutoMiningCard extends StatelessWidget {
  final MiningController c;
  final VoidCallback onBuyAuto;
  const CompactAutoMiningCard({super.key, required this.c, required this.onBuyAuto});

  @override
  Widget build(BuildContext context) {
    final bool active = c.autoMining;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [
            (active ? AppColors.accentGreen : Colors.white).withOpacity(active ? 0.15 : 0.05),
            AppColors.bgCard,
          ],
        ),
        border: Border.all(
          color: (active ? AppColors.accentGreen : Colors.white54).withOpacity(active ? 0.4 : 0.2),
          width: active ? 1.5 : 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.accentGreen.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: active
                    ? const LinearGradient(
                        colors: [AppColors.accentGreen, Color(0xFF00CC88)],
                      )
                    : null,
                color: active ? null : Colors.white10,
              ),
              child: Center(
                child: SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: Lottie.network(
                    active ? AppLottie.shield : AppLottie.bolt,
                    repeat: active,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    active ? "AUTO MINING ON" : "AUTO MINING",
                    style: GoogleFonts.inter(
                      color: active ? AppColors.accentGreen : Colors.white54,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    active
                        ? "Auto-restart enabled"
                        : "One-time \$10 unlock",
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 8.sp,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PulseDot(color: AppColors.accentGreen, size: 5),
                  SizedBox(width: 4.w),
                  Text(
                    "ON",
                    style: GoogleFonts.inter(
                      color: AppColors.accentGreen,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: onBuyAuto,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentGreen, Color(0xFF00CC88)],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    "BUY \$10",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.05);
  }
}

// --- Compact Live Earnings Card --------------------------------------------------------------
class CompactLiveEarningsCard extends StatelessWidget {
  final MiningController c;
  const CompactLiveEarningsCard({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentGreen.withOpacity(0.12),
            AppColors.accentPurple.withOpacity(0.03),
            AppColors.bgCard,
          ],
        ),
        border: Border.all(
          color: AppColors.accentGreen.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 12.w,
                      height: 12.h,
                      child: Lottie.network(AppLottie.pulse, repeat: true),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      "LIVE EARNINGS",
                      style: GoogleFonts.inter(
                        color: AppColors.accentGreen,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "\$${c.liveUSD.toStringAsFixed(4)}",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Padding(
                      padding: EdgeInsets.only(bottom: 3.h),
                      child: Text(
                        "USD",
                        style: GoogleFonts.inter(
                          color: AppColors.accentGreen,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.accentGreen.withOpacity(0.2)),
                  ),
                  child: Text(
                    "Withdraw: \$${c.withdrawableUSD.toStringAsFixed(2)} | ${(c.cycleProgress * 100).clamp(0, 100).toStringAsFixed(0)}%",
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 8.sp,
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

// --- Compact Solana Live Card --------------------------------------------------------------
class CompactSolanaLiveCard extends StatelessWidget {
  final MiningController c;
  const CompactSolanaLiveCard({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final bool active = c.isMining;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentPurple.withOpacity(active ? 0.15 : 0.06),
            AppColors.accentGreen.withOpacity(active ? 0.08 : 0.03),
            AppColors.bgCard,
          ],
        ),
        border: Border.all(
          color: AppColors.accentPurple.withOpacity(active ? 0.3 : 0.15),
          width: active ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withOpacity(active ? 0.15 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.accentPurple, AppColors.accentGreen],
                        ),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 18.w,
                          height: 18.h,
                          child: Lottie.network(AppLottie.coin),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "SOLANA",
                            style: GoogleFonts.inter(
                              color: AppColors.accentPurple,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            "\$${c.solPrice.toStringAsFixed(2)}/SOL",
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 8.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (active)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.accentGreen.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PulseDot(color: AppColors.accentGreen, size: 5),
                            SizedBox(width: 4.w),
                            Text(
                              "LIVE",
                              style: GoogleFonts.inter(
                                color: AppColors.accentGreen,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          c.formatSol(c.liveSOL),
                          style: GoogleFonts.spaceMono(
                            color: active ? AppColors.accentGreen : Colors.white38,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Text(
                        "SOL",
                        style: GoogleFonts.inter(
                          color: AppColors.accentGreen,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(
                      active ? CupertinoIcons.arrow_up_circle_fill : CupertinoIcons.pause_circle_fill,
                      color: active ? AppColors.accentGreen : Colors.white24,
                      size: 11.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      active
                          ? "+${c.formatSol(c.solPerSec)}/sec"
                          : "Tap ORB to mine",
                      style: GoogleFonts.spaceMono(
                        color: active ? Colors.white60 : Colors.white24,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (active)
                      Text(
                        "≈ \$${(c.liveSOL * c.solPrice).toStringAsFixed(3)}",
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 8.sp,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(target: active ? 1.0 : 0.0).shimmer(
      duration: const Duration(milliseconds: 2000),
      color: AppColors.accentGreen.withOpacity(0.08),
    );
  }
}

// --- Compact Cycle Progress Section --------------------------------------------------------------
class CompactCycleProgressSection extends StatelessWidget {
  final MiningController c;
  const CompactCycleProgressSection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor;

    if (c.isMining) {
      statusText = "Mining...";
      statusColor = AppColors.accentGreen;
    } else if (c.dayStarted) {
      statusText = "Paused";
      statusColor = Colors.orange;
    } else {
      statusText = "Ready";
      statusColor = AppColors.accentPurple;
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [
            AppColors.accentGreen.withOpacity(0.08),
            AppColors.bgCard,
          ],
        ),
        border: Border.all(
          color: AppColors.accentGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: Lottie.network(AppLottie.chart),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      "CYCLE",
                      style: GoogleFonts.inter(
                        color: AppColors.accentGreen,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: statusColor.withOpacity(0.25)),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: c.cycleProgress.clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                minHeight: 5.h,
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${(c.cycleProgress * 100).toStringAsFixed(1)}%",
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 8.sp,
                  ),
                ),
                Text(
                  "\$${c.liveUSD.toStringAsFixed(2)} / \$${kUsdTarget.toStringAsFixed(0)}",
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }
}

// --- Compact Withdrawable Section --------------------------------------------------------------
class CompactWithdrawableSection extends StatelessWidget {
  final MiningController c;
  const CompactWithdrawableSection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        gradient: LinearGradient(
          colors: [
            AppColors.accentLeaf.withOpacity(0.12),
            AppColors.bgCard,
          ],
        ),
        border: Border.all(
          color: AppColors.accentLeaf.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentLeaf.withOpacity(0.15),
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  color: AppColors.accentLeaf,
                  size: 16.sp,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "WITHDRAWABLE",
                    style: GoogleFonts.inter(
                      color: AppColors.accentLeaf,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    "\$${c.withdrawableUSD.toStringAsFixed(2)}",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}

// --- Compact Mining Orb --------------------------------------------------------------
class CompactMiningOrb extends StatelessWidget {
  final MiningController c;
  final VoidCallback onTap;
  const CompactMiningOrb({super.key, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPaused = c.dayStarted && !c.isMining;

    String orbLabel;
    String orbSub = '';
    Color orbIconColor;
    List<Color> borderColors;
    String lottieAsset;

    if (c.isMining && c.boostActive) {
      orbLabel = "BOOSTED";
      orbSub = "MINING";
      orbIconColor = AppColors.accentPurple;
      borderColors = [AppColors.accentPurple, AppColors.accentGreen];
      lottieAsset = AppLottie.rocket;
    } else if (c.isMining) {
      orbLabel = "MINING";
      orbIconColor = AppColors.accentGreen;
      borderColors = [AppColors.accentGreen, AppColors.accentPurple];
      lottieAsset = AppLottie.mining;
    } else if (isPaused) {
      orbLabel = "PAUSED";
      orbSub = "Tap to resume";
      orbIconColor = Colors.orange;
      borderColors = [Colors.orange.withOpacity(0.6), Colors.white10];
      lottieAsset = AppLottie.pulse;
    } else {
      orbLabel = "START";
      orbSub = "Tap to mine";
      orbIconColor = Colors.white70;
      borderColors = [Colors.white38, Colors.white10];
      lottieAsset = AppLottie.bolt;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated outer ring
          if (c.isMining)
            Container(
              width: 130.w,
              height: 130.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (c.boostActive ? AppColors.accentPurple : AppColors.accentGreen)
                      .withOpacity(0.4),
                  width: 1.5,
                ),
              ),
            )
                .animate(onPlay: (ctrl) => ctrl.repeat())
                .rotate(duration: const Duration(seconds: 3))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.12, 1.12),
                  curve: Curves.easeInOutSine,
                )
                .then()
                .scale(begin: const Offset(1.12, 1.12), end: const Offset(1, 1)),

          // Boost ring
          if (c.isMining && c.boostActive)
            Container(
              width: 145.w,
              height: 145.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentPurple.withOpacity(0.25),
                  width: 1,
                ),
              ),
            )
                .animate(onPlay: (ctrl) => ctrl.repeat())
                .rotate(duration: const Duration(seconds: 5), begin: 1, end: 0),

          // Main orb
          Container(
            width: 115.w,
            height: 115.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.4),
                ],
              ),
              border: Border.all(
                color: borderColors[0],
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: borderColors[0].withOpacity(0.25),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 38.w,
                      height: 38.h,
                      child: Lottie.network(lottieAsset, repeat: c.isMining),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      orbLabel,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (orbSub.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        orbSub,
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 8.sp,
                        ),
                      ),
                    ],
                    if (c.isMining) ...[
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: orbIconColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: orbIconColor.withOpacity(0.25)),
                        ),
                        child: Text(
                          "+\$${c.usdPerSec.toStringAsFixed(6)}/s",
                          style: GoogleFonts.spaceMono(
                            color: orbIconColor,
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Buy Boost Bottom Sheet --------------------------------------------------------------
class BuyBoostSheet extends StatefulWidget {
  final MiningController c;
  final Future<bool> Function(double amount) onConfirm;
  const BuyBoostSheet({super.key, required this.c, required this.onConfirm});

  @override
  State<BuyBoostSheet> createState() => _BuyBoostSheetState();
}

class _BuyBoostSheetState extends State<BuyBoostSheet> {
  double _amount = 10;
  bool _loading = false;
  String? _error;

  double get _remainingBoost => (50 - widget.c.boostAmount).clamp(0, 50).toDouble();

  double get _newMultiplier {
    const baseDays = 360.0;
    const minDays = 80.0;
    final newBoost = ((widget.c.boostAmount + _amount).clamp(0, 50)).toDouble();
    final ratio = newBoost / 50.0;
    final days = baseDays - (baseDays - minDays) * ratio;
    return baseDays / days;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border(
          top: BorderSide(color: AppColors.accentPurple.withOpacity(0.3), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Header
            Row(
              children: [
                SizedBox(
                  width: 40.w,
                  height: 40.h,
                  child: Lottie.network(AppLottie.rocket),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SPEED BOOST",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        "Invest \$1-\$50 to speed up",
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Info cards
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.accentPurple.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoItem("Current", "\$${widget.c.boostAmount.toStringAsFixed(0)}", AppColors.accentPurple),
                  _divider(),
                  _infoItem("Remaining", "\$${_remainingBoost.toStringAsFixed(0)}", Colors.white70),
                  _divider(),
                  _infoItem("Speed", "${widget.c.boostMultiplier.toStringAsFixed(2)}x", AppColors.accentGreen),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Amount selector
            Text(
              "Amount",
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.accentPurple,
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.white,
                overlayColor: AppColors.accentPurple.withOpacity(0.2),
                trackHeight: 5,
              ),
              child: Slider(
                value: _amount.clamp(1, _remainingBoost.clamp(1, 50)),
                min: 1,
                max: _remainingBoost.clamp(1, 50),
                divisions: (_remainingBoost.clamp(1, 50) - 1).round(),
                onChanged: _remainingBoost < 1
                    ? null
                    : (v) => setState(() => _amount = v.roundToDouble()),
              ),
            ),
            SizedBox(height: 12.h),

            // Quick buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [5, 10, 20, 50].map((val) {
                final double dVal = val.toDouble();
                final bool sel = _amount == dVal;
                final bool disabled = dVal > _remainingBoost;
                return GestureDetector(
                  onTap: disabled ? null : () => setState(() => _amount = dVal.clamp(1, _remainingBoost)),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      gradient: sel
                          ? const LinearGradient(colors: [AppColors.accentPurple, Color(0xFFCC44FF)])
                          : null,
                      color: sel ? null : Colors.white10,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: sel ? AppColors.accentPurple : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      "\$$val",
                      style: GoogleFonts.inter(
                        color: disabled ? Colors.white24 : (sel ? Colors.white : Colors.white70),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16.h),

            // Preview
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.accentGreen.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.arrow_up_circle_fill, color: AppColors.accentGreen, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    "New speed: ${_newMultiplier.toStringAsFixed(2)}x",
                    style: GoogleFonts.inter(
                      color: AppColors.accentGreen,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Error
            if (_error != null)
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.exclamationmark_circle, color: Colors.red, size: 16.sp),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.inter(color: Colors.red, fontSize: 11.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _loading || _remainingBoost < 1
                    ? null
                    : () async {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        final ok = await widget.onConfirm(_amount);
                        if (!mounted) return;
                        if (ok) {
                          Navigator.pop(context);
                        } else {
                          setState(() {
                            _loading = false;
                            _error = "Purchase failed. Check balance.";
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: _loading || _remainingBoost < 1
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.accentPurple, Color(0xFFCC44FF)],
                          ),
                    color: _loading || _remainingBoost < 1 ? Colors.white12 : null,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: _loading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _remainingBoost < 1 ? "MAX BOOST" : "CONFIRM \$${_amount.toStringAsFixed(0)}",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: GoogleFonts.inter(
            color: valueColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32.h,
        color: Colors.white12,
      );
}

// --- Buy Auto Mining Sheet --------------------------------------------------------------
class BuyAutoMiningSheet extends StatefulWidget {
  final MiningController c;
  final Future<bool> Function() onConfirm;
  const BuyAutoMiningSheet({super.key, required this.c, required this.onConfirm});

  @override
  State<BuyAutoMiningSheet> createState() => _BuyAutoMiningSheetState();
}

class _BuyAutoMiningSheetState extends State<BuyAutoMiningSheet> {
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border(
          top: BorderSide(color: AppColors.accentGreen.withOpacity(0.3), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),

            // Icon
            Container(
              width: 64.w,
              height: 64.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.accentGreen, Color(0xFF00CC88)],
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 38.w,
                  height: 38.h,
                  child: Lottie.network(AppLottie.shield),
                ),
              ),
            ),
            SizedBox(height: 14.h),

            Text(
              "Auto Mining",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              "One-time \$10 unlock. Auto-restart every cycle.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 12.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 16.h),

            // Features
            ...[
              _featureRow(CupertinoIcons.checkmark_circle_fill, "Auto-restart after \$100 cycle", AppColors.accentGreen),
              _featureRow(CupertinoIcons.checkmark_circle_fill, "No manual tap needed", AppColors.accentGreen),
              _featureRow(CupertinoIcons.checkmark_circle_fill, "Works with all boosts", AppColors.accentGreen),
            ],
            SizedBox(height: 16.h),

            // Price
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Unlock Cost",
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13.sp),
                  ),
                  Text(
                    "\$10.00",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Error
            if (_error != null)
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.exclamationmark_circle, color: Colors.red, size: 16.sp),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.inter(color: Colors.red, fontSize: 11.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        final ok = await widget.onConfirm();
                        if (!mounted) return;
                        if (ok) {
                          Navigator.pop(context);
                        } else {
                          setState(() {
                            _loading = false;
                            _error = "Need \$10 balance.";
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: _loading
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.accentGreen, Color(0xFF00CC88)],
                          ),
                    color: _loading ? Colors.white12 : null,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: _loading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "UNLOCK \$10",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String text, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Helper Functions --------------------------------------------------------------
void showBuyBoostSheet(
  BuildContext context,
  MiningController controller,
  Future<bool> Function(double) onConfirm,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BuyBoostSheet(c: controller, onConfirm: onConfirm),
  );
}

void showBuyAutoMiningSheet(
  BuildContext context,
  MiningController controller,
  Future<bool> Function() onConfirm,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BuyAutoMiningSheet(c: controller, onConfirm: onConfirm),
  );
}

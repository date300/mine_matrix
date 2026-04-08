import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';
import '../constants/mining_constants.dart';
import '../controllers/mining_controller.dart';

// --- Colors ------------------------------------------------------------------
class AppColors {
  static const Color background   = Color(0xFF0A0A0F);
  static const Color surface      = Color(0xFF12121A);
  static const Color accentGreen  = Color(0xFF00FFA3);
  static const Color accentPurple = Color(0xFFB829F7);
  static const Color accentBlue   = Color(0xFF00D4FF);
  static const Color accentOrange = Color(0xFFFF9500);
  static const Color accentRed    = Color(0xFFFF4D4D);
  static const Color accentLeaf   = Color(0xFF4ADE80);
  static const Color textPrimary  = Color(0xFFFFFFFF);
  static const Color textSecondary= Color(0xFF8B8B9E);
  static const Color textMuted    = Color(0xFF4A4A5A);
  static const Color border       = Color(0xFF2A2A3A);
  static const Color cardBg       = Color(0xFF161620);
}

// Lottie Network URLs - No local assets needed!
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
  const PulseDot({super.key, required this.color});

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
          width: 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.6),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Live Earnings Card with Lottie --------------------------------------------------------------
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
            AppColors.accentBlue.withOpacity(0.05),
            AppColors.surface,
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

// --- Solana Live Card with Lottie --------------------------------------------------------------
class SolanaLiveCard extends StatelessWidget {
  final MiningController c;
  const SolanaLiveCard({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final bool active = c.isMining;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentPurple.withOpacity(active ? 0.2 : 0.08),
            AppColors.accentGreen.withOpacity(active ? 0.1 : 0.04),
            AppColors.surface,
          ],
        ),
        border: Border.all(
          color: AppColors.accentPurple.withOpacity(active ? 0.4 : 0.2),
          width: active ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withOpacity(active ? 0.3 : 0.1),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.accentPurple, AppColors.accentGreen],
                        ),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 24.w,
                          height: 24.h,
                          child: Lottie.network(AppLottie.coin),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "SOLANA MINING",
                            style: GoogleFonts.inter(
                              color: AppColors.accentPurple,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            "1 SOL = \$${c.solPrice.toStringAsFixed(2)}",
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (active)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PulseDot(color: AppColors.accentGreen),
                            SizedBox(width: 6.w),
                            Text(
                              "LIVE",
                              style: GoogleFonts.inter(
                                color: AppColors.accentGreen,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16.h),
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
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Text(
                        "SOL",
                        style: GoogleFonts.inter(
                          color: AppColors.accentGreen,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      active ? CupertinoIcons.arrow_up_circle_fill : CupertinoIcons.pause_circle_fill,
                      color: active ? AppColors.accentGreen : Colors.white24,
                      size: 14.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      active
                          ? "+${c.formatSol(c.solPerSec)} SOL/sec"
                          : "Start mining to earn SOL",
                      style: GoogleFonts.spaceMono(
                        color: active ? Colors.white70 : Colors.white24,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (active)
                      Text(
                        "≈ \$${(c.liveSOL * c.solPrice).toStringAsFixed(4)}",
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 10.sp,
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
      color: AppColors.accentGreen.withOpacity(0.1),
    );
  }
}

// --- Cycle Progress Section with Lottie --------------------------------------------------------------
class CycleProgressSection extends StatelessWidget {
  final MiningController c;
  const CycleProgressSection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor;

    if (c.isMining) {
      statusText = "Mining in progress...";
      statusColor = AppColors.accentGreen;
    } else if (c.dayStarted) {
      statusText = "Paused • tap ORB to resume";
      statusColor = Colors.orange;
    } else {
      statusText = "Tap ORB to start mining";
      statusColor = AppColors.accentBlue;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: [
            AppColors.accentGreen.withOpacity(0.1),
            AppColors.surface,
          ],
        ),
        border: Border.all(
          color: AppColors.accentGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: Lottie.network(AppLottie.chart),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "\$18 → \$100 CYCLE",
                      style: GoogleFonts.inter(
                        color: AppColors.accentGreen,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Text(
                  "\$${c.liveUSD.toStringAsFixed(3)} / \$${kUsdTarget.toStringAsFixed(0)}",
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            LinearPercentIndicator(
              lineHeight: 8.h,
              percent: c.cycleProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.white10,
              linearGradient: const LinearGradient(
                colors: [AppColors.accentGreen, AppColors.accentPurple],
              ),
              barRadius: const Radius.circular(10),
              padding: EdgeInsets.zero,
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${(c.cycleProgress * 100).toStringAsFixed(2)}% complete",
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 10.sp,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

// --- Boost Info Section with Lottie --------------------------------------------------------------
class BoostInfoSection extends StatelessWidget {
  final MiningController c;
  final VoidCallback onBuyBoost;
  const BoostInfoSection({super.key, required this.c, required this.onBuyBoost});

  @override
  Widget build(BuildContext context) {
    final double boostPercent =
        ((c.boostMultiplier - 1.0) / (kNormalDays / kBoostDays - 1.0))
            .clamp(0.0, 1.0);
    final bool maxed = c.boostAmount >= 50;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: [
            AppColors.accentPurple.withOpacity(0.15),
            AppColors.surface,
          ],
        ),
        border: Border.all(
          color: AppColors.accentPurple.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: Lottie.network(AppLottie.rocket),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "BOOST  |  \$${c.boostAmount.toStringAsFixed(0)} invested",
                      style: GoogleFonts.inter(
                        color: AppColors.accentPurple,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "${c.boostMultiplier.toStringAsFixed(2)}x",
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: maxed ? null : onBuyBoost,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          gradient: maxed
                              ? null
                              : const LinearGradient(
                                  colors: [AppColors.accentPurple, Color(0xFFCC44FF)],
                                ),
                          color: maxed ? Colors.white12 : null,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: maxed
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.accentPurple.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Text(
                          maxed ? "MAXED" : "+ BUY",
                          style: GoogleFonts.inter(
                            color: maxed ? Colors.white38 : Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
            LinearPercentIndicator(
              lineHeight: 6.h,
              percent: boostPercent,
              backgroundColor: Colors.white10,
              linearGradient: const LinearGradient(
                colors: [AppColors.accentPurple, Color(0xFFCC44FF)],
              ),
              barRadius: const Radius.circular(10),
              padding: EdgeInsets.zero,
            ),
            SizedBox(height: 10.h),
            Text(
              "360 days → $kBoostDays days  |  AI: ${c.aiMultiplier.toStringAsFixed(2)}x  |  Speed: ${c.boostMultiplier.toStringAsFixed(2)}x",
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}

// --- Auto Mining Card with Lottie --------------------------------------------------------------
class AutoMiningCard extends StatelessWidget {
  final MiningController c;
  final VoidCallback onBuyAuto;
  const AutoMiningCard({super.key, required this.c, required this.onBuyAuto});

  @override
  Widget build(BuildContext context) {
    final bool active = c.autoMining;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: [
            (active ? AppColors.accentGreen : Colors.white).withOpacity(active ? 0.15 : 0.05),
            AppColors.surface,
          ],
        ),
        border: Border.all(
          color: (active ? AppColors.accentGreen : Colors.white54).withOpacity(active ? 0.4 : 0.2),
          width: active ? 2 : 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.accentGreen.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.h,
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
                  width: 28.w,
                  height: 28.h,
                  child: Lottie.network(
                    active ? AppLottie.shield : AppLottie.bolt,
                    repeat: active,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    active ? "AUTO MINING ACTIVE" : "AUTO MINING",
                    style: GoogleFonts.inter(
                      color: active ? AppColors.accentGreen : Colors.white54,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    active
                        ? "Mining resumes automatically each cycle"
                        : "One-time \$10 unlock • mines without tapping",
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PulseDot(color: AppColors.accentGreen),
                    SizedBox(width: 6.w),
                    Text(
                      "ON",
                      style: GoogleFonts.inter(
                        color: AppColors.accentGreen,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: onBuyAuto,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentGreen, Color(0xFF00CC88)],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGreen.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    "BUY \$10",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

// --- Withdrawable Section --------------------------------------------------------------
class WithdrawableSection extends StatelessWidget {
  final MiningController c;
  const WithdrawableSection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [
            AppColors.accentLeaf.withOpacity(0.15),
            AppColors.surface,
          ],
        ),
        border: Border.all(
          color: AppColors.accentLeaf.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentLeaf.withOpacity(0.2),
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  color: AppColors.accentLeaf,
                  size: 24.sp,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "WITHDRAWABLE BALANCE",
                    style: GoogleFonts.inter(
                      color: AppColors.accentLeaf,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "\$${c.withdrawableUSD.toStringAsFixed(2)} USD",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18.sp,
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

// --- Mining Orb with Lottie --------------------------------------------------------------
class MiningOrb extends StatelessWidget {
  final MiningController c;
  final VoidCallback onTap;
  const MiningOrb({super.key, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPaused = c.dayStarted && !c.isMining;

    IconData orbIcon;
    String orbLabel;
    String orbSub = '';
    Color orbIconColor;
    List<Color> borderColors;
    String lottieAsset;

    if (c.isMining && c.boostActive) {
      orbIcon = CupertinoIcons.rocket_fill;
      orbLabel = "BOOSTED";
      orbSub = "MINING";
      orbIconColor = AppColors.accentPurple;
      borderColors = [AppColors.accentPurple, AppColors.accentGreen];
      lottieAsset = AppLottie.rocket;
    } else if (c.isMining) {
      orbIcon = CupertinoIcons.hammer_fill;
      orbLabel = "MINING";
      orbIconColor = AppColors.accentGreen;
      borderColors = [AppColors.accentGreen, AppColors.accentPurple];
      lottieAsset = AppLottie.mining;
    } else if (isPaused) {
      orbIcon = CupertinoIcons.pause_fill;
      orbLabel = "PAUSED";
      orbSub = "Tap to resume";
      orbIconColor = Colors.orange;
      borderColors = [Colors.orange.withOpacity(0.6), Colors.white10];
      lottieAsset = AppLottie.pulse;
    } else {
      orbIcon = CupertinoIcons.bolt_fill;
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
              width: 170.w,
              height: 170.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (c.boostActive ? AppColors.accentPurple : AppColors.accentGreen)
                      .withOpacity(0.5),
                  width: 2,
                ),
              ),
            )
                .animate(onPlay: (ctrl) => ctrl.repeat())
                .rotate(duration: const Duration(seconds: 3))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.15, 1.15),
                  curve: Curves.easeInOutSine,
                )
                .then()
                .scale(begin: const Offset(1.15, 1.15), end: const Offset(1, 1)),

          // Boost ring
          if (c.isMining && c.boostActive)
            Container(
              width: 190.w,
              height: 190.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentPurple.withOpacity(0.3),
                  width: 1,
                ),
              ),
            )
                .animate(onPlay: (ctrl) => ctrl.repeat())
                .rotate(duration: const Duration(seconds: 5), begin: 1, end: 0),

          // Main orb
          Container(
            width: 150.w,
            height: 150.h,
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
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: borderColors[0].withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 50.w,
                      height: 50.h,
                      child: Lottie.network(lottieAsset, repeat: c.isMining),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      orbLabel,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (orbSub.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        orbSub,
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                    if (c.isMining) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: orbIconColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: orbIconColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          "+\$${c.usdPerSec.toStringAsFixed(6)}/s",
                          style: GoogleFonts.spaceMono(
                            color: orbIconColor,
                            fontSize: 10.sp,
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

// --- Buy Boost Bottom Sheet with Lottie --------------------------------------------------------------
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        border: Border(
          top: BorderSide(color: AppColors.accentPurple.withOpacity(0.3), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 40.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Header with Lottie
          Row(
            children: [
              SizedBox(
                width: 48.w,
                height: 48.h,
                child: Lottie.network(AppLottie.rocket),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "BUY SPEED BOOST",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "Invest \$1-\$50 to speed up mining",
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Info cards
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
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
          SizedBox(height: 24.h),

          // Amount selector
          Text(
            "Select Amount",
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentPurple,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              overlayColor: AppColors.accentPurple.withOpacity(0.2),
              trackHeight: 6,
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
          SizedBox(height: 16.h),

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
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    gradient: sel
                        ? const LinearGradient(colors: [AppColors.accentPurple, Color(0xFFCC44FF)])
                        : null,
                    color: sel ? null : Colors.white10,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: sel ? AppColors.accentPurple : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    "\$$val",
                    style: GoogleFonts.inter(
                      color: disabled ? Colors.white24 : (sel ? Colors.white : Colors.white70),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 24.h),

          // Preview
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.accentGreen.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.arrow_up_circle_fill, color: AppColors.accentGreen, size: 20.sp),
                SizedBox(width: 10.w),
                Text(
                  "New speed: ${_newMultiplier.toStringAsFixed(2)}x",
                  style: GoogleFonts.inter(
                    color: AppColors.accentGreen,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Error
          if (_error != null)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.accentRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.exclamationmark_circle, color: AppColors.accentRed, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.inter(color: AppColors.accentRed, fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 56.h,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: _loading || _remainingBoost < 1
                      ? null
                      : const LinearGradient(
                          colors: [AppColors.accentPurple, Color(0xFFCC44FF)],
                        ),
                  color: _loading || _remainingBoost < 1 ? Colors.white12 : null,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: _loading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.h,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _remainingBoost < 1 ? "MAX BOOST REACHED" : "CONFIRM \$${_amount.toStringAsFixed(0)} BOOST",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 11.sp),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.inter(
            color: valueColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40.h,
        color: Colors.white12,
      );
}

// --- Buy Auto Mining Sheet with Lottie --------------------------------------------------------------
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        border: Border(
          top: BorderSide(color: AppColors.accentGreen.withOpacity(0.3), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 40.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 24.h),

          // Icon with Lottie
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.accentGreen, Color(0xFF00CC88)],
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 50.w,
                height: 50.h,
                child: Lottie.network(AppLottie.shield),
              ),
            ),
          ),
          SizedBox(height: 20.h),

          Text(
            "Enable Auto Mining",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "One-time \$10 unlock. Mining restarts automatically after each cycle.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 24.h),

          // Features
          ...[
            _featureRow(CupertinoIcons.checkmark_circle_fill, "Auto-restart after every \$100 cycle", AppColors.accentGreen),
            _featureRow(CupertinoIcons.checkmark_circle_fill, "No manual tap required", AppColors.accentGreen),
            _featureRow(CupertinoIcons.checkmark_circle_fill, "Works with boost multipliers", AppColors.accentGreen),
          ],
          SizedBox(height: 24.h),

          // Price
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Unlock Cost",
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14.sp),
                ),
                Text(
                  "\$10.00",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Error
          if (_error != null)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.accentRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.exclamationmark_circle, color: AppColors.accentRed, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.inter(color: AppColors.accentRed, fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Button
          SizedBox(
            width: double.infinity,
            height: 56.h,
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
                          _error = "Purchase failed. Need \$10 balance.";
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: _loading
                      ? null
                      : const LinearGradient(
                          colors: [AppColors.accentGreen, Color(0xFF00CC88)],
                        ),
                  color: _loading ? Colors.white12 : null,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: _loading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.h,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "UNLOCK FOR \$10",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String text, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14.sp,
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

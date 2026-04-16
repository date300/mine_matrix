import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../constants/mining_constants.dart';
import '../controllers/mining_controller.dart';

// NOTE: AppColors is imported from mining_constants.dart

// ---------------------------------------------------------------------------
// Lottie URLs (এগুলো ঠিক আছে)
// ---------------------------------------------------------------------------
class AppLottie {
  static const String mining   = 'https://assets10.lottiefiles.com/packages/lf20_w51pcehl.json';
  static const String rocket   = 'https://assets10.lottiefiles.com/packages/lf20_96bovdur.json';
  static const String bolt     = 'https://assets10.lottiefiles.com/packages/lf20_7z8wtyb0.json';
  static const String pulse    = 'https://assets10.lottiefiles.com/packages/lf20_b88nh30c.json';
  static const String coin     = 'https://assets10.lottiefiles.com/packages/lf20_6wutsrox.json';
  static const String shield   = 'https://assets10.lottiefiles.com/packages/lf20_5njp3vgg.json';
  static const String hammer   = 'https://assets10.lottiefiles.com/packages/lf20_3s913D.json';
}

// ---------------------------------------------------------------------------
// _SectionLabel (ঠিক আছে)
// ---------------------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Container(width: 3.w, height: 14.h,
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                borderRadius: BorderRadius.circular(2.r),
              )),
          SizedBox(width: 8.w),
          Text(text,
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pulse Dot (ঠিক আছে)
// ---------------------------------------------------------------------------
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 7.w, height: 7.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [BoxShadow(color: widget.color.withOpacity(0.6), blurRadius: 6, spreadRadius: 1)],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ✅ LiveEarningsCard - padding parameter যোগ করা হয়েছে
// ---------------------------------------------------------------------------
class LiveEarningsCard extends StatelessWidget {
  final MiningController c;
  final double padding; // ✅ নতুন parameter
  
  const LiveEarningsCard({
    super.key, 
    required this.c,
    this.padding = 16, // ✅ ডিফল্ট মান
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentGreen.withOpacity(0.12),
            AppColors.bgCard,
          ],
        ),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(color: AppColors.accentGreen.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding.w, vertical: (padding - 2).h), // ✅ padding ব্যবহার
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: label + amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LIVE badge
                      Row(
                        children: [
                          SizedBox(
                            width: 14.w, height: 14.h,
                            child: Lottie.network(AppLottie.pulse, repeat: true),
                          ),
                          SizedBox(width: 6.w),
                          Text("LIVE EARNINGS",
                            style: GoogleFonts.inter(
                              color: AppColors.accentGreen,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "\$${c.liveUSD.toStringAsFixed(4)}",
                            style: GoogleFonts.spaceMono(
                              color: Colors.white,
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Padding(
                            padding: EdgeInsets.only(bottom: 3.h),
                            child: Text("USD",
                              style: GoogleFonts.inter(
                                color: AppColors.accentGreen,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right: withdrawable pill
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Withdrawable",
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp, letterSpacing: 0.5)),
                    SizedBox(height: 4.h),
                    Text("\$${c.withdrawableUSD.toStringAsFixed(2)}",
                      style: GoogleFonts.spaceMono(
                        color: Colors.white70, fontSize: 14.sp, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                      ),
                      child: Text(
                        "${(c.cycleProgress * 100).clamp(0, 100).toStringAsFixed(1)}% to \$100",
                        style: GoogleFonts.inter(
                          color: AppColors.accentGreen, fontSize: 9.sp, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.08);
  }
}

// ---------------------------------------------------------------------------
// ✅ SolanaLiveCard - padding parameter যোগ করা হয়েছে
// ---------------------------------------------------------------------------
class SolanaLiveCard extends StatelessWidget {
  final MiningController c;
  final double padding; // ✅ নতুন parameter
  
  const SolanaLiveCard({
    super.key, 
    required this.c,
    this.padding = 16, // ✅ ডিফল্ট মান
  });

  @override
  Widget build(BuildContext context) {
    final bool active = c.isMining;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentPurple.withOpacity(active ? 0.15 : 0.06),
            AppColors.bgCard,
          ],
        ),
        border: Border.all(
          color: AppColors.accentPurple.withOpacity(active ? 0.35 : 0.18),
          width: active ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding.w, vertical: (padding - 4).h), // ✅ padding ব্যবহার
            child: Row(
              children: [
                // Icon: Solana currency icon
                Container(
                  width: 42.w, height: 42.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.accentPurple, AppColors.accentGreen],
                    ),
                  ),
                  child: Icon(CupertinoIcons.circle_fill,
                    color: Colors.white.withOpacity(0.9), size: 20.sp),
                ),
                SizedBox(width: 14.w),
                // Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("SOLANA MINING",
                        style: GoogleFonts.inter(
                          color: AppColors.accentPurple,
                          fontSize: 10.sp, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                      SizedBox(height: 2.h),
                      Text("1 SOL = \$${c.solPrice.toStringAsFixed(2)}",
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp)),
                    ],
                  ),
                ),
                // Right: SOL amount + rate
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(c.formatSol(c.liveSOL),
                      style: GoogleFonts.spaceMono(
                        color: active ? AppColors.accentGreen : Colors.white38,
                        fontSize: 18.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4.h),
                    if (active)
                      Row(
                        children: [
                          PulseDot(color: AppColors.accentGreen),
                          SizedBox(width: 5.w),
                          Text("+${c.formatSol(c.solPerSec)}/s",
                            style: GoogleFonts.spaceMono(
                              color: Colors.white54, fontSize: 9.sp)),
                        ],
                      )
                    else
                      Text("Paused",
                        style: GoogleFonts.inter(color: Colors.white24, fontSize: 9.sp)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(target: active ? 1.0 : 0.0)
        .shimmer(duration: const Duration(milliseconds: 2000),
            color: AppColors.accentGreen.withOpacity(0.08));
  }
}

// ---------------------------------------------------------------------------
// ✅ CycleProgressSection - padding parameter যোগ করা হয়েছে
// ---------------------------------------------------------------------------
class CycleProgressSection extends StatelessWidget {
  final MiningController c;
  final double padding; // ✅ নতুন parameter
  
  const CycleProgressSection({
    super.key, 
    required this.c,
    this.padding = 16, // ✅ ডিফল্ট মান
  });

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (c.isMining) {
      statusText = "Mining active";
      statusColor = AppColors.accentGreen;
      statusIcon = CupertinoIcons.arrow_up_circle_fill;
    } else if (c.dayStarted) {
      statusText = "Paused";
      statusColor = Colors.orange;
      statusIcon = CupertinoIcons.pause_circle_fill;
    } else {
      statusText = "Tap ORB to start";
      statusColor = AppColors.accentPurple;
      statusIcon = CupertinoIcons.power;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: AppColors.bgCard,
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding.w, vertical: (padding - 2).h), // ✅ padding ব্যবহার
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.chart_bar_fill,
                      color: AppColors.accentGreen, size: 14.sp),
                    SizedBox(width: 7.w),
                    Text("\$18 → \$100 CYCLE",
                      style: GoogleFonts.inter(
                        color: AppColors.accentGreen,
                        fontSize: 10.sp, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                  ],
                ),
                Text("\$${c.liveUSD.toStringAsFixed(3)} / \$${kUsdTarget.toStringAsFixed(0)}",
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp)),
              ],
            ),
            SizedBox(height: 14.h),
            // Progress bar
            LinearPercentIndicator(
              lineHeight: 7.h,
              percent: c.cycleProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.white10,
              linearGradient: const LinearGradient(
                  colors: [AppColors.accentGreen, AppColors.accentPurple]),
              barRadius: const Radius.circular(10),
              padding: EdgeInsets.zero,
            ),
            SizedBox(height: 10.h),
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${(c.cycleProgress * 100).toStringAsFixed(2)}% complete",
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp)),
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 11.sp),
                    SizedBox(width: 4.w),
                    Text(statusText,
                      style: GoogleFonts.inter(
                        color: statusColor, fontSize: 10.sp, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.08);
  }
}

// ---------------------------------------------------------------------------
// ✅ BoostInfoSection - padding parameter যোগ করা হয়েছে
// ---------------------------------------------------------------------------
class BoostInfoSection extends StatelessWidget {
  final MiningController c;
  final VoidCallback onBuyBoost;
  final double padding; // ✅ নতুন parameter
  
  const BoostInfoSection({
    super.key, 
    required this.c, 
    required this.onBuyBoost,
    this.padding = 16, // ✅ ডিফল্ট মান
  });

  @override
  Widget build(BuildContext context) {
    final double boostPercent =
        ((c.boostMultiplier - 1.0) / (kNormalDays / kBoostDays - 1.0)).clamp(0.0, 1.0);
    final bool maxed = c.boostAmount >= 50;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.accentPurple.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding.w, vertical: (padding - 2).h), // ✅ padding ব্যবহার
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.rocket_fill,
                      color: AppColors.accentPurple, size: 14.sp),
                    SizedBox(width: 7.w),
                    Text("BOOST",
                      style: GoogleFonts.inter(
                        color: AppColors.accentPurple,
                        fontSize: 10.sp, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                    SizedBox(width: 8.w),
                    Text("\$${c.boostAmount.toStringAsFixed(0)} invested",
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text("${c.boostMultiplier.toStringAsFixed(2)}x",
                        style: GoogleFonts.spaceMono(
                          color: AppColors.accentPurple, fontSize: 11.sp, fontWeight: FontWeight.w700)),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: maxed ? null : onBuyBoost,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          gradient: maxed
                              ? null
                              : const LinearGradient(
                                  colors: [AppColors.accentPurple, Color(0xFFCC44FF)]),
                          color: maxed ? Colors.white10 : null,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          maxed ? "MAXED" : "+ BUY",
                          style: GoogleFonts.inter(
                            color: maxed ? Colors.white24 : Colors.white,
                            fontSize: 10.sp, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
            LinearPercentIndicator(
              lineHeight: 5.h,
              percent: boostPercent,
              backgroundColor: Colors.white10,
              linearGradient: const LinearGradient(
                  colors: [AppColors.accentPurple, Color(0xFFCC44FF)]),
              barRadius: const Radius.circular(10),
              padding: EdgeInsets.zero,
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(CupertinoIcons.speedometer, color: Colors.white24, size: 11.sp),
                SizedBox(width: 5.w),
                Text(
                  "AI: ${c.aiMultiplier.toStringAsFixed(2)}x  •  Speed: ${c.boostMultiplier.toStringAsFixed(2)}x",
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp)),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.08);
  }
}

// ---------------------------------------------------------------------------
// ✅ AutoMiningCard - padding parameter যোগ করা হয়েছে
// ---------------------------------------------------------------------------
class AutoMiningCard extends StatelessWidget {
  final MiningController c;
  final VoidCallback onBuyAuto;
  final double padding; // ✅ নতুন parameter
  
  const AutoMiningCard({
    super.key, 
    required this.c, 
    required this.onBuyAuto,
    this.padding = 16, // ✅ ডিফল্ট মান
  });

  @override
  Widget build(BuildContext context) {
    final bool active = c.autoMining;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: AppColors.bgCard,
        border: Border.all(
          color: active
              ? AppColors.accentGreen.withOpacity(0.4)
              : Colors.white12,
          width: active ? 1.5 : 1,
        ),
        boxShadow: active
            ? [BoxShadow(color: AppColors.accentGreen.withOpacity(0.12),
                blurRadius: 16, offset: const Offset(0, 6))]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding.w, vertical: (padding - 4).h), // ✅ padding ব্যবহার
        child: Row(
          children: [
            // Icon
            Container(
              width: 40.w, height: 40.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? AppColors.accentGreen.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: active
                      ? AppColors.accentGreen.withOpacity(0.4)
                      : Colors.white12),
              ),
              child: Icon(
                active ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.shield,
                color: active ? AppColors.accentGreen : Colors.white38,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(active ? "AUTO MINING ACTIVE" : "AUTO MINING",
                    style: GoogleFonts.inter(
                      color: active ? AppColors.accentGreen : Colors.white54,
                      fontSize: 11.sp, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                  SizedBox(height: 3.h),
                  Text(
                    active
                        ? "Restarts automatically each cycle"
                        : "One-time \$10 unlock",
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp)),
                ],
              ),
            ),
            if (active)
              Row(
                children: [
                  PulseDot(color: AppColors.accentGreen),
                  SizedBox(width: 6.w),
                  Text("ON",
                    style: GoogleFonts.inter(
                      color: AppColors.accentGreen, fontSize: 11.sp, fontWeight: FontWeight.w800)),
                ],
              )
            else
              GestureDetector(
                onTap: onBuyAuto,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.accentGreen, Color(0xFF00CC88)]),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text("BUY \$10",
                    style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.08);
  }
}

// ---------------------------------------------------------------------------
// ✅ WithdrawableSection - আগে থেকেই ভালো আছে, কিন্তু padding যোগ করা হলো
// ---------------------------------------------------------------------------
class WithdrawableSection extends StatelessWidget {
  final MiningController c;
  final double padding; // ✅ নতুন parameter
  
  const WithdrawableSection({
    super.key, 
    required this.c,
    this.padding = 16, // ✅ ডিফল্ট মান
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: [
            AppColors.accentLeaf.withOpacity(0.12),
            AppColors.bgCard,
          ],
        ),
        border: Border.all(color: AppColors.accentLeaf.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding.w, vertical: (padding - 4).h), // ✅ padding ব্যবহার
        child: Row(
          children: [
            Container(
              width: 40.w, height: 40.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentLeaf.withOpacity(0.15),
              ),
              child: Icon(CupertinoIcons.checkmark_seal_fill,
                color: AppColors.accentLeaf, size: 20.sp),
            ),
            SizedBox(width: 14.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("WITHDRAWABLE BALANCE",
                  style: GoogleFonts.inter(
                    color: AppColors.accentLeaf,
                    fontSize: 9.sp, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                SizedBox(height: 4.h),
                Text("\$${c.withdrawableUSD.toStringAsFixed(2)} USD",
                  style: GoogleFonts.spaceMono(
                    color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}

// ---------------------------------------------------------------------------
// ✅ MiningOrb - size parameter যোগ করা হয়েছে
// ---------------------------------------------------------------------------
class MiningOrb extends StatelessWidget {
  final MiningController c;
  final VoidCallback onTap;
  final double? size; // ✅ নতুন optional parameter
  
  const MiningOrb({
    super.key, 
    required this.c, 
    required this.onTap,
    this.size, // ✅ যদি না দেওয়া হয়, তাহলে default ব্যবহার হবে
  });

  @override
  Widget build(BuildContext context) {
    final isPaused = c.dayStarted && !c.isMining;

    String orbLabel, orbSub = '';
    Color orbAccent;
    List<Color> borderColors;
    String lottieAsset;

    if (c.isMining && c.boostActive) {
      orbLabel = "BOOSTED"; orbSub = "MINING";
      orbAccent = AppColors.accentPurple;
      borderColors = [AppColors.accentPurple, AppColors.accentGreen];
      lottieAsset = AppLottie.rocket;
    } else if (c.isMining) {
      orbLabel = "MINING";
      orbAccent = AppColors.accentGreen;
      borderColors = [AppColors.accentGreen, AppColors.accentPurple];
      lottieAsset = AppLottie.mining;
    } else if (isPaused) {
      orbLabel = "PAUSED"; orbSub = "Tap to resume";
      orbAccent = Colors.orange;
      borderColors = [Colors.orange.withOpacity(0.6), Colors.white10];
      lottieAsset = AppLottie.pulse;
    } else {
      orbLabel = "START"; orbSub = "Tap to mine";
      orbAccent = Colors.white70;
      borderColors = [Colors.white38, Colors.white10];
      lottieAsset = AppLottie.bolt;
    }

    // ✅ size না দিলে default মান ব্যবহার করবে
    final double orbSize = size ?? 150.w;
    final double outerRingSize = orbSize * 1.13; // 170/150 = 1.13
    final double outerRing2Size = orbSize * 1.28; // 192/150 = 1.28

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring animation
          if (c.isMining)
            Container(
              width: outerRingSize,
              height: outerRingSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (c.boostActive ? AppColors.accentPurple : AppColors.accentGreen).withOpacity(0.4),
                  width: 1.5,
                ),
              ),
            ).animate(onPlay: (ctrl) => ctrl.repeat())
                .rotate(duration: const Duration(seconds: 3))
                .scale(begin: const Offset(1, 1), end: const Offset(1.12, 1.12),
                    curve: Curves.easeInOutSine)
                .then()
                .scale(begin: const Offset(1.12, 1.12), end: const Offset(1, 1)),

          if (c.isMining && c.boostActive)
            Container(
              width: outerRing2Size,
              height: outerRing2Size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentPurple.withOpacity(0.2), width: 1),
              ),
            ).animate(onPlay: (ctrl) => ctrl.repeat())
                .rotate(duration: const Duration(seconds: 5), begin: 1, end: 0),

          // Main orb
          Container(
            width: orbSize,
            height: orbSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.85), Colors.black.withOpacity(0.4)]),
              border: Border.all(color: borderColors[0], width: 2),
              boxShadow: [BoxShadow(
                color: borderColors[0].withOpacity(0.3), blurRadius: 28, spreadRadius: 4)],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Lottie
                    SizedBox(
                      width: orbSize * 0.33, // 50/150 = 0.33
                      height: orbSize * 0.33,
                      child: Lottie.network(lottieAsset, repeat: c.isMining),
                    ),
                    SizedBox(height: orbSize * 0.04), // 6/150 = 0.04
                    Text(orbLabel,
                      style: GoogleFonts.inter(
                        color: Colors.white, fontSize: (orbSize * 0.1).sp, // 15/150 = 0.1
                        fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                    if (orbSub.isNotEmpty) ...[
                      SizedBox(height: orbSize * 0.02), // 3/150 = 0.02
                      Text(orbSub,
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: (orbSize * 0.067).sp)), // 10/150 = 0.067
                    ],
                    if (c.isMining) ...[
                      SizedBox(height: orbSize * 0.04), // 6/150 = 0.04
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: orbSize * 0.053, // 8/150 = 0.053
                          vertical: orbSize * 0.02, // 3/150 = 0.02
                        ),
                        decoration: BoxDecoration(
                          color: orbAccent.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: orbAccent.withOpacity(0.3)),
                        ),
                        child: Text("+\$${c.usdPerSec.toStringAsFixed(6)}/s",
                          style: GoogleFonts.spaceMono(
                            color: orbAccent, fontSize: (orbSize * 0.06).sp, fontWeight: FontWeight.w700)), // 9/150 = 0.06
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

// ---------------------------------------------------------------------------
// Buy Boost Bottom Sheet (ঠিক আছে, কোনো পরিবর্তন লাগবে না)
// ---------------------------------------------------------------------------
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
    const baseDays = 360.0, minDays = 80.0;
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
        border: Border(top: BorderSide(color: AppColors.accentPurple.withOpacity(0.25), width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 40.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36.w, height: 4.h,
              decoration: BoxDecoration(color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r)),
            ),
          ),
          SizedBox(height: 24.h),

          // Header
          Row(
            children: [
              Container(
                width: 48.w, height: 48.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [AppColors.accentPurple, Color(0xFFCC44FF)]),
                ),
                child: Icon(CupertinoIcons.rocket_fill, color: Colors.white, size: 22.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("BUY SPEED BOOST",
                      style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w800)),
                    Text("Invest \$1-\$50 to speed up mining",
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 12.sp)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 22.h),

          // Info cards
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.accentPurple.withOpacity(0.18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoItem("Invested", "\$${widget.c.boostAmount.toStringAsFixed(0)}", AppColors.accentPurple),
                _divider(),
                _infoItem("Remaining", "\$${_remainingBoost.toStringAsFixed(0)}", Colors.white54),
                _divider(),
                _infoItem("Speed", "${widget.c.boostMultiplier.toStringAsFixed(2)}x", AppColors.accentGreen),
              ],
            ),
          ),
          SizedBox(height: 22.h),

          Text("Select Amount",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 10.h),

          // Preview multiplier
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Text(
                "\$${_amount.toStringAsFixed(0)}  →  ${_newMultiplier.toStringAsFixed(2)}x speed",
                style: GoogleFonts.spaceMono(
                  color: AppColors.accentPurple, fontSize: 13.sp, fontWeight: FontWeight.w700)),
            ),
          ),
          SizedBox(height: 10.h),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentPurple,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              overlayColor: AppColors.accentPurple.withOpacity(0.15),
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
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    gradient: sel ? const LinearGradient(
                        colors: [AppColors.accentPurple, Color(0xFFCC44FF)]) : null,
                    color: sel ? null : (disabled ? Colors.white.withOpacity(0.03) : Colors.white10),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text("\$$val",
                    style: GoogleFonts.inter(
                      color: disabled ? Colors.white12 : (sel ? Colors.white : Colors.white70),
                      fontSize: 13.sp, fontWeight: FontWeight.w700)),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20.h),

          if (_error != null)
            Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.red.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.exclamationmark_circle, color: Colors.red, size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(child: Text(_error!,
                    style: GoogleFonts.inter(color: Colors.red, fontSize: 12.sp))),
                ],
              ),
            ),

          SizedBox(
            width: double.infinity, height: 52.h,
            child: ElevatedButton(
              onPressed: _loading ? null : () async {
                setState(() { _loading = true; _error = null; });
                final ok = await widget.onConfirm(_amount);
                if (!mounted) return;
                if (ok) {
                  Navigator.pop(context);
                } else {
                  setState(() { _loading = false; _error = "Purchase failed. Need \$${_amount.toStringAsFixed(0)} balance."; });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: _loading ? null : const LinearGradient(
                      colors: [AppColors.accentPurple, Color(0xFFCC44FF)]),
                  color: _loading ? Colors.white12 : null,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Center(
                  child: _loading
                      ? SizedBox(width: 22.w, height: 22.h,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("BOOST  \$${_amount.toStringAsFixed(0)}",
                          style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: GoogleFonts.spaceMono(color: color, fontSize: 14.sp, fontWeight: FontWeight.w700)),
      SizedBox(height: 2.h),
      Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp)),
    ]);
  }

  Widget _divider() => Container(width: 1, height: 28.h, color: Colors.white10);
}

// ---------------------------------------------------------------------------
// Buy Auto Mining Bottom Sheet (ঠিক আছে)
// ---------------------------------------------------------------------------
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
        border: Border(top: BorderSide(color: AppColors.accentGreen.withOpacity(0.25), width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 40.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36.w, height: 4.h,
              decoration: BoxDecoration(color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r)),
            ),
          ),
          SizedBox(height: 24.h),

          // Icon
          Container(
            width: 72.w, height: 72.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [AppColors.accentGreen, Color(0xFF00CC88)]),
            ),
            child: Icon(CupertinoIcons.checkmark_shield_fill,
              color: Colors.white, size: 32.sp),
          ),
          SizedBox(height: 18.h),

          Text("Enable Auto Mining",
            style: GoogleFonts.inter(
              color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w800)),
          SizedBox(height: 6.h),
          Text("One-time \$10 unlock. Mining restarts automatically after each cycle.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 13.sp, height: 1.5)),
          SizedBox(height: 22.h),

          // Feature rows
          _featureRow(CupertinoIcons.checkmark_circle_fill,
              "Auto-restart after every \$100 cycle", AppColors.accentGreen),
          _featureRow(CupertinoIcons.checkmark_circle_fill,
              "No manual tap required", AppColors.accentGreen),
          _featureRow(CupertinoIcons.checkmark_circle_fill,
              "Works with boost multipliers", AppColors.accentGreen),
          SizedBox(height: 20.h),

          // Price row
          Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Unlock Cost",
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 14.sp)),
                Text("\$10.00",
                  style: GoogleFonts.spaceMono(
                    color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          if (_error != null)
            Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.red.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.exclamationmark_circle, color: Colors.red, size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(child: Text(_error!,
                    style: GoogleFonts.inter(color: Colors.red, fontSize: 12.sp))),
                ],
              ),
            ),

          SizedBox(
            width: double.infinity, height: 52.h,
            child: ElevatedButton(
              onPressed: _loading ? null : () async {
                setState(() { _loading = true; _error = null; });
                final ok = await widget.onConfirm();
                if (!mounted) return;
                if (ok) {
                  Navigator.pop(context);
                } else {
                  setState(() { _loading = false; _error = "Purchase failed. Need \$10 balance."; });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: _loading ? null : const LinearGradient(
                      colors: [AppColors.accentGreen, Color(0xFF00CC88)]),
                  color: _loading ? Colors.white12 : null,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Center(
                  child: _loading
                      ? SizedBox(width: 22.w, height: 22.h,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("UNLOCK FOR \$10",
                          style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w800)),
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
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(width: 12.w),
          Expanded(child: Text(text,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13.sp))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper functions (ঠিক আছে)
// ---------------------------------------------------------------------------
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

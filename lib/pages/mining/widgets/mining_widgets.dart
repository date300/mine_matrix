 import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_background/animated_background.dart';
import '../constants/mining_constants.dart';
import '../controllers/mining_controller.dart';

// ═══════════════════════════════════════════════════════════════
// Pulse Dot
// ═══════════════════════════════════════════════════════════════
class PulseDot extends StatefulWidget {
  final Color color;
  const PulseDot({super.key, required this.color});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
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
          width: 7.w,
          height: 7.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                  color: widget.color.withOpacity(0.6), blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Live Earnings Card (USD)
// ═══════════════════════════════════════════════════════════════
class LiveEarningsCard extends StatelessWidget {
  final MiningController c;
  const LiveEarningsCard({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 115.h,
      borderRadius: 20.r,
      blur: 20,
      alignment: Alignment.center,
      border: 0.5,
      linearGradient: LinearGradient(colors: [
        AppColors.accentGreen.withOpacity(0.05),
        Colors.white.withOpacity(0.02),
      ]),
      borderGradient: LinearGradient(colors: [
        AppColors.accentGreen.withOpacity(0.2),
        Colors.transparent,
      ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("LIVE EARNINGS",
              style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2)),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("\$${c.liveUSD.toStringAsFixed(4)}",
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold)),
              SizedBox(width: 5.w),
              Padding(
                padding: EdgeInsets.only(bottom: 3.h),
                child: Text("USD",
                    style: GoogleFonts.inter(
                        color: AppColors.accentGreen,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Text(
            "Withdrawable: \$${c.withdrawableUSD.toStringAsFixed(2)}"
            "  |  ${(c.cycleProgress * 100).clamp(0, 100).toStringAsFixed(1)}% to \$100",
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }
}

// ═══════════════════════════════════════════════════════════════
// Solana Live Card
// ═══════════════════════════════════════════════════════════════
class SolanaLiveCard extends StatelessWidget {
  final MiningController c;
  const SolanaLiveCard({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final bool active = c.isMining;

    return GlassmorphicContainer(
      width: double.infinity,
      height: 130.h,
      borderRadius: 20.r,
      blur: 20,
      alignment: Alignment.center,
      border: active ? 1.0 : 0.5,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.accentPurple.withOpacity(active ? 0.12 : 0.04),
          AppColors.accentGreen.withOpacity(active ? 0.06 : 0.02),
        ],
      ),
      borderGradient: LinearGradient(colors: [
        AppColors.accentPurple.withOpacity(active ? 0.5 : 0.15),
        AppColors.accentGreen.withOpacity(active ? 0.3 : 0.08),
      ]),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 22.w,
                height: 22.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.accentPurple, AppColors.accentGreen],
                  ),
                ),
                child: Center(
                  child: Text("◎",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(width: 7.w),
              Text("SOLANA MINING",
                  style: GoogleFonts.inter(
                      color: AppColors.accentPurple,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0)),
              const Spacer(),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                      color: AppColors.accentPurple.withOpacity(0.3)),
                ),
                child: Text(
                  "1 SOL = \$${c.solPrice.toStringAsFixed(2)}",
                  style: GoogleFonts.inter(
                      color: AppColors.accentPurple,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ]),
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
                          color: active
                              ? AppColors.accentGreen
                              : Colors.white38,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Text("SOL",
                      style: GoogleFonts.inter(
                          color: AppColors.accentGreen,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(children: [
              if (active)
                PulseDot(color: AppColors.accentGreen)
              else
                Container(
                  width: 7.w,
                  height: 7.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white24,
                  ),
                ),
              SizedBox(width: 6.w),
              Text(
                active
                    ? "+${c.formatSol(c.solPerSec)} SOL/sec"
                    : "Start mining to earn SOL",
                style: GoogleFonts.spaceMono(
                    color: active ? Colors.white60 : Colors.white24,
                    fontSize: 9.sp),
              ),
              const Spacer(),
              if (active)
                Text(
                  "≈ \$${(c.liveSOL * c.solPrice).toStringAsFixed(4)}",
                  style:
                      GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp),
                ),
            ]),
          ],
        ),
      ),
    )
        .animate(target: active ? 1.0 : 0.0)
        .shimmer(
            duration: const Duration(milliseconds: 2000),
            color: AppColors.accentGreen.withOpacity(0.06));
  }
}

// ═══════════════════════════════════════════════════════════════
// Cycle Progress Section
// ═══════════════════════════════════════════════════════════════
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
      statusText = "Paused · tap ORB to resume";
      statusColor = Colors.orange;
    } else {
      statusText = "Tap ORB to start mining";
      statusColor = AppColors.accentGreen.withOpacity(0.85);
    }

    return GlassmorphicContainer(
      width: double.infinity,
      height: 82.h,
      borderRadius: 16.r,
      blur: 10,
      alignment: Alignment.center,
      border: 0.5,
      linearGradient: LinearGradient(colors: [
        AppColors.accentGreen.withOpacity(0.06),
        Colors.white.withOpacity(0.02),
      ]),
      borderGradient: LinearGradient(colors: [
        AppColors.accentGreen.withOpacity(0.35),
        Colors.transparent,
      ]),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(CupertinoIcons.chart_bar_fill,
                      color: AppColors.accentGreen, size: 10.sp),
                  SizedBox(width: 4.w),
                  Text("\$18 → \$100 CYCLE",
                      style: GoogleFonts.inter(
                          color: AppColors.accentGreen,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8)),
                ]),
                Flexible(
                  child: Text(
                    "\$${c.liveUSD.toStringAsFixed(3)} / \$${kUsdTarget.toStringAsFixed(0)}",
                    style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: 9.sp),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
          SizedBox(height: 6.h),
          LinearPercentIndicator(
            lineHeight: 5.h,
            percent: c.cycleProgress.clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            linearGradient: const LinearGradient(
                colors: [AppColors.accentGreen, AppColors.accentPurple]),
            barRadius: const Radius.circular(10),
            padding: EdgeInsets.zero,
          ),
          SizedBox(height: 5.h),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    "${(c.cycleProgress * 100).toStringAsFixed(2)}% complete",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 9.sp)),
                Flexible(
                  child: Text(statusText,
                      style: GoogleFonts.inter(
                          color: statusColor,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Boost Info Section  (with Buy More Boost button)
// ═══════════════════════════════════════════════════════════════
class BoostInfoSection extends StatelessWidget {
  final MiningController c;
  final VoidCallback onBuyBoost; // opens BuyBoostSheet
  const BoostInfoSection(
      {super.key, required this.c, required this.onBuyBoost});

  @override
  Widget build(BuildContext context) {
    final double boostPercent =
        ((c.boostMultiplier - 1.0) / (kNormalDays / kBoostDays - 1.0))
            .clamp(0.0, 1.0);
    final bool maxed = c.boostAmount >= 50;

    return GlassmorphicContainer(
      width: double.infinity,
      height: 90.h,
      borderRadius: 16.r,
      blur: 10,
      alignment: Alignment.center,
      border: 0.5,
      linearGradient: LinearGradient(colors: [
        AppColors.accentPurple.withOpacity(0.08),
        Colors.white.withOpacity(0.02),
      ]),
      borderGradient: LinearGradient(colors: [
        AppColors.accentPurple.withOpacity(0.4),
        Colors.transparent,
      ]),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // — Row 1: label + multiplier + buy button
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(CupertinoIcons.rocket_fill,
                      color: AppColors.accentPurple, size: 10.sp),
                  SizedBox(width: 4.w),
                  Text(
                    "BOOST  |  \$${c.boostAmount.toStringAsFixed(0)} invested",
                    style: GoogleFonts.inter(
                        color: AppColors.accentPurple,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8),
                  ),
                ]),
                Row(children: [
                  Text("${c.boostMultiplier.toStringAsFixed(2)}x",
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 9.sp)),
                  SizedBox(width: 6.w),
                  // ── Buy / Maxed button ──
                  GestureDetector(
                    onTap: maxed ? null : onBuyBoost,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 9.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        gradient: maxed
                            ? null
                            : const LinearGradient(colors: [
                                AppColors.accentPurple,
                                Color(0xFFCC44FF),
                              ]),
                        color: maxed
                            ? Colors.white12
                            : null,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        maxed ? "MAXED" : "+ BUY",
                        style: GoogleFonts.inter(
                            color: maxed
                                ? Colors.white38
                                : Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ]),
              ]),
          SizedBox(height: 6.h),
          // — Row 2: progress bar
          LinearPercentIndicator(
            lineHeight: 5.h,
            percent: boostPercent,
            backgroundColor: Colors.white10,
            linearGradient: const LinearGradient(
                colors: [AppColors.accentPurple, Color(0xFFCC44FF)]),
            barRadius: const Radius.circular(10),
            padding: EdgeInsets.zero,
          ),
          SizedBox(height: 5.h),
          // — Row 3: info text
          Text(
            "360 days → $kBoostDays days  |  AI: ${c.aiMultiplier.toStringAsFixed(2)}x  |  Speed: ${c.boostMultiplier.toStringAsFixed(2)}x",
            style:
                GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Auto Mining Card  (buy or status)
// ═══════════════════════════════════════════════════════════════
class AutoMiningCard extends StatelessWidget {
  final MiningController c;
  final VoidCallback onBuyAuto;
  const AutoMiningCard(
      {super.key, required this.c, required this.onBuyAuto});

  @override
  Widget build(BuildContext context) {
    final bool active = c.autoMining;

    return GlassmorphicContainer(
      width: double.infinity,
      height: 68.h,
      borderRadius: 16.r,
      blur: 10,
      alignment: Alignment.center,
      border: active ? 1.0 : 0.5,
      linearGradient: LinearGradient(colors: [
        (active ? AppColors.accentGreen : Colors.white)
            .withOpacity(active ? 0.07 : 0.02),
        Colors.transparent,
      ]),
      borderGradient: LinearGradient(colors: [
        (active ? AppColors.accentGreen : Colors.white54)
            .withOpacity(active ? 0.45 : 0.15),
        Colors.transparent,
      ]),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        child: Row(children: [
          // Icon
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: active
                  ? const LinearGradient(
                      colors: [AppColors.accentGreen, Color(0xFF00CC88)])
                  : null,
              color: active ? null : Colors.white10,
            ),
            child: Icon(
              active
                  ? CupertinoIcons.checkmark_shield_fill
                  : CupertinoIcons.bolt_slash_fill,
              color: active ? Colors.white : Colors.white38,
              size: 16.sp,
            ),
          ),
          SizedBox(width: 10.w),
          // Text
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? "AUTO MINING ACTIVE" : "AUTO MINING",
                  style: GoogleFonts.inter(
                      color: active
                          ? AppColors.accentGreen
                          : Colors.white54,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8),
                ),
                SizedBox(height: 2.h),
                Text(
                  active
                      ? "Mining resumes automatically each cycle"
                      : "One-time \$10 unlock · mines without tapping",
                  style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 8.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          // Action
          if (active)
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                    color: AppColors.accentGreen.withOpacity(0.3)),
              ),
              child: Row(children: [
                PulseDot(color: AppColors.accentGreen),
                SizedBox(width: 4.w),
                Text("ON",
                    style: GoogleFonts.inter(
                        color: AppColors.accentGreen,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800)),
              ]),
            )
          else
            GestureDetector(
              onTap: onBuyAuto,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.accentGreen, Color(0xFF00CC88)]),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  "BUY \$10",
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ]),
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }
}

// ═══════════════════════════════════════════════════════════════
// Withdrawable Section
// ═══════════════════════════════════════════════════════════════
class WithdrawableSection extends StatelessWidget {
  final MiningController c;
  const WithdrawableSection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 58.h,
      borderRadius: 14.r,
      blur: 10,
      alignment: Alignment.center,
      border: 0.5,
      linearGradient: LinearGradient(colors: [
        AppColors.accentLeaf.withOpacity(0.08),
        Colors.white.withOpacity(0.02),
      ]),
      borderGradient: LinearGradient(colors: [
        AppColors.accentLeaf.withOpacity(0.4),
        Colors.transparent,
      ]),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        child: Row(children: [
          Icon(CupertinoIcons.checkmark_seal_fill,
              color: AppColors.accentLeaf, size: 16.sp),
          SizedBox(width: 8.w),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("WITHDRAWABLE BALANCE",
                  style: GoogleFonts.inter(
                      color: AppColors.accentLeaf,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8)),
              Text("\$${c.withdrawableUSD.toStringAsFixed(2)} USD",
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Mining Orb
// ═══════════════════════════════════════════════════════════════
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

    if (c.isMining && c.boostActive) {
      orbIcon = CupertinoIcons.rocket_fill;
      orbLabel = "BOOSTED";
      orbSub = "MINING";
      orbIconColor = AppColors.accentPurple;
      borderColors = [AppColors.accentPurple, AppColors.accentGreen];
    } else if (c.isMining) {
      orbIcon = CupertinoIcons.hammer_fill;
      orbLabel = "MINING";
      orbIconColor = AppColors.accentGreen;
      borderColors = [AppColors.accentGreen, AppColors.accentPurple];
    } else if (isPaused) {
      orbIcon = CupertinoIcons.pause_fill;
      orbLabel = "PAUSED";
      orbSub = "Tap to resume";
      orbIconColor = Colors.orange;
      borderColors = [Colors.orange.withOpacity(0.6), Colors.white10];
    } else {
      orbIcon = CupertinoIcons.bolt_fill;
      orbLabel = "START";
      orbSub = "Tap to mine";
      orbIconColor = Colors.white70;
      borderColors = [Colors.white38, Colors.white10];
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated outer ring (only when mining)
          if (c.isMining)
            Container(
              width: 160.w,
              height: 160.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (c.boostActive
                          ? AppColors.accentPurple
                          : AppColors.accentGreen)
                      .withOpacity(0.5),
                  width: 2,
                ),
              ),
            )
                .animate(onPlay: (ctrl) => ctrl.repeat())
                .rotate(duration: const Duration(seconds: 3))
                .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    curve: Curves.easeInOutSine)
                .then()
                .scale(
                    begin: const Offset(1.1, 1.1),
                    end: const Offset(1, 1)),

          // Boost ring (second ring when boosted)
          if (c.isMining && c.boostActive)
            Container(
              width: 175.w,
              height: 175.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentPurple.withOpacity(0.25),
                  width: 1,
                ),
              ),
            )
                .animate(onPlay: (ctrl) => ctrl.repeat())
                .rotate(
                    duration: const Duration(seconds: 5),
                    begin: 1,
                    end: 0),

          // Main orb body
          GlassmorphicContainer(
            width: 140.w,
            height: 140.w,
            borderRadius: 70.w,
            blur: 15,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(colors: [
              Colors.black.withOpacity(0.6),
              Colors.black.withOpacity(0.3),
            ]),
            borderGradient: LinearGradient(colors: borderColors),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Icon(orbIcon, color: orbIconColor, size: 35.sp),
                SizedBox(height: 5.h),
                // Primary label
                Text(orbLabel,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0)),
                // Sub label (optional)
                if (orbSub.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(orbSub,
                      style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w500)),
                ],
                // Rate indicator when mining
                if (c.isMining) ...[
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 7.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: orbIconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      "+\$${c.usdPerSec.toStringAsFixed(6)}/s",
                      style: GoogleFonts.spaceMono(
                          color: orbIconColor,
                          fontSize: 7.sp,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Buy Boost Bottom Sheet
// ═══════════════════════════════════════════════════════════════
class BuyBoostSheet extends StatefulWidget {
  final MiningController c;
  final Future<bool> Function(double amount) onConfirm;
  const BuyBoostSheet(
      {super.key, required this.c, required this.onConfirm});

  @override
  State<BuyBoostSheet> createState() => _BuyBoostSheetState();
}

class _BuyBoostSheetState extends State<BuyBoostSheet> {
  double _amount = 10;
  bool _loading = false;
  String? _error;

  double get _remainingBoost =>
      (50 - widget.c.boostAmount).clamp(0, 50).toDouble();

  double get _newMultiplier {
    const baseDays = 360.0;
    const minDays = 80.0;
    final newBoost =
        ((widget.c.boostAmount + _amount).clamp(0, 50)).toDouble();
    final ratio = newBoost / 50.0;
    final days = baseDays - (baseDays - minDays) * ratio;
    return baseDays / days;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(
          top: BorderSide(
              color: AppColors.accentPurple.withOpacity(0.3), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
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

          // Title
          Row(children: [
            Icon(CupertinoIcons.rocket_fill,
                color: AppColors.accentPurple, size: 16.sp),
            SizedBox(width: 8.w),
            Text("BUY SPEED BOOST",
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8)),
          ]),
          SizedBox(height: 4.h),
          Text(
            "Invest \$1–\$50 to speed up your mining cycle",
            style:
                GoogleFonts.inter(color: Colors.white38, fontSize: 10.sp),
          ),
          SizedBox(height: 20.h),

          // Current boost info
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                  color: AppColors.accentPurple.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoItem("Current Boost",
                    "\$${widget.c.boostAmount.toStringAsFixed(0)}",
                    AppColors.accentPurple),
                _divider(),
                _infoItem("Remaining Cap",
                    "\$${_remainingBoost.toStringAsFixed(0)}",
                    Colors.white54),
                _divider(),
                _infoItem("Current Speed",
                    "${widget.c.boostMultiplier.toStringAsFixed(2)}x",
                    AppColors.accentGreen),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Amount selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Amount",
                  style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600)),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.accentPurple, Color(0xFFCC44FF)]),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  "\$${_amount.toStringAsFixed(0)}",
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentPurple,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              overlayColor: AppColors.accentPurple.withOpacity(0.2),
              trackHeight: 4,
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
          // Quick pick buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [5, 10, 20, 50].map((val) {
              final double dVal = val.toDouble();
              final bool sel = _amount == dVal;
              final bool disabled = dVal > _remainingBoost;
              return GestureDetector(
                onTap: disabled
                    ? null
                    : () => setState(
                        () => _amount = dVal.clamp(1, _remainingBoost)),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.accentPurple.withOpacity(0.3)
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: sel
                          ? AppColors.accentPurple
                          : Colors.transparent,
                    ),
                  ),
                  child: Text("\$$val",
                      style: GoogleFonts.inter(
                          color: disabled
                              ? Colors.white24
                              : (sel ? Colors.white : Colors.white54),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16.h),

          // Preview new speed
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                  color: AppColors.accentGreen.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.arrow_up_right_circle_fill,
                    color: AppColors.accentGreen, size: 13.sp),
                SizedBox(width: 6.w),
                Text(
                  "After purchase: ${_newMultiplier.toStringAsFixed(2)}x speed",
                  style: GoogleFonts.inter(
                      color: AppColors.accentGreen,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),

          // Error
          if (_error != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(_error!,
                  style: GoogleFonts.inter(
                      color: Colors.redAccent, fontSize: 10.sp)),
            ),

          SizedBox(height: 8.h),

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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: _loading || _remainingBoost < 1
                      ? null
                      : const LinearGradient(
                          colors: [
                            AppColors.accentPurple,
                            Color(0xFFCC44FF)
                          ],
                        ),
                  color: _loading || _remainingBoost < 1
                      ? Colors.white12
                      : null,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: _loading
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          _remainingBoost < 1
                              ? "MAX BOOST REACHED"
                              : "CONFIRM  \$${_amount.toStringAsFixed(0)} BOOST",
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800),
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
    return Column(children: [
      Text(label,
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 8.sp)),
      SizedBox(height: 2.h),
      Text(value,
          style: GoogleFonts.inter(
              color: valueColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800)),
    ]);
  }

  Widget _divider() => Container(
        width: 1,
        height: 28.h,
        color: Colors.white12,
      );
}

// ═══════════════════════════════════════════════════════════════
// Buy Auto Mining Dialog  (confirm sheet)
// ═══════════════════════════════════════════════════════════════
class BuyAutoMiningSheet extends StatefulWidget {
  final MiningController c;
  final Future<bool> Function() onConfirm;
  const BuyAutoMiningSheet(
      {super.key, required this.c, required this.onConfirm});

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(
          top: BorderSide(
              color: AppColors.accentGreen.withOpacity(0.3), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
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
          SizedBox(height: 20.h),

          // Icon
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [AppColors.accentGreen, Color(0xFF00CC88)]),
            ),
            child:
                Icon(CupertinoIcons.bolt_fill, color: Colors.white, size: 28.sp),
          ),
          SizedBox(height: 14.h),

          Text("Enable Auto Mining",
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800)),
          SizedBox(height: 8.h),
          Text(
            "One-time \$10 unlock. Mining will restart automatically\nafter each cycle without tapping the ORB.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp),
          ),
          SizedBox(height: 20.h),

          // Feature list
          ...[
            _featureRow(
                CupertinoIcons.checkmark_circle_fill,
                "Auto-restart after every \$100 cycle",
                AppColors.accentGreen),
            _featureRow(
                CupertinoIcons.checkmark_circle_fill,
                "No manual tap required",
                AppColors.accentGreen),
            _featureRow(CupertinoIcons.checkmark_circle_fill,
                "Works with boost multipliers", AppColors.accentGreen),
          ],
          SizedBox(height: 20.h),

          // Balance check
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Cost",
                    style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: 11.sp)),
                Text("\$10.00",
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          SizedBox(height: 6.h),

          // Error
          if (_error != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(_error!,
                  style: GoogleFonts.inter(
                      color: Colors.redAccent, fontSize: 10.sp)),
            ),

          SizedBox(height: 8.h),

          // Confirm
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
                          _error = "Purchase failed. Need \$10 balance.";
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: _loading
                      ? null
                      : const LinearGradient(
                          colors: [
                            AppColors.accentGreen,
                            Color(0xFF00CC88),
                          ],
                        ),
                  color: _loading ? Colors.white12 : null,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: _loading
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text("UNLOCK AUTO MINING  \$10",
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800)),
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
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(children: [
        Icon(icon, color: color, size: 13.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(text,
              style:
                  GoogleFonts.inter(color: Colors.white60, fontSize: 10.sp)),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Helper — show boost sheet
// ═══════════════════════════════════════════════════════════════
void showBuyBoostSheet(
  BuildContext context,
  MiningController controller,
  Future<bool> Function(double) onConfirm,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        BuyBoostSheet(c: controller, onConfirm: onConfirm),
  );
}

// ═══════════════════════════════════════════════════════════════
// Helper — show auto mining sheet
// ═══════════════════════════════════════════════════════════════
void showBuyAutoMiningSheet(
  BuildContext context,
  MiningController controller,
  Future<bool> Function() onConfirm,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        BuyAutoMiningSheet(c: controller, onConfirm: onConfirm),
  );
}


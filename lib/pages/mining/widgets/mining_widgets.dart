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

// ─── Pulse Dot ────────────────────────────────────────────────────────────────
class PulseDot extends StatefulWidget {
  final Color color;
  const PulseDot({super.key, required this.color});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

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
              BoxShadow(color: widget.color.withOpacity(0.6), blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Live Earnings Card (USD) ─────────────────────────────────────────────────
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

// ─── Solana Live Card ─────────────────────────────────────────────────────────
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
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
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
                          color: active ? AppColors.accentGreen : Colors.white38,
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
                  style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 9.sp),
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

// ─── Cycle Progress Section ───────────────────────────────────────────────────
class CycleProgressSection extends StatelessWidget {
  final MiningController c;
  const CycleProgressSection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color  statusColor;

    if (c.isMining) {
      statusText  = "Mining in progress...";
      statusColor = AppColors.accentGreen;
    } else if (c.dayStarted) {
      statusText  = "Paused — tap ORB to resume";
      statusColor = Colors.orange;
    } else {
      statusText  = "Tap ORB to start mining";
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 9.sp),
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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("${(c.cycleProgress * 100).toStringAsFixed(2)}% complete",
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

// ─── Boost Info Section ───────────────────────────────────────────────────────
class BoostInfoSection extends StatelessWidget {
  final MiningController c;
  const BoostInfoSection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 72.h,
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(CupertinoIcons.rocket_fill,
                  color: AppColors.accentPurple, size: 10.sp),
              SizedBox(width: 4.w),
              Text(
                "BOOST ACTIVE  |  \$${c.boostAmount.toStringAsFixed(0)} invested",
                style: GoogleFonts.inter(
                    color: AppColors.accentPurple,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8)),
            ]),
            Text("${c.boostMultiplier.toStringAsFixed(2)}x speed",
                style:
                    GoogleFonts.inter(color: Colors.white54, fontSize: 9.sp)),
          ]),
          SizedBox(height: 6.h),
          LinearPercentIndicator(
            lineHeight: 5.h,
            percent: ((c.boostMultiplier - 1.0) /
                    (kNormalDays / kBoostDays - 1.0))
                .clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            linearGradient: const LinearGradient(
                colors: [AppColors.accentPurple, Color(0xFFCC44FF)]),
            barRadius: const Radius.circular(10),
            padding: EdgeInsets.zero,
          ),
          SizedBox(height: 5.h),
          Text(
            "360 days → $kBoostDays days  |  AI: ${c.aiMultiplier.toStringAsFixed(2)}x",
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp),
          ),
        ]),
      ),
    );
  }
}

// ─── Withdrawable Section ─────────────────────────────────────────────────────
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

// ─── Mining Orb ──────────────────────────────────────────────────────────────
class MiningOrb extends StatelessWidget {
  final MiningController c;
  final VoidCallback onTap;
  const MiningOrb({super.key, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPaused = c.dayStarted && !c.isMining;

    IconData    orbIcon;
    String      orbLabel;
    String      orbSub = '';
    Color       orbIconColor;
    List<Color> borderColors;

    if (c.isMining && c.boostActive) {
      orbIcon      = CupertinoIcons.rocket_fill;
      orbLabel     = "BOOSTED";
      orbSub       = "MINING";
      orbIconColor = AppColors.accentPurple;
      borderColors = [AppColors.accentPurple, AppColors.accentGreen];
    } else if (c.isMining) {
      orbIcon      = CupertinoIcons.hammer_fill;
      orbLabel     = "MINING";
      orbIconColor = AppColors.accentGreen;
      borderColors = [AppColors.accentGreen, AppColors.accentPurple];
    } else if (isPaused) {
      orbIcon      = CupertinoIcons.pause_fill;
      orbLabel     = "PAUSED";
      orbSub       = "Tap to resume";
      orbIconColor = Colors.orange;
      borderColors = [Colors.orange.withOpacity(0.6), Colors.white10];
    } else {
      orbIcon      = CupertinoIcons.bolt_fill;
      orbLabel     = "START";
      orbSub       = "Tap to mine";
      orbIconColor = Colors.white70;
      borderColors = [Colors.white38, Colors.white10];
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
                Icon(orbIcon, color: orbIconColor, size: 35.sp),
                SizedBox(height: 5.h),
                Text(orbLabel,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900)),
                if (orbSub.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(orbSub,
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 8.sp)),
                ],
                if (c.isMining) ...[
                  SizedBox(height: 4.h),
                  Text(
                    "+${c.formatSol(c.solPerSec)}/s",
                    style: GoogleFonts.spaceMono(
                        color: AppColors.accentGreen.withOpacity(0.8),
                        fontSize: 7.sp),
                  ),
                ],
              ],
            ),
          ).animate(target: c.isMining ? 1 : 0).shimmer(
              duration: const Duration(milliseconds: 1500),
              color: Colors.white24),
        ],
      ),
    );
  }
}

// ─── Cycle Progress Bar ───────────────────────────────────────────────────────
class CycleProgressBar extends StatelessWidget {
  final MiningController c;
  const CycleProgressBar({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return LinearPercentIndicator(
      lineHeight: 6.h,
      percent: c.cycleProgress.clamp(0.0, 1.0),
      backgroundColor: Colors.white10,
      linearGradient: const LinearGradient(
          colors: [AppColors.accentPurple, AppColors.accentGreen]),
      barRadius: const Radius.circular(10),
      padding: EdgeInsets.zero,
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────
class ActionButtons extends StatelessWidget {
  final MiningController c;
  final VoidCallback onClaim;
  final VoidCallback onRefresh;
  const ActionButtons({
    super.key,
    required this.c,
    required this.onClaim,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final claimable = c.dayStarted && c.isMining;
    return Row(children: [
      Expanded(child: _ClaimButton(active: claimable, onTap: onClaim)),
      SizedBox(width: 8.w),
      Expanded(
        child: _SmallButton(
          label: "REFRESH",
          icon: CupertinoIcons.arrow_clockwise,
          color: AppColors.accentLeaf,
          onTap: onRefresh,
        ),
      ),
    ]);
  }
}

class _ClaimButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _ClaimButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 60.h,
        borderRadius: 15.r,
        blur: 10,
        alignment: Alignment.center,
        border: active ? 1.0 : 0.5,
        linearGradient: LinearGradient(colors: [
          active
              ? AppColors.accentGreen.withOpacity(0.18)
              : Colors.white.withOpacity(0.05),
          Colors.transparent,
        ]),
        borderGradient: LinearGradient(colors: [
          active ? AppColors.accentGreen : Colors.white24,
          Colors.transparent,
        ]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(CupertinoIcons.drop_fill,
              color: active ? AppColors.accentGreen : Colors.white38,
              size: 16.sp),
          SizedBox(width: 5.w),
          Text("CLAIM",
              style: GoogleFonts.inter(
                  color: active ? AppColors.accentGreen : Colors.white38,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _SmallButton(
      {required this.label,
      required this.icon,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 60.h,
        borderRadius: 15.r,
        blur: 10,
        alignment: Alignment.center,
        border: 0.5,
        linearGradient: LinearGradient(
            colors: [Colors.white.withOpacity(0.05), Colors.transparent]),
        borderGradient:
            const LinearGradient(colors: [Colors.white24, Colors.transparent]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(width: 5.w),
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────
class StatsGrid extends StatelessWidget {
  final MiningController c;
  const StatsGrid({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: _StatBox(
              label: "BOOST",
              value: "${c.boostMultiplier.toStringAsFixed(2)}x",
              color: AppColors.accentPurple)),
      SizedBox(width: 8.w),
      Expanded(
          child: _StatBox(
              label: "AI MULT",
              value: "${c.aiMultiplier.toStringAsFixed(2)}x",
              color: Colors.orangeAccent)),
      SizedBox(width: 8.w),
      Expanded(
          child: _StatBox(
              label: "WITHDRAW",
              value: "\$${c.withdrawableUSD.toStringAsFixed(2)}",
              color: AppColors.accentLeaf)),
    ]);
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 9.sp,
                fontWeight: FontWeight.bold)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: GoogleFonts.inter(
                  color: color,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}

// ─── Error Widget ─────────────────────────────────────────────────────────────
class MiningErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const MiningErrorWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.cloud_off_rounded, color: Colors.white30, size: 48.sp),
        SizedBox(height: 12.h),
        Text("Could not load mining data",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14.sp)),
        SizedBox(height: 16.h),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, color: Colors.black),
          label: Text("Retry",
              style: GoogleFonts.inter(
                  color: Colors.black, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r)),
          ),
        ),
      ]),
    );
  }
}

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

// ============================================
// MAIN SCREEN - সব কন্টেন্ট উপরে
// ============================================

class MiningScreen extends StatefulWidget {
  final MiningController c;
  
  const MiningScreen({super.key, required this.c});

  @override
  State<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen> {
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
                // Header
                _buildHeader(),
                SizedBox(height: 16.h),
                
                // 1. AUTO MINING CARD (সবার উপরে)
                AutoMiningCard(c: widget.c),
                SizedBox(height: 16.h),
                
                // 2. LIVE EARNINGS
                LiveEarningsCard(c: widget.c),
                SizedBox(height: 16.h),
                
                // 3. SOLANA MINING
                SolanaLiveCard(c: widget.c),
                SizedBox(height: 16.h),
                
                // 4. CYCLE PROGRESS
                CycleProgressSection(c: widget.c),
                SizedBox(height: 16.h),
                
                // 5. BOOST INFO
                BoostInfoSection(
                  c: widget.c, 
                  onBuyBoost: () => widget.c.purchaseBoost(),
                ),
                SizedBox(height: 16.h),
                
                // 6. WITHDRAWABLE SECTION
                WithdrawableSection(c: widget.c),
                SizedBox(height: 16.h),
                
                // 7. MINING ORB
                MiningOrb(c: widget.c),
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
              widget.c.isAutoMining ? "Auto Mining Active" : "Manual Mode",
              style: GoogleFonts.inter(
                color: widget.c.isAutoMining ? AppColors.accentGreen : Colors.orange,
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
}

// ============================================
// AUTO MINING CARD (সবার উপরে)
// ============================================

class AutoMiningCard extends StatefulWidget {
  final MiningController c;
  
  const AutoMiningCard({super.key, required this.c});

  @override
  State<AutoMiningCard> createState() => _AutoMiningCardState();
}

class _AutoMiningCardState extends State<AutoMiningCard> {
  @override
  Widget build(BuildContext context) {
    final bool isAutoMining = widget.c.isAutoMining;

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
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          widget.c.toggleAutoMining();
                        });
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAutoStat("Next Claim", widget.c.nextClaimTime, Icons.timer),
                    _buildAutoStat("Auto Rate", "+${widget.c.formatSol(widget.c.solPerSec)}/s", Icons.speed),
                    _buildAutoStat("Streak", "${widget.c.autoMiningStreak} Days", Icons.local_fire_department),
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
// LIVE EARNINGS CARD
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

// ============================================
// SOLANA LIVE CARD
// ============================================

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
            AppColors.bgCard,
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
                              color: Colors.white54,
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
                            _PulseDot(color: AppColors.accentGreen),
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

// ============================================
// PULSE DOT
// ============================================

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
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

// ============================================
// CYCLE PROGRESS SECTION
// ============================================

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
      statusColor = AppColors.accentPurple;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: [
            AppColors.accentGreen.withOpacity(0.1),
            AppColors.bgCard,
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
                      "\$${kMinWithdraw.toStringAsFixed(0)} - \$${kUsdTarget.toStringAsFixed(0)} CYCLE",
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

// ============================================
// BOOST INFO SECTION
// ============================================

class BoostInfoSection extends StatelessWidget {
  final MiningController c;
  final VoidCallback onBuyBoost;
  
  const BoostInfoSection({
    super.key, 
    required this.c, 
    required this.onBuyBoost,
  });

  @override
  Widget build(BuildContext context) {
    final double boostPercent = kNormalDays != kBoostDays
        ? ((c.boostMultiplier - 1.0) / (kNormalDays / kBoostDays - 1.0)).clamp(0.0, 1.0)
        : 0.0;
    final bool maxed = c.boostAmount >= 50;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: [
            AppColors.accentPurple.withOpacity(0.15),
            AppColors.bgCard,
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
              children: [
                SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: Lottie.network(AppLottie.rocket),
                ),
                SizedBox(width: 8.w),
                Text(
                  "BOOST x${c.boostMultiplier.toStringAsFixed(1)}",
                  style: GoogleFonts.inter(
                    color: AppColors.accentPurple,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                if (maxed)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      "MAXED",
                      style: GoogleFonts.inter(
                        color: Colors.amber,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            LinearPercentIndicator(
              lineHeight: 6.h,
              percent: boostPercent,
              backgroundColor: Colors.white10,
              linearGradient: const LinearGradient(
                colors: [AppColors.accentPurple, AppColors.accentGreen],
              ),
              barRadius: const Radius.circular(10),
              padding: EdgeInsets.zero,
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${(boostPercent * 100).toStringAsFixed(0)}% to max boost",
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 10.sp,
                  ),
                ),
                GestureDetector(
                  onTap: maxed ? null : onBuyBoost,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      gradient: maxed ? null : const LinearGradient(
                        colors: [AppColors.accentPurple, AppColors.accentGreen],
                      ),
                      color: maxed ? Colors.white10 : null,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      maxed ? "MAXED OUT" : "UPGRADE",
                      style: GoogleFonts.inter(
                        color: maxed ? Colors.white38 : Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
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

// ============================================
// WITHDRAWABLE SECTION
// ============================================

class WithdrawableSection extends StatelessWidget {
  final MiningController c;
  const WithdrawableSection({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: AppColors.bgCard,
        border: Border.all(color: Colors.white10),
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
                color: AppColors.accentGreen.withOpacity(0.2),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: AppColors.accentGreen,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Withdrawable Balance",
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "\$${c.withdrawableUSD.toStringAsFixed(2)}",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentGreen, AppColors.accentPurple],
                ),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                "WITHDRAW",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}

// ============================================
// MINING ORB
// ============================================

class MiningOrb extends StatefulWidget {
  final MiningController c;
  const MiningOrb({super.key, required this.c});

  @override
  State<MiningOrb> createState() => _MiningOrbState();
}

class _MiningOrbState extends State<MiningOrb> {
  @override
  Widget build(BuildContext context) {
    final bool isMining = widget.c.isMining;

    return GestureDetector(
      onTap: () {
        setState(() {
          widget.c.isMining = !widget.c.isMining;
        });
      },
      child: Center(
        child: Container(
          width: 150.w,
          height: 150.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: isMining
                ? [AppColors.accentGreen, AppColors.accentPurple.withOpacity(0.5), Colors.transparent]
                : [Colors.white24, Colors.transparent],
            ),
            boxShadow: isMining
              ? [
                  BoxShadow(
                    color: AppColors.accentGreen.withOpacity(0.5),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ]
              : [],
          ),
          child: Center(
            child: Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isMining
                    ? [AppColors.accentGreen, AppColors.accentPurple]
                    : [Colors.white24, Colors.white10],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isMining ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 40.sp,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      isMining ? "PAUSE" : "START",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(),
        ).scale(
          duration: const Duration(milliseconds: 1500),
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.05, 1.05),
        ),
      ),
    );
  }
}

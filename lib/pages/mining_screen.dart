import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_background/animated_background.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ======================== COLORS ========================
class AppColors {
  static const Color background   = Color(0xFF0D0D12);
  static const Color accentGreen  = Color(0xFF14F195);
  static const Color accentPurple = Color(0xFF9945FF);
  static const Color accentLeaf   = Color(0xFF76C442);
  static const Color accentOrange = Color(0xFFFF9500);
  static const Color accentBlue   = Color(0xFF0A84FF);
  static const Color iosGreen     = Color(0xFF30D158);
}

// ======================== MAIN ========================
void main() => runApp(const VexylonApp());

class VexylonApp extends StatelessWidget {
  const VexylonApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppColors.background,
            textTheme:
                GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          home: const MiningScreen(),
        );
      },
    );
  }
}

// ======================== CONTROLLER ========================
class MiningController extends GetxController {
  static const double entryFee        = 18.0;
  static const int    planDays        = 365;
  static const double targetVXL       = 10000.0;
  static const double dailyVXL        = targetVXL / planDays;
  static const int    ticksPerDay     = 864000;
  static const double perTickEarning  = dailyVXL / ticksPerDay;
  static const int    boostDays       = 80;
  static const int    totalBoostTicks = boostDays * ticksPerDay;
  static const double autoStartFee    = 10.0;

  // ── Observables ──────────────────────────────────────────
  final isMining        = false.obs;
  final hasPaid         = false.obs;
  final isComplete      = false.obs;
  final balance         = 0.0.obs;
  final cycleProgress   = 0.0.obs;
  final planProgress    = 0.0.obs;
  final remainingDays   = planDays.obs;
  final totalEarned     = 0.0.obs;

  final completedDays   = 0.obs;
  final currentDayNum   = 1.obs;
  final dayProgress     = 0.0.obs;
  final dayStarted      = false.obs;
  final canStartNewDay  = true.obs;
  final todayEarned     = 0.0.obs;

  final hasAutoStart    = false.obs;

  final boostPaid           = false.obs;
  final boostIsComplete     = false.obs;
  final boostAmount         = 0.0.obs;
  final boostProgress       = 0.0.obs;
  final boostRemainingDays  = boostDays.obs;
  final boostEarned         = 0.0.obs;
  final boostTotalVXL       = 0.0.obs;

  // Referral
  final activeReferrals = 0.obs;
  final daysSaved       = 0.obs;

  // Claim
  final canClaim        = false.obs;
  final isClaimed       = false.obs;
  final claimedAmount   = 0.0.obs;

  // ── Private ──────────────────────────────────────────────
  Timer?  _timer;
  int     _dayElapsedTicks   = 0;
  int     _boostElapsedTicks = 0;
  double  _boostPerTick      = 0.0;
  Worker? _referralWorker;

  // ── Computed ─────────────────────────────────────────────
  int get effectivePlanDays =>
      max(5, planDays - activeReferrals.value * 10);

  @override
  void onInit() {
    super.onInit();
    _referralWorker = ever(activeReferrals, (_) {
      daysSaved.value = activeReferrals.value * 10;
      if (!hasPaid.value || isComplete.value) return;
      final eff = effectivePlanDays;
      if (completedDays.value >= eff) {
        isComplete.value    = true;
        canClaim.value      = true;
        planProgress.value  = 1.0;
        remainingDays.value = 0;
        _timer?.cancel();
        isMining.value   = false;
        dayStarted.value = false;
      } else {
        planProgress.value  = completedDays.value / eff;
        remainingDays.value = eff - completedDays.value;
      }
    });
  }

  // ── Public Methods ────────────────────────────────────────
  void addReferral() {
    if (activeReferrals.value < 36) activeReferrals.value++;
  }

  void claimBalance() {
    if (!canClaim.value) return;
    claimedAmount.value = balance.value;
    isClaimed.value = true;
    canClaim.value  = false;
    balance.value   = 0;
  }

  void activatePlan() {
    hasPaid.value        = true;
    isComplete.value     = false;
    isClaimed.value      = false;
    canClaim.value       = false;
    claimedAmount.value  = 0;
    _dayElapsedTicks     = 0;
    completedDays.value  = 0;
    currentDayNum.value  = 1;
    balance.value        = 0;
    totalEarned.value    = 0;
    planProgress.value   = 0;
    remainingDays.value  = effectivePlanDays;
    dayProgress.value    = 0;
    dayStarted.value     = false;
    canStartNewDay.value = true;
    todayEarned.value    = 0;
  }

  void activateAutoStart() {
    hasAutoStart.value = true;
    if (hasPaid.value && !isComplete.value &&
        !isMining.value && canStartNewDay.value && !dayStarted.value) {
      _startNewDay();
    }
  }

  void toggleMining() {
    if (!hasPaid.value || isComplete.value) return;
    if (isMining.value) {
      _timer?.cancel();
      isMining.value = false;
    } else if (dayStarted.value) {
      _resumeMining();
    } else if (canStartNewDay.value) {
      _startNewDay();
    }
  }

  void _startNewDay() {
    dayStarted.value     = true;
    canStartNewDay.value = false;
    isMining.value       = true;
    _runTimer();
  }

  void _resumeMining() {
    isMining.value = true;
    _runTimer();
  }

  void _runTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (_dayElapsedTicks >= ticksPerDay) {
        t.cancel();
        isMining.value    = false;
        dayStarted.value  = false;
        completedDays.value++;
        _dayElapsedTicks  = 0;
        dayProgress.value = 0;
        todayEarned.value = 0;

        final eff = effectivePlanDays;
        if (completedDays.value >= eff) {
          isComplete.value    = true;
          canClaim.value      = true;
          planProgress.value  = 1.0;
          remainingDays.value = 0;
          currentDayNum.value = eff;
          return;
        }
        currentDayNum.value  = completedDays.value + 1;
        planProgress.value   = completedDays.value / eff;
        remainingDays.value  = eff - completedDays.value;

        Future.delayed(const Duration(seconds: 2), () {
          if (!isComplete.value) {
            canStartNewDay.value = true;
            if (hasAutoStart.value) _startNewDay();
          }
        });
        return;
      }

      balance.value      += perTickEarning;
      totalEarned.value  += perTickEarning;
      todayEarned.value  += perTickEarning;
      cycleProgress.value = (cycleProgress.value + 0.005) % 1.0;
      _dayElapsedTicks++;
      dayProgress.value   = _dayElapsedTicks / ticksPerDay;

      final eff = effectivePlanDays;
      planProgress.value =
          (completedDays.value * ticksPerDay + _dayElapsedTicks) /
          (eff * ticksPerDay);
      remainingDays.value =
          (eff - completedDays.value - _dayElapsedTicks / ticksPerDay)
              .ceil()
              .clamp(0, eff);

      if (totalEarned.value >= targetVXL &&
          !canClaim.value &&
          !isClaimed.value) {
        canClaim.value = true;
      }

      if (boostPaid.value && !boostIsComplete.value) {
        if (_boostElapsedTicks < totalBoostTicks) {
          balance.value     += _boostPerTick;
          boostEarned.value += _boostPerTick;
          _boostElapsedTicks++;
          boostProgress.value = _boostElapsedTicks / totalBoostTicks;
          boostRemainingDays.value =
              (boostDays - _boostElapsedTicks / ticksPerDay)
                  .ceil()
                  .clamp(0, boostDays);
        } else {
          boostIsComplete.value = true;
        }
      }
    });
  }

  void activateBoost(double amount) {
    boostPaid.value          = true;
    boostIsComplete.value    = false;
    boostAmount.value        = amount;
    _boostElapsedTicks       = 0;
    boostProgress.value      = 0;
    boostEarned.value        = 0;
    boostRemainingDays.value = boostDays;
    final total              = amount * 2.0 * (10000.0 / 18.0);
    boostTotalVXL.value      = total;
    _boostPerTick            = total / totalBoostTicks;
  }

  @override
  void onClose() {
    _referralWorker?.dispose();
    _timer?.cancel();
    super.onClose();
  }
}

// ======================== SCREEN ========================
class MiningScreen extends StatefulWidget {
  const MiningScreen({super.key});
  @override
  State<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen>
    with TickerProviderStateMixin {
  final MiningController c = Get.put(MiningController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBackground(
            vsync: this,
            behaviour: RandomParticleBehaviour(
              options: const ParticleOptions(
                baseColor: AppColors.accentGreen,
                spawnOpacity: 0.05,
                particleCount: 12,
                maxOpacity: 0.25,
              ),
            ),
            child: Container(),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── iOS Header ───────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 4.h),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentGreen, AppColors.accentPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGreen.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(CupertinoIcons.hexagon_fill,
                color: Colors.white, size: 20.sp),
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "VEXYLON",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
              Text(
                "Mining Network",
                style: GoogleFonts.inter(
                    color: Colors.white38, fontSize: 9.5.sp),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                  color: AppColors.accentGreen.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5.w,
                  height: 5.w,
                  decoration: const BoxDecoration(
                    color: AppColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 5.w),
                Text(
                  "LIVE",
                  style: GoogleFonts.inter(
                    color: AppColors.accentGreen,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Page Content ─────────────────────────────────────────
  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          SizedBox(height: 6.h),
          _buildBalanceCard(),
          SizedBox(height: 10.h),
          _buildPlanProgressCard(),
          SizedBox(height: 8.h),
          Obx(() => c.hasPaid.value
              ? _buildDailyCard()
              : const SizedBox.shrink()),
          SizedBox(height: 8.h),
          _buildReferralCard(),
          SizedBox(height: 8.h),
          Obx(() => c.boostPaid.value
              ? _buildBoostCard()
              : const SizedBox.shrink()),
          SizedBox(height: 22.h),
          _buildMiningOrb(),
          SizedBox(height: 16.h),
          _buildCycleBar(),
          SizedBox(height: 20.h),
          Obx(() => c.hasPaid.value
              ? _buildActionButtons()
              : _buildUnlockButton()),
          SizedBox(height: 14.h),
          _buildStatsGrid(),
          SizedBox(height: 28.h),
        ],
      ),
    );
  }

  // ── Balance Card ─────────────────────────────────────────
  Widget _buildBalanceCard() {
    return _glassCard(
      height: 98.h,
      borderColor: AppColors.accentGreen.withOpacity(0.2),
      bg: AppColors.accentGreen.withOpacity(0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "MINED BALANCE",
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 6.h),
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    c.balance.value.toStringAsFixed(4),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      "VXL",
                      style: GoogleFonts.inter(
                        color: AppColors.accentGreen,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              )),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.08, duration: 400.ms);
  }

  // ── Plan Progress Card ───────────────────────────────────
  Widget _buildPlanProgressCard() {
    return Obx(() {
      final prog    = c.planProgress.value;
      final left    = c.remainingDays.value;
      final earned  = c.totalEarned.value;
      final done    = c.completedDays.value;
      final effDays = c.effectivePlanDays;

      return _glassCard(
        height: 84.h,
        borderColor: AppColors.accentLeaf.withOpacity(0.3),
        bg: AppColors.accentLeaf.withOpacity(0.06),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(CupertinoIcons.chart_bar_fill,
                        color: AppColors.accentLeaf, size: 10.sp),
                    SizedBox(width: 5.w),
                    Text(
                      "$effDays-DAY PLAN  ·  \$18 → \$100",
                      style: GoogleFonts.inter(
                        color: AppColors.accentLeaf,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ]),
                  Text(
                    "${earned.toStringAsFixed(1)} / 10,000 VXL",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 9.sp),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              LinearPercentIndicator(
                lineHeight: 5.h,
                percent: prog.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.06),
                linearGradient: LinearGradient(colors: [
                  AppColors.accentLeaf,
                  const Color(0xFF2E8B00),
                ]),
                barRadius: const Radius.circular(10),
                padding: EdgeInsets.zero,
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("$done / $effDays days mined",
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 9.sp)),
                  Text("$left days left",
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 9.sp)),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Daily Card ───────────────────────────────────────────
  Widget _buildDailyCard() {
    return Obx(() {
      final dayNum   = c.currentDayNum.value;
      final prog     = c.dayProgress.value;
      final earned   = c.todayEarned.value;
      final mining   = c.isMining.value;
      final started  = c.dayStarted.value;
      final canStart = c.canStartNewDay.value;
      final hasAuto  = c.hasAutoStart.value;
      final complete = c.isComplete.value;
      final effDays  = c.effectivePlanDays;

      String statusText;
      Color  statusColor;
      if (complete) {
        statusText  = "Plan Complete! 🎉";
        statusColor = AppColors.accentLeaf;
      } else if (mining && hasAuto) {
        statusText  = "⚡ Auto Mining Active";
        statusColor = AppColors.accentOrange;
      } else if (mining) {
        statusText  = "Mining in progress...";
        statusColor = AppColors.accentGreen;
      } else if (started && !mining) {
        statusText  = "Paused · tap ORB to resume";
        statusColor = Colors.orange;
      } else if (!canStart && !started) {
        statusText  = "Today done · next day soon";
        statusColor = Colors.white38;
      } else {
        statusText  = "Tap ORB to start today";
        statusColor = AppColors.accentGreen.withOpacity(0.85);
      }

      final barColor =
          hasAuto ? AppColors.accentOrange : AppColors.accentGreen;

      return _glassCard(
        height: 88.h,
        borderColor: barColor.withOpacity(0.3),
        bg: barColor.withOpacity(0.06),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(
                      hasAuto
                          ? CupertinoIcons.bolt_fill
                          : CupertinoIcons.calendar,
                      color: barColor,
                      size: 10.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      "DAY $dayNum / $effDays${hasAuto ? '  ⚡ AUTO' : ''}",
                      style: GoogleFonts.inter(
                        color: barColor,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ]),
                  Text(
                    "${earned.toStringAsFixed(3)} / ${MiningController.dailyVXL.toStringAsFixed(2)} VXL",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 9.sp),
                  ),
                ],
              ),
              SizedBox(height: 7.h),
              LinearPercentIndicator(
                lineHeight: 5.h,
                percent: prog.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.06),
                linearGradient: LinearGradient(
                  colors: hasAuto
                      ? [AppColors.accentOrange, const Color(0xFFFFCC00)]
                      : [AppColors.accentGreen, AppColors.accentPurple],
                ),
                barRadius: const Radius.circular(10),
                padding: EdgeInsets.zero,
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${(prog * 100).toStringAsFixed(2)}% of today",
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 9.sp)),
                  Text(
                    statusText,
                    style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Referral Card ────────────────────────────────────────
  Widget _buildReferralCard() {
    return Obx(() {
      final refs  = c.activeReferrals.value;
      final saved = c.daysSaved.value;

      return _glassCard(
        height: 92.h,
        borderColor: AppColors.accentBlue.withOpacity(0.3),
        bg: AppColors.accentBlue.withOpacity(0.06),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(CupertinoIcons.person_2_fill,
                        color: AppColors.accentBlue, size: 11.sp),
                    SizedBox(width: 5.w),
                    Text(
                      "REFERRALS  ·  প্রতিটি = -১০ দিন",
                      style: GoogleFonts.inter(
                        color: AppColors.accentBlue,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ]),
                  GestureDetector(
                    onTap: c.addReferral,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 9.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                            color: AppColors.accentBlue.withOpacity(0.4)),
                      ),
                      child: Text(
                        "+ Demo",
                        style: GoogleFonts.inter(
                          color: AppColors.accentBlue,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  // Referral code
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(9.r),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(children: [
                      Text(
                        "VXL-A7X9",
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Icon(CupertinoIcons.doc_on_doc_fill,
                          color: Colors.white38, size: 11.sp),
                    ]),
                  ),
                  const Spacer(),
                  // Stats
                  _referralStat(
                      "$refs", "Active", AppColors.accentBlue),
                  SizedBox(width: 16.w),
                  _referralStat(
                      "$saved", "Days Saved", AppColors.accentGreen),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _referralStat(String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
              color: Colors.white38, fontSize: 8.sp),
        ),
      ],
    );
  }

  // ── Boost Card ───────────────────────────────────────────
  Widget _buildBoostCard() {
    return Obx(() {
      final prog     = c.boostProgress.value;
      final left     = c.boostRemainingDays.value;
      final earned   = c.boostEarned.value;
      final total    = c.boostTotalVXL.value;
      final complete = c.boostIsComplete.value;

      return _glassCard(
        height: 80.h,
        borderColor: AppColors.accentPurple.withOpacity(0.35),
        bg: AppColors.accentPurple.withOpacity(0.08),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(CupertinoIcons.rocket_fill,
                        color: AppColors.accentPurple, size: 10.sp),
                    SizedBox(width: 5.w),
                    Text(
                      "BOOST  ·  \$${c.boostAmount.value.toStringAsFixed(0)} → \$${(c.boostAmount.value * 2).toStringAsFixed(0)}",
                      style: GoogleFonts.inter(
                        color: AppColors.accentPurple,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (complete) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text("DONE",
                            style: GoogleFonts.inter(
                                color: AppColors.accentGreen,
                                fontSize: 7.sp,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  Text(
                    "${earned.toStringAsFixed(1)} / ${total.toStringAsFixed(0)} VXL",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 9.sp),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              LinearPercentIndicator(
                lineHeight: 5.h,
                percent: prog.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.06),
                linearGradient: const LinearGradient(
                    colors: [AppColors.accentPurple, Color(0xFFCC44FF)]),
                barRadius: const Radius.circular(10),
                padding: EdgeInsets.zero,
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${(prog * 100).toStringAsFixed(2)}% complete",
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 9.sp)),
                  Text(complete ? "Boost Complete!" : "$left days left",
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 9.sp)),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Mining Orb ───────────────────────────────────────────
  Widget _buildMiningOrb() {
    return Obx(() {
      final active   = c.isMining.value;
      final complete = c.isComplete.value;
      final paid     = c.hasPaid.value;
      final started  = c.dayStarted.value;
      final canStart = c.canStartNewDay.value;
      final hasAuto  = c.hasAutoStart.value;

      final isPaused  = paid && started && !active && !complete;
      final isWaiting = paid && !started && !canStart && !active && !complete;

      IconData    orbIcon;
      String      orbLabel;
      String      orbSub = '';
      Color       orbColor;
      List<Color> borderCols;

      if (complete) {
        orbIcon    = CupertinoIcons.checkmark_seal_fill;
        orbLabel   = "COMPLETE";
        orbColor   = AppColors.accentLeaf;
        borderCols = [AppColors.accentLeaf, const Color(0xFF2E8B00)];
      } else if (active && hasAuto) {
        orbIcon    = CupertinoIcons.bolt_fill;
        orbLabel   = "AUTO";
        orbSub     = "MINING";
        orbColor   = AppColors.accentOrange;
        borderCols = [AppColors.accentOrange, AppColors.accentGreen];
      } else if (active) {
        orbIcon    = CupertinoIcons.hammer_fill;
        orbLabel   = "MINING";
        orbColor   = AppColors.accentGreen;
        borderCols = [AppColors.accentGreen, AppColors.accentPurple];
      } else if (isPaused) {
        orbIcon    = CupertinoIcons.pause_fill;
        orbLabel   = "PAUSED";
        orbSub     = "Tap to resume";
        orbColor   = Colors.orange;
        borderCols = [Colors.orange.withOpacity(0.6), Colors.white10];
      } else if (isWaiting) {
        orbIcon    = CupertinoIcons.clock_fill;
        orbLabel   = "NEXT DAY";
        orbSub     = "Coming soon...";
        orbColor   = Colors.white38;
        borderCols = [Colors.white24, Colors.white10];
      } else if (paid && canStart) {
        orbIcon    = CupertinoIcons.bolt_fill;
        orbLabel   = "START";
        orbSub     = "Today's mining";
        orbColor   = Colors.white70;
        borderCols = [Colors.white38, Colors.white10];
      } else {
        orbIcon    = CupertinoIcons.lock_fill;
        orbLabel   = "LOCKED";
        orbSub     = "\$18 to unlock";
        orbColor   = AppColors.accentLeaf.withOpacity(0.75);
        borderCols = [AppColors.accentLeaf.withOpacity(0.45), Colors.white10];
      }

      return GestureDetector(
        onTap: paid ? c.toggleMining : _showConfirmDialog,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (active)
              Container(
                width: 158.w,
                height: 158.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (hasAuto
                            ? AppColors.accentOrange
                            : AppColors.accentGreen)
                        .withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
              )
                  .animate(onPlay: (ctrl) => ctrl.repeat())
                  .rotate(duration: const Duration(seconds: 3))
                  .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.08, 1.08),
                      curve: Curves.easeInOutSine)
                  .then()
                  .scale(
                      begin: const Offset(1.08, 1.08),
                      end: const Offset(1, 1)),
            GlassmorphicContainer(
              width: 140.w,
              height: 140.w,
              borderRadius: 70.w,
              blur: 18,
              alignment: Alignment.center,
              border: 1.2,
              linearGradient: LinearGradient(colors: [
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.25),
              ]),
              borderGradient: LinearGradient(colors: borderCols),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(orbIcon, color: orbColor, size: 34.sp),
                  SizedBox(height: 5.h),
                  Text(
                    orbLabel,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (orbSub.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(orbSub,
                        style: GoogleFonts.inter(
                            color: Colors.white38, fontSize: 8.sp)),
                  ],
                ],
              ),
            ).animate(target: active ? 1.0 : 0.0).shimmer(
                  duration: 1500.ms,
                  color: Colors.white.withOpacity(0.12),
                ),
          ],
        ),
      );
    });
  }

  // ── Cycle Bar ────────────────────────────────────────────
  Widget _buildCycleBar() {
    return Obx(() => LinearPercentIndicator(
          lineHeight: 5.h,
          percent: c.cycleProgress.value,
          backgroundColor: Colors.white.withOpacity(0.06),
          linearGradient: const LinearGradient(
              colors: [AppColors.accentPurple, AppColors.accentGreen]),
          barRadius: const Radius.circular(10),
          padding: EdgeInsets.zero,
        ));
  }

  // ── Action Buttons ───────────────────────────────────────
  Widget _buildActionButtons() {
    return Row(
      children: [
        // CLAIM
        Expanded(
          child: Obx(() {
            final canClaim = c.canClaim.value;
            final claimed  = c.isClaimed.value;
            if (claimed) {
              return _iosBtn(
                "CLAIMED",
                CupertinoIcons.checkmark_circle_fill,
                AppColors.accentGreen,
                null,
                active: true,
              );
            } else if (canClaim) {
              return _iosBtn(
                "CLAIM",
                CupertinoIcons.drop_fill,
                AppColors.accentGreen,
                _showClaimDialog,
                active: true,
              ).animate(onPlay: (ctrl) => ctrl.repeat(reverse: true)).shimmer(
                    duration: 1200.ms,
                    color: AppColors.accentGreen.withOpacity(0.3),
                  );
            } else {
              return _iosBtn(
                "CLAIM",
                CupertinoIcons.drop_fill,
                Colors.white24,
                null,
              );
            }
          }),
        ),
        SizedBox(width: 8.w),
        // BOOST
        Expanded(
          child: _iosBtn("BOOST", CupertinoIcons.rocket_fill,
              AppColors.accentPurple, _showBoostDialog),
        ),
        SizedBox(width: 8.w),
        // AUTO
        Expanded(
          child: Obx(() => c.hasAutoStart.value
              ? _iosBtn("AUTO ON", CupertinoIcons.bolt_fill,
                  AppColors.accentOrange, null,
                  active: true)
              : _iosBtn("AUTO", CupertinoIcons.bolt_fill,
                  AppColors.accentOrange, _showAutoStartDialog)),
        ),
      ],
    );
  }

  Widget _buildUnlockButton() {
    return GestureDetector(
      onTap: _showConfirmDialog,
      child: _glassCard(
        height: 66.h,
        borderColor: AppColors.accentLeaf.withOpacity(0.5),
        bg: AppColors.accentLeaf.withOpacity(0.1),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: AppColors.accentLeaf.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(CupertinoIcons.lock_fill,
                    color: AppColors.accentLeaf, size: 17.sp),
              ),
              SizedBox(width: 12.w),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "\$18 ENTRY FEE",
                    style: GoogleFonts.inter(
                      color: AppColors.accentLeaf,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "Tap to unlock 365-day mining plan",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 9.5.sp),
                  ),
                ],
              ),
              const Spacer(),
              Icon(CupertinoIcons.chevron_right,
                  color: AppColors.accentLeaf.withOpacity(0.5),
                  size: 14.sp),
            ],
          ),
        ),
      ),
    )
        .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
        .shimmer(
          duration: 2200.ms,
          color: AppColors.accentLeaf.withOpacity(0.14),
        );
  }

  // ── Stats Grid ───────────────────────────────────────────
  Widget _buildStatsGrid() {
    return Obx(() => Row(
          children: [
            Expanded(child: _statTile("SPEED", "450 TH/S", AppColors.accentGreen)),
            SizedBox(width: 8.w),
            Expanded(child: _statTile(
              "MINED DAYS",
              "${c.completedDays.value}",
              Colors.orangeAccent,
            )),
            SizedBox(width: 8.w),
            Expanded(child: _statTile(
              "DAYS LEFT",
              "${c.remainingDays.value}",
              AppColors.accentLeaf,
            )),
          ],
        ));
  }

  // ── Helpers ──────────────────────────────────────────────
  Widget _glassCard({
    required double height,
    required Color borderColor,
    required Color bg,
    required Widget child,
  }) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: height,
      borderRadius: 18.r,
      blur: 14,
      alignment: Alignment.center,
      border: 0.6,
      linearGradient: LinearGradient(colors: [bg, Colors.transparent]),
      borderGradient:
          LinearGradient(colors: [borderColor, Colors.transparent]),
      child: child,
    );
  }

  Widget _iosBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onTap, {
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 62.h,
        borderRadius: 16.r,
        blur: 10,
        alignment: Alignment.center,
        border: 0.6,
        linearGradient: LinearGradient(colors: [
          active ? color.withOpacity(0.14) : Colors.white.withOpacity(0.04),
          Colors.transparent,
        ]),
        borderGradient: LinearGradient(colors: [
          active ? color.withOpacity(0.55) : Colors.white.withOpacity(0.12),
          Colors.transparent,
        ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18.sp),
            SizedBox(height: 3.h),
            Text(
              label,
              style: GoogleFonts.inter(
                color: active ? color : Colors.white60,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 8.5.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialog Button Helper ─────────────────────────────────
  Widget _dialogBtn(
    String label,
    Color textColor,
    Color accentColor,
    bool filled, {
    IconData? icon,
  }) {
    return Container(
      height: 46.h,
      decoration: BoxDecoration(
        gradient: filled
            ? LinearGradient(
                colors: [accentColor, accentColor.withOpacity(0.75)])
            : null,
        color: filled ? null : Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: filled
              ? Colors.transparent
              : Colors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: 13.sp),
            SizedBox(width: 6.w),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────

  // Claim Dialog
  void _showClaimDialog() {
    if (!c.canClaim.value) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          "Claim Reward 🎉",
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w800, fontSize: 16.sp),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: Column(
            children: [
              SizedBox(height: 4.h),
              Text(
                "${c.balance.value.toStringAsFixed(4)} VXL",
                style: GoogleFonts.inter(
                  color: AppColors.accentGreen,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                "≈ \$100.00 USD",
                style: GoogleFonts.inter(
                    color: Colors.white54, fontSize: 12.sp),
              ),
              SizedBox(height: 10.h),
              Text(
                "আপনার ৩৬৫-দিনের মাইনিং প্ল্যান সম্পন্ন হয়েছে!\n\nআপনার ব্যালেন্স ক্লেইম করতে নিচের বাটনে ট্যাপ করুন।",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 12.sp, height: 1.55),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child:
                Text("Cancel", style: GoogleFonts.inter(fontSize: 15.sp)),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              c.claimBalance();
              Navigator.pop(ctx);
              _showClaimSuccessDialog();
            },
            child: Text(
              "Claim \$100",
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, fontSize: 15.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _showClaimSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          "🎉 Claim Successful!",
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w800, fontSize: 16.sp),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: Text(
            "${c.claimedAmount.value.toStringAsFixed(4)} VXL\n≈ \$100 USD\n\nসফলভাবে ক্লেইম হয়েছে! শীঘ্রই আপনার ওয়ালেটে পাঠানো হবে।",
            textAlign: TextAlign.center,
            style:
                GoogleFonts.inter(fontSize: 13.sp, height: 1.55),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text("OK 👍",
                style: GoogleFonts.inter(
                    fontSize: 15.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Confirm Plan Dialog
  void _showConfirmDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          "Confirm Payment",
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w800, fontSize: 16.sp),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: Text(
            "\$18.00 পেমেন্ট করুন\n\n"
            "সুবিধা: ৩৬৫ দিনে ১০,০০০ VXL আয় করুন\n\n"
            "প্রতিদিন ORB ট্যাপ করে মাইনিং শুরু করুন এবং প্রতিদিন VXL আয় করুন\n\n"
            "⚡ \$10-এ Auto Start অ্যাক্টিভ করুন\n\n"
            "👥 প্রতি রেফারেলে ১০ দিন কমবে",
            style: GoogleFonts.inter(fontSize: 12.sp, height: 1.55),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel",
                style: GoogleFonts.inter(fontSize: 15.sp)),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              c.activatePlan();
            },
            child: Text(
              "Pay \$18",
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, fontSize: 15.sp),
            ),
          ),
        ],
      ),
    );
  }

  // Auto Start Dialog
  void _showAutoStartDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassmorphicContainer(
            width: 300.w,
            height: 308.h,
            borderRadius: 24.r,
            blur: 24,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentOrange.withOpacity(0.12),
                Colors.black.withOpacity(0.88),
              ],
            ),
            borderGradient: LinearGradient(colors: [
              AppColors.accentOrange.withOpacity(0.65),
              AppColors.accentGreen.withOpacity(0.2),
            ]),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.bolt_fill,
                      color: AppColors.accentOrange, size: 32.sp),
                  SizedBox(height: 10.h),
                  Text(
                    "AUTO START MINING",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "প্রতিদিন নিজে নিজেই ORB শুরু হবে!\nকোনো ট্যাপ ছাড়াই মাইনিং চলবে।\nএকবার পেমেন্টে সারাজীবনের সুবিধা।",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 11.sp,
                        height: 1.55),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                          color: AppColors.accentOrange.withOpacity(0.3)),
                    ),
                    child: Column(children: [
                      Text(
                        "\$10.00",
                        style: GoogleFonts.inter(
                          color: AppColors.accentOrange,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "একবার পেমেন্ট · সারাজীবন অ্যাক্টিভ",
                        style: GoogleFonts.inter(
                            color: Colors.white38, fontSize: 9.sp),
                      ),
                    ]),
                  ),
                  SizedBox(height: 18.h),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: _dialogBtn("Cancel", Colors.white60,
                            Colors.white12, false),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          c.activateAutoStart();
                        },
                        child: _dialogBtn(
                          "Pay \$10",
                          Colors.white,
                          AppColors.accentOrange,
                          true,
                          icon: CupertinoIcons.bolt_fill,
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Boost Dialog
  void _showBoostDialog() {
    final TextEditingController amountCtrl = TextEditingController();
    double? previewVXL;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Center(
          child: Material(
            color: Colors.transparent,
            child: GlassmorphicContainer(
              width: 310.w,
              height: 316.h,
              borderRadius: 24.r,
              blur: 24,
              alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accentPurple.withOpacity(0.12),
                  Colors.black.withOpacity(0.88),
                ],
              ),
              borderGradient: LinearGradient(colors: [
                AppColors.accentPurple.withOpacity(0.65),
                AppColors.accentGreen.withOpacity(0.2),
              ]),
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 18.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.rocket_fill,
                        color: AppColors.accentPurple, size: 28.sp),
                    SizedBox(height: 8.h),
                    Text(
                      "BOOST MINING",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Max \$50  ·  Earn 2× in 80 days",
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 10.sp),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                            color: AppColors.accentPurple
                                .withOpacity(0.4)),
                      ),
                      child: TextField(
                        controller: amountCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 16.sp),
                        decoration: InputDecoration(
                          hintText: "Amount (\$1 – \$50)",
                          hintStyle: GoogleFonts.inter(
                              color: Colors.white30, fontSize: 11.sp),
                          prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 13.h),
                            child: Text(
                              "\$",
                              style: GoogleFonts.inter(
                                  color: AppColors.accentPurple,
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                              minWidth: 0, minHeight: 0),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 14.h),
                        ),
                        onChanged: (val) {
                          final v = double.tryParse(val);
                          setState(() {
                            previewVXL =
                                (v != null && v >= 1 && v <= 50)
                                    ? v * 2.0 * (10000.0 / 18.0)
                                    : null;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 10.h),
                    AnimatedSwitcher(
                      duration: 250.ms,
                      child: previewVXL != null
                          ? Container(
                              key: const ValueKey('preview'),
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 9.h),
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen
                                    .withOpacity(0.07),
                                borderRadius:
                                    BorderRadius.circular(10.r),
                                border: Border.all(
                                    color: AppColors.accentGreen
                                        .withOpacity(0.2)),
                              ),
                              child: Column(children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                        CupertinoIcons.arrow_up_right,
                                        color: AppColors.accentGreen,
                                        size: 11.sp),
                                    SizedBox(width: 5.w),
                                    Text(
                                      "You'll earn: ${previewVXL!.toStringAsFixed(2)} VXL",
                                      style: GoogleFonts.inter(
                                          color: AppColors.accentGreen,
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2.h),
                                Text("in 80 days",
                                    style: GoogleFonts.inter(
                                        color: Colors.white38,
                                        fontSize: 9.sp)),
                              ]),
                            )
                          : SizedBox(
                              key: const ValueKey('empty'),
                              height: 44.h),
                    ),
                    SizedBox(height: 14.h),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: _dialogBtn("Cancel", Colors.white60,
                              Colors.white12, false),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final v =
                                double.tryParse(amountCtrl.text);
                            if (v == null || v < 1 || v > 50) return;
                            Navigator.pop(ctx);
                            c.activateBoost(v);
                          },
                          child: _dialogBtn(
                            "BOOST",
                            Colors.white,
                            AppColors.accentPurple,
                            true,
                            icon: CupertinoIcons.rocket_fill,
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

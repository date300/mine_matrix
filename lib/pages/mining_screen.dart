import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_background/animated_background.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppColors {
  static const Color background   = Color(0xFF0D0D12);
  static const Color accentGreen  = Color(0xFF14F195);
  static const Color accentPurple = Color(0xFF9945FF);
  static const Color glassWhite   = Color(0xAAFFFFFF);
  static const Color accentLeaf   = Color(0xFF76C442);
  static const Color accentOrange = Color(0xFFFF9500); // Auto Start color
}

void main() => runApp(const VexylonApp());

class VexylonApp extends StatelessWidget {
  const VexylonApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppColors.background,
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          home: const MiningScreen(),
        );
      },
    );
  }
}

// ===================== CONTROLLER =====================
class MiningController extends GetxController {
  // ── Main Plan ──────────────────────────────────────────
  static const double entryFee        = 18.0;
  static const int    planDays        = 365;          // 360 → 365
  static const double targetVXL       = 10000.0;
  static const double dailyVXL        = targetVXL / planDays;
  static const int    ticksPerDay     = 864000;       // 100ms × 864000 = 24h
  static const double perTickEarning  = dailyVXL / ticksPerDay;

  // ── Boost Plan ─────────────────────────────────────────
  static const int    boostDays       = 80;
  static const int    totalBoostTicks = boostDays * ticksPerDay;

  // ── Auto Start ─────────────────────────────────────────
  static const double autoStartFee    = 10.0;

  // ── Observables ────────────────────────────────────────
  var isMining         = false.obs;
  var hasPaid          = false.obs;
  var isComplete       = false.obs;
  var balance          = 0.0.obs;
  var cycleProgress    = 0.0.obs;
  var planProgress     = 0.0.obs;
  var remainingDays    = planDays.obs;
  var totalEarned      = 0.0.obs;

  // Daily mining state
  var completedDays    = 0.obs;
  var currentDayNum    = 1.obs;
  var dayProgress      = 0.0.obs;
  var dayStarted       = false.obs;   // আজকের সেশন শুরু হয়েছে কিনা
  var canStartNewDay   = true.obs;    // নতুন দিনের উইন্ডো খোলা আছে কিনা
  var todayEarned      = 0.0.obs;

  // Auto Start
  var hasAutoStart     = false.obs;

  // Boost
  var boostPaid           = false.obs;
  var boostIsComplete     = false.obs;
  var boostAmount         = 0.0.obs;
  var boostProgress       = 0.0.obs;
  var boostRemainingDays  = boostDays.obs;
  var boostEarned         = 0.0.obs;
  var boostTotalVXL       = 0.0.obs;

  Timer? _timer;
  int    _dayElapsedTicks    = 0;
  int    _boostElapsedTicks  = 0;
  double _boostPerTick       = 0.0;

  // ── Plan Activation ────────────────────────────────────
  void activatePlan() {
    hasPaid.value         = true;
    isComplete.value      = false;
    _dayElapsedTicks      = 0;
    completedDays.value   = 0;
    currentDayNum.value   = 1;
    balance.value         = 0;
    totalEarned.value     = 0;
    planProgress.value    = 0;
    remainingDays.value   = planDays;
    dayProgress.value     = 0;
    dayStarted.value      = false;
    canStartNewDay.value  = true;
    todayEarned.value     = 0;
  }

  // ── Auto Start Activation ──────────────────────────────
  void activateAutoStart() {
    hasAutoStart.value = true;
    // প্ল্যান চালু থাকলে এবং আজকের উইন্ডো খোলা থাকলে অটো শুরু
    if (hasPaid.value && !isComplete.value &&
        !isMining.value && canStartNewDay.value && !dayStarted.value) {
      _startNewDay();
    }
  }

  // ── Orb Tap Handler ────────────────────────────────────
  void toggleMining() {
    if (!hasPaid.value || isComplete.value) return;

    if (isMining.value) {
      // Pause
      _timer?.cancel();
      isMining.value = false;
    } else if (dayStarted.value) {
      // Resume (একই দিনে থামানো ছিল)
      _resumeMining();
    } else if (canStartNewDay.value) {
      // নতুন দিন শুরু
      _startNewDay();
    }
    // !canStartNewDay && !dayStarted → দিন শেষ, পরের দিনের অপেক্ষা
  }

  void _startNewDay() {
    dayStarted.value     = true;
    canStartNewDay.value = false; // এই দিন আর নতুন করে শুরু করা যাবে না
    isMining.value       = true;
    _runTimer();
  }

  void _resumeMining() {
    isMining.value = true;
    _runTimer();
  }

  void _runTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      // ── দিন সম্পন্ন ───────────────────────────────
      if (_dayElapsedTicks >= ticksPerDay) {
        t.cancel();
        isMining.value     = false;
        dayStarted.value   = false;
        completedDays.value++;
        _dayElapsedTicks   = 0;
        dayProgress.value  = 0;
        todayEarned.value  = 0;

        if (completedDays.value >= planDays) {
          isComplete.value    = true;
          planProgress.value  = 1.0;
          remainingDays.value = 0;
          currentDayNum.value = planDays;
          return;
        }

        currentDayNum.value  = completedDays.value + 1;
        planProgress.value   = completedDays.value / planDays;
        remainingDays.value  = planDays - completedDays.value;

        // Real app: 24h অপেক্ষা | Demo: 2s পরে পরের দিন
        Future.delayed(const Duration(seconds: 2), () {
          if (!isComplete.value) {
            canStartNewDay.value = true;
            if (hasAutoStart.value) _startNewDay();
          }
        });
        return;
      }

      // ── Per-tick Earnings ─────────────────────────
      balance.value       += perTickEarning;
      totalEarned.value   += perTickEarning;
      todayEarned.value   += perTickEarning;
      cycleProgress.value  = (cycleProgress.value + 0.005) % 1.0;
      _dayElapsedTicks++;
      dayProgress.value    = _dayElapsedTicks / ticksPerDay;
      planProgress.value   =
          (completedDays.value * ticksPerDay + _dayElapsedTicks) /
          (planDays * ticksPerDay);
      remainingDays.value  =
          (planDays - completedDays.value - _dayElapsedTicks / ticksPerDay)
              .ceil()
              .clamp(0, planDays);

      // ── Boost ─────────────────────────────────────
      if (boostPaid.value && !boostIsComplete.value) {
        if (_boostElapsedTicks < totalBoostTicks) {
          balance.value          += _boostPerTick;
          boostEarned.value      += _boostPerTick;
          _boostElapsedTicks++;
          boostProgress.value     = _boostElapsedTicks / totalBoostTicks;
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

  // ── Boost Activation ───────────────────────────────────
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
    _timer?.cancel();
    super.onClose();
  }
}

// ===================== SCREEN =====================
class MiningScreen extends StatefulWidget {
  const MiningScreen({super.key});
  @override
  State<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen>
    with TickerProviderStateMixin {
  final MiningController controller = Get.put(MiningController());

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
                spawnOpacity: 0.1,
                particleCount: 15,
              ),
            ),
            child: Container(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _buildMiningContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiningContent() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Column(
        children: [
          SizedBox(height: 15.h),
          _buildBalanceSection(),
          SizedBox(height: 10.h),
          _buildPlanProgressSection(),
          SizedBox(height: 8.h),
          // Daily Section — শুধু প্ল্যান কেনার পর দেখাবে
          Obx(() => controller.hasPaid.value
              ? _buildDailySection()
              : const SizedBox.shrink()),
          SizedBox(height: 8.h),
          Obx(() => controller.boostPaid.value
              ? _buildBoostProgressSection()
              : const SizedBox.shrink()),
          SizedBox(height: 24.h),
          _buildMiningOrb(),
          SizedBox(height: 20.h),
          _buildCycleProgressBar(),
          SizedBox(height: 25.h),
          Obx(() => controller.hasPaid.value
              ? _buildActionButtons()
              : _buildEntryFeeButton()),
          SizedBox(height: 12.h),
          _buildStatsGrid(),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🗓 Daily Mining Section (নতুন)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildDailySection() {
    return Obx(() {
      final dayNum   = controller.currentDayNum.value;
      final prog     = controller.dayProgress.value;
      final earned   = controller.todayEarned.value;
      final mining   = controller.isMining.value;
      final started  = controller.dayStarted.value;
      final canStart = controller.canStartNewDay.value;
      final hasAuto  = controller.hasAutoStart.value;
      final complete = controller.isComplete.value;

      // Status text determination
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
        statusText  = "Paused — tap ORB to resume";
        statusColor = Colors.orange;
      } else if (!canStart && !started) {
        statusText  = "Today done — next day soon";
        statusColor = Colors.white38;
      } else {
        statusText  = "Tap ORB to start today";
        statusColor = AppColors.accentGreen.withOpacity(0.85);
      }

      final barColor = hasAuto ? AppColors.accentOrange : AppColors.accentGreen;

      return GlassmorphicContainer(
        width: double.infinity,
        height: 82.h,
        borderRadius: 16.r,
        blur: 10,
        alignment: Alignment.center,
        border: 0.5,
        linearGradient: LinearGradient(colors: [
          barColor.withOpacity(0.06),
          Colors.white.withOpacity(0.02),
        ]),
        borderGradient: LinearGradient(colors: [
          barColor.withOpacity(0.35),
          Colors.transparent,
        ]),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasAuto
                            ? CupertinoIcons.bolt_fill
                            : CupertinoIcons.calendar,
                        color: barColor,
                        size: 10.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        "DAY $dayNum / 365${hasAuto ? '   ⚡ AUTO' : ''}",
                        style: GoogleFonts.inter(
                          color: barColor,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${earned.toStringAsFixed(3)} / ${MiningController.dailyVXL.toStringAsFixed(2)} VXL",
                    style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: 9.sp),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              LinearPercentIndicator(
                lineHeight: 5.h,
                percent: prog.clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                linearGradient: LinearGradient(
                  colors: hasAuto
                      ? [AppColors.accentOrange, const Color(0xFFFFCC00)]
                      : [AppColors.accentGreen, AppColors.accentPurple],
                ),
                barRadius: const Radius.circular(10),
                padding: EdgeInsets.zero,
              ),
              SizedBox(height: 5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${(prog * 100).toStringAsFixed(2)}% of today",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 9.sp),
                  ),
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💰 Balance Section
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildBalanceSection() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 95.h,
      borderRadius: 20.r,
      blur: 20,
      alignment: Alignment.center,
      border: 0.5,
      linearGradient: LinearGradient(colors: [
        AppColors.accentGreen.withOpacity(0.05),
        Colors.white.withOpacity(0.02),
      ]),
      borderGradient: LinearGradient(
          colors: [AppColors.accentGreen.withOpacity(0.2), Colors.transparent]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "MINED BALANCE",
            style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2),
          ),
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.balance.value.toStringAsFixed(4),
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 30.sp,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    "VXL",
                    style: GoogleFonts.inter(
                        color: AppColors.accentGreen,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              )),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📊 Plan Progress (365 দিন)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildPlanProgressSection() {
    return Obx(() {
      final prog   = controller.planProgress.value;
      final left   = controller.remainingDays.value;
      final earned = controller.totalEarned.value;
      final done   = controller.completedDays.value;
      return GlassmorphicContainer(
        width: double.infinity,
        height: 76.h,
        borderRadius: 16.r,
        blur: 10,
        alignment: Alignment.center,
        border: 0.5,
        linearGradient: LinearGradient(colors: [
          AppColors.accentLeaf.withOpacity(0.06),
          Colors.white.withOpacity(0.02),
        ]),
        borderGradient: LinearGradient(colors: [
          AppColors.accentLeaf.withOpacity(0.35),
          Colors.transparent,
        ]),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "365-DAY PLAN  •  \$18 → \$100",
                    style: GoogleFonts.inter(
                        color: AppColors.accentLeaf,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8),
                  ),
                  Text(
                    "${earned.toStringAsFixed(1)} / 10,000 VXL",
                    style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: 9.sp),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              LinearPercentIndicator(
                lineHeight: 5.h,
                percent: prog.clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                linearGradient: LinearGradient(
                    colors: [AppColors.accentLeaf, const Color(0xFF2E8B00)]),
                barRadius: const Radius.circular(10),
                padding: EdgeInsets.zero,
              ),
              SizedBox(height: 5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$done / 365 days mined",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 9.sp),
                  ),
                  Text(
                    "$left days left",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 9.sp),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🚀 Boost Progress
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildBoostProgressSection() {
    return Obx(() {
      final prog     = controller.boostProgress.value;
      final left     = controller.boostRemainingDays.value;
      final earned   = controller.boostEarned.value;
      final total    = controller.boostTotalVXL.value;
      final complete = controller.boostIsComplete.value;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.rocket_fill,
                          color: AppColors.accentPurple, size: 10.sp),
                      SizedBox(width: 4.w),
                      Text(
                        "BOOST  •  \$${controller.boostAmount.value.toStringAsFixed(0)} → \$${(controller.boostAmount.value * 2).toStringAsFixed(0)}",
                        style: GoogleFonts.inter(
                            color: AppColors.accentPurple,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8),
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
                    ],
                  ),
                  Text(
                    "${earned.toStringAsFixed(1)} / ${total.toStringAsFixed(0)} VXL",
                    style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: 9.sp),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              LinearPercentIndicator(
                lineHeight: 5.h,
                percent: prog.clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                linearGradient: const LinearGradient(
                    colors: [AppColors.accentPurple, Color(0xFFCC44FF)]),
                barRadius: const Radius.circular(10),
                padding: EdgeInsets.zero,
              ),
              SizedBox(height: 5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${(prog * 100).toStringAsFixed(2)}% complete",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 9.sp),
                  ),
                  Text(
                    complete ? "Boost Complete!" : "$left days left",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 9.sp),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔮 Mining Orb (নতুন স্টেট: PAUSED, NEXT DAY, AUTO)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildMiningOrb() {
    return Obx(() {
      final active   = controller.isMining.value;
      final complete = controller.isComplete.value;
      final paid     = controller.hasPaid.value;
      final started  = controller.dayStarted.value;
      final canStart = controller.canStartNewDay.value;
      final hasAuto  = controller.hasAutoStart.value;

      final isPaused   = paid && started && !active && !complete;
      final isWaiting  = paid && !started && !canStart && !active && !complete;

      IconData    orbIcon;
      String      orbLabel;
      String      orbSubLabel = '';
      Color       orbIconColor;
      List<Color> borderColors;

      if (complete) {
        orbIcon      = CupertinoIcons.checkmark_seal_fill;
        orbLabel     = "COMPLETE";
        orbIconColor = AppColors.accentLeaf;
        borderColors = [AppColors.accentLeaf, const Color(0xFF2E8B00)];
      } else if (active && hasAuto) {
        orbIcon      = CupertinoIcons.bolt_fill;
        orbLabel     = "AUTO";
        orbSubLabel  = "MINING";
        orbIconColor = AppColors.accentOrange;
        borderColors = [AppColors.accentOrange, AppColors.accentGreen];
      } else if (active) {
        orbIcon      = CupertinoIcons.hammer_fill;
        orbLabel     = "MINING";
        orbIconColor = AppColors.accentGreen;
        borderColors = [AppColors.accentGreen, AppColors.accentPurple];
      } else if (isPaused) {
        orbIcon      = CupertinoIcons.pause_fill;
        orbLabel     = "PAUSED";
        orbSubLabel  = "Tap to resume";
        orbIconColor = Colors.orange;
        borderColors = [Colors.orange.withOpacity(0.6), Colors.white10];
      } else if (isWaiting) {
        orbIcon      = CupertinoIcons.clock_fill;
        orbLabel     = "NEXT DAY";
        orbSubLabel  = "Coming soon...";
        orbIconColor = Colors.white38;
        borderColors = [Colors.white24, Colors.white10];
      } else if (paid && canStart) {
        orbIcon      = CupertinoIcons.bolt_fill;
        orbLabel     = "START";
        orbSubLabel  = "Today's mining";
        orbIconColor = Colors.white70;
        borderColors = [Colors.white38, Colors.white10];
      } else {
        orbIcon      = CupertinoIcons.lock_fill;
        orbLabel     = "LOCKED";
        orbSubLabel  = "\$18 to unlock";
        orbIconColor = AppColors.accentLeaf.withOpacity(0.75);
        borderColors = [AppColors.accentLeaf.withOpacity(0.45), Colors.white10];
      }

      return GestureDetector(
        onTap: paid ? controller.toggleMining : _showConfirmDialog,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (active)
              Container(
                width: 160.w,
                height: 160.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (hasAuto
                            ? AppColors.accentOrange
                            : AppColors.accentGreen)
                        .withOpacity(0.5),
                    width: 2,
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
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
                  Text(
                    orbLabel,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (orbSubLabel.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      orbSubLabel,
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 8.sp),
                    ),
                  ],
                ],
              ),
            ).animate(target: active ? 1 : 0).shimmer(
                  duration: const Duration(milliseconds: 1500),
                  color: Colors.white24),
          ],
        ),
      );
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Cycle Bar
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildCycleProgressBar() {
    return Obx(() => LinearPercentIndicator(
          lineHeight: 6.h,
          percent: controller.cycleProgress.value,
          backgroundColor: Colors.white10,
          linearGradient: const LinearGradient(
              colors: [AppColors.accentPurple, AppColors.accentGreen]),
          barRadius: const Radius.circular(10),
          padding: EdgeInsets.zero,
        ));
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Action Buttons (CLAIM | BOOST | AUTO)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _smallButton(
              "CLAIM", CupertinoIcons.drop_fill, AppColors.accentGreen, null),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _smallButton("BOOST", CupertinoIcons.rocket_fill,
              AppColors.accentPurple, _showBoostDialog),
        ),
        SizedBox(width: 8.w),
        // AUTO button — কেনা থাকলে active style
        Expanded(
          child: Obx(() => controller.hasAutoStart.value
              ? _activeAutoButton()
              : _smallButton("AUTO", CupertinoIcons.bolt_fill,
                  AppColors.accentOrange, _showAutoStartDialog)),
        ),
      ],
    );
  }

  Widget _buildEntryFeeButton() {
    return GestureDetector(
      onTap: _showConfirmDialog,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 64.h,
        borderRadius: 18.r,
        blur: 14,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentLeaf.withOpacity(0.13),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderGradient: LinearGradient(
          colors: [AppColors.accentLeaf.withOpacity(0.55), Colors.transparent],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: AppColors.accentLeaf.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
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
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "Tap to unlock 365-day mining plan",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 10.sp),
                  ),
                ],
              ),
              const Spacer(),
              Icon(CupertinoIcons.chevron_right,
                  color: AppColors.accentLeaf.withOpacity(0.6), size: 15.sp),
            ],
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          duration: 2200.ms,
          color: AppColors.accentLeaf.withOpacity(0.18),
        );
  }

  Widget _smallButton(
      String label, IconData icon, Color color, VoidCallback? onTap) {
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
            LinearGradient(colors: [Colors.white24, Colors.transparent]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16.sp),
            SizedBox(width: 5.w),
            Text(label,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _activeAutoButton() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 60.h,
      borderRadius: 15.r,
      blur: 10,
      alignment: Alignment.center,
      border: 0.5,
      linearGradient: LinearGradient(colors: [
        AppColors.accentOrange.withOpacity(0.15),
        Colors.transparent,
      ]),
      borderGradient: LinearGradient(colors: [
        AppColors.accentOrange.withOpacity(0.6),
        Colors.transparent,
      ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.bolt_fill,
              color: AppColors.accentOrange, size: 16.sp),
          SizedBox(width: 5.w),
          Text("AUTO ON",
              style: GoogleFonts.inter(
                  color: AppColors.accentOrange,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Stats Grid
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildStatsGrid() {
    return Obx(() => Row(
          children: [
            Expanded(
                child:
                    _statBox("SPEED", "450 TH/S", AppColors.accentGreen)),
            SizedBox(width: 8.w),
            Expanded(
                child: _statBox(
                    "MINED DAYS",
                    "${controller.completedDays.value}",
                    Colors.orangeAccent)),
            SizedBox(width: 8.w),
            Expanded(
                child: _statBox("DAYS LEFT",
                    "${controller.remainingDays.value}", AppColors.accentLeaf)),
          ],
        ));
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold)),
          Text(value,
              style: GoogleFonts.inter(
                  color: color,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Dialogs
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void _showConfirmDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          "Confirm Payment",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Text(
            "\$18.00 পেমেন্ট নিশ্চিত করুন\n\n"
            "পরিকল্পনা: ৩৬৫ দিনে ১০,০০০ VXL অর্জন\n\n"
            "⚠️ প্রতিদিন নিজে ORB ট্যাপ করে মাইনিং শুরু করতে হবে। না করলে সেদিনের VXL মিস হবে।\n\n"
            "💡 \$10-এ Auto Start কিনলে আর প্রতিদিন ট্যাপ করতে হবে না।",
            style: GoogleFonts.inter(fontSize: 12.sp),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel",
                style: GoogleFonts.inter(fontSize: 14.sp)),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              controller.activatePlan();
            },
            child: Text("Pay \$18",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  // ── Auto Start Dialog (নতুন) ───────────────────────────
  void _showAutoStartDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassmorphicContainer(
            width: 300.w,
            height: 305.h,
            borderRadius: 22.r,
            blur: 22,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentOrange.withOpacity(0.12),
                Colors.black.withOpacity(0.8),
              ],
            ),
            borderGradient: LinearGradient(colors: [
              AppColors.accentOrange.withOpacity(0.7),
              AppColors.accentGreen.withOpacity(0.3),
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
                        letterSpacing: 1),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "প্রতিদিন নিজে ORB ট্যাপ করার\nঝামেলা থেকে মুক্তি!\nমাইনিং স্বয়ংক্রিয়ভাবে চালু হবে।",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 11.sp,
                        height: 1.5),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                          color: AppColors.accentOrange.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "\$10.00",
                          style: GoogleFonts.inter(
                              color: AppColors.accentOrange,
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w900),
                        ),
                        Text(
                          "এককালীন পেমেন্ট — পুরো ৩৬৫ দিন",
                          style: GoogleFonts.inter(
                              color: Colors.white38, fontSize: 9.sp),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            height: 46.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(13.r),
                              border:
                                  Border.all(color: Colors.white12, width: 1),
                            ),
                            alignment: Alignment.center,
                            child: Text("Cancel",
                                style: GoogleFonts.inter(
                                    color: Colors.white60, fontSize: 13.sp)),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            controller.activateAutoStart();
                          },
                          child: Container(
                            height: 46.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                AppColors.accentOrange,
                                AppColors.accentOrange.withOpacity(0.75),
                              ]),
                              borderRadius: BorderRadius.circular(13.r),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.bolt_fill,
                                    color: Colors.white, size: 14.sp),
                                SizedBox(width: 6.w),
                                Text("Pay \$10",
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Boost Dialog ──────────────────────────────────────
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
              width: 300.w,
              height: 310.h,
              borderRadius: 22.r,
              blur: 22,
              alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accentPurple.withOpacity(0.12),
                  Colors.black.withOpacity(0.8),
                ],
              ),
              borderGradient: LinearGradient(colors: [
                AppColors.accentPurple.withOpacity(0.7),
                AppColors.accentGreen.withOpacity(0.3),
              ]),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 18.h),
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
                          letterSpacing: 1),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Max \$50  •  Earn 2x in 80 days",
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 10.sp),
                    ),
                    SizedBox(height: 18.h),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(13.r),
                        border: Border.all(
                            color: AppColors.accentPurple.withOpacity(0.45),
                            width: 1),
                      ),
                      child: TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 16.sp),
                        decoration: InputDecoration(
                          hintText: "Enter amount (\$1 – \$50)",
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
                          prefixIconConstraints:
                              BoxConstraints(minWidth: 0.w, minHeight: 0.h),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 14.h),
                        ),
                        onChanged: (val) {
                          final v = double.tryParse(val);
                          setState(() {
                            previewVXL = (v != null && v >= 1 && v <= 50)
                                ? v * 2.0 * (10000.0 / 18.0)
                                : null;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 12.h),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: previewVXL != null
                          ? Container(
                              key: const ValueKey('preview'),
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                    color: AppColors.accentGreen
                                        .withOpacity(0.2)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(CupertinoIcons.arrow_up_right,
                                          color: AppColors.accentGreen,
                                          size: 12.sp),
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
                                  SizedBox(height: 3.h),
                                  Text("in 80 days",
                                      style: GoogleFonts.inter(
                                          color: Colors.white38,
                                          fontSize: 9.sp)),
                                ],
                              ),
                            )
                          : SizedBox(
                              key: const ValueKey('empty'), height: 44.h),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              height: 46.h,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(13.r),
                                border: Border.all(
                                    color: Colors.white12, width: 1),
                              ),
                              alignment: Alignment.center,
                              child: Text("Cancel",
                                  style: GoogleFonts.inter(
                                      color: Colors.white60, fontSize: 13.sp)),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              final v = double.tryParse(amountCtrl.text);
                              if (v == null || v < 1 || v > 50) return;
                              Navigator.pop(ctx);
                              controller.activateBoost(v);
                            },
                            child: Container(
                              height: 46.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  AppColors.accentPurple,
                                  AppColors.accentPurple.withOpacity(0.75),
                                ]),
                                borderRadius: BorderRadius.circular(13.r),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.rocket_fill,
                                      color: Colors.white, size: 14.sp),
                                  SizedBox(width: 6.w),
                                  Text("BOOST",
                                      style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

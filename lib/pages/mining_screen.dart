import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NOTE: `animated_background` and `flutter_screenutil` are intentionally
// removed for full cross-platform (mobile / web / desktop) compatibility.
// Responsive sizing is now handled via MediaQuery helpers defined below.
// Background is transparent (Colors.transparent / no scaffold background).
// Coin name changed from VXL → SOL (Solana).
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  static const Color background   = Colors.transparent;        // no background
  static const Color accentGreen  = Color(0xFF14F195);         // Solana green
  static const Color accentPurple = Color(0xFF9945FF);         // Solana purple
  static const Color glassWhite   = Color(0xAAFFFFFF);
  static const Color accentLeaf   = Color(0xFF76C442);
  static const Color accentOrange = Color(0xFFFF9500);
}

// ─────────────────────────────────────────────────────────────────────────────
// Responsive helpers (replaces flutter_screenutil)
// ─────────────────────────────────────────────────────────────────────────────
class R {
  static late BuildContext _ctx;
  static void init(BuildContext ctx) => _ctx = ctx;

  static double get _w => MediaQuery.of(_ctx).size.width;
  static double get _h => MediaQuery.of(_ctx).size.height;

  // Base design size: 360 × 690 (mobile reference)
  static double w(double v) => v * (_w / 360).clamp(0.7, 2.5);
  static double h(double v) => v * (_h / 690).clamp(0.7, 2.5);
  static double sp(double v) => v * ((_w + _h) / (360 + 690)).clamp(0.75, 2.0);
  static double r(double v) => v * (_w / 360).clamp(0.7, 2.0);

  /// Max content width for desktop/tablet (keeps card narrow and centred)
  static double get contentWidth => _w < 600 ? _w : 520;
}

// ─────────────────────────────────────────────────────────────────────────────
void main() => runApp(const SolanaApp());

class SolanaApp extends StatelessWidget {
  const SolanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MiningScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────
class MiningController extends GetxController {
  // Main Plan
  static const double entryFee       = 18.0;
  static const int    planDays       = 365;
  static const double targetSOL      = 10000.0;
  static const double dailySOL       = targetSOL / planDays;
  static const int    ticksPerDay    = 864000;          // 100 ms × 864000 = 24 h
  static const double perTickEarning = dailySOL / ticksPerDay;

  // Boost Plan
  static const int    boostDays       = 80;
  static const int    totalBoostTicks = boostDays * ticksPerDay;

  // Auto Start
  static const double autoStartFee = 10.0;

  // Observables
  var isMining        = false.obs;
  var hasPaid         = false.obs;
  var isComplete      = false.obs;
  var balance         = 0.0.obs;
  var cycleProgress   = 0.0.obs;
  var planProgress    = 0.0.obs;
  var remainingDays   = planDays.obs;
  var totalEarned     = 0.0.obs;

  var completedDays   = 0.obs;
  var currentDayNum   = 1.obs;
  var dayProgress     = 0.0.obs;
  var dayStarted      = false.obs;
  var canStartNewDay  = true.obs;
  var todayEarned     = 0.0.obs;

  var hasAutoStart    = false.obs;

  var boostPaid           = false.obs;
  var boostIsComplete     = false.obs;
  var boostAmount         = 0.0.obs;
  var boostProgress       = 0.0.obs;
  var boostRemainingDays  = boostDays.obs;
  var boostEarned         = 0.0.obs;
  var boostTotalSOL       = 0.0.obs;

  Timer? _timer;
  int    _dayElapsedTicks   = 0;
  int    _boostElapsedTicks = 0;
  double _boostPerTick      = 0.0;

  void activatePlan() {
    hasPaid.value        = true;
    isComplete.value     = false;
    _dayElapsedTicks     = 0;
    completedDays.value  = 0;
    currentDayNum.value  = 1;
    balance.value        = 0;
    totalEarned.value    = 0;
    planProgress.value   = 0;
    remainingDays.value  = planDays;
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

        currentDayNum.value = completedDays.value + 1;
        planProgress.value  = completedDays.value / planDays;
        remainingDays.value = planDays - completedDays.value;

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
      planProgress.value  =
          (completedDays.value * ticksPerDay + _dayElapsedTicks) /
          (planDays * ticksPerDay);
      remainingDays.value =
          (planDays - completedDays.value - _dayElapsedTicks / ticksPerDay)
              .ceil()
              .clamp(0, planDays);

      if (boostPaid.value && !boostIsComplete.value) {
        if (_boostElapsedTicks < totalBoostTicks) {
          balance.value      += _boostPerTick;
          boostEarned.value  += _boostPerTick;
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

  void activateBoost(double amount) {
    boostPaid.value          = true;
    boostIsComplete.value    = false;
    boostAmount.value        = amount;
    _boostElapsedTicks       = 0;
    boostProgress.value      = 0;
    boostEarned.value        = 0;
    boostRemainingDays.value = boostDays;
    final total              = amount * 2.0 * (10000.0 / 18.0);
    boostTotalSOL.value      = total;
    _boostPerTick            = total / totalBoostTicks;
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
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
    R.init(context);

    return Scaffold(
      backgroundColor: Colors.transparent,  // ← no background
      body: Center(
        child: SizedBox(
          width: R.contentWidth,            // centred on large screens
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _buildMiningContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiningContent() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: R.w(18)),
      child: Column(
        children: [
          SizedBox(height: R.h(15)),
          _buildBalanceSection(),
          SizedBox(height: R.h(10)),
          _buildPlanProgressSection(),
          SizedBox(height: R.h(8)),
          Obx(() => controller.hasPaid.value
              ? _buildDailySection()
              : const SizedBox.shrink()),
          SizedBox(height: R.h(8)),
          Obx(() => controller.boostPaid.value
              ? _buildBoostProgressSection()
              : const SizedBox.shrink()),
          SizedBox(height: R.h(24)),
          _buildMiningOrb(),
          SizedBox(height: R.h(20)),
          _buildCycleProgressBar(),
          SizedBox(height: R.h(25)),
          Obx(() => controller.hasPaid.value
              ? _buildActionButtons()
              : _buildEntryFeeButton()),
          SizedBox(height: R.h(12)),
          _buildStatsGrid(),
          SizedBox(height: R.h(20)),
        ],
      ),
    );
  }

  // ── Daily Section ───────────────────────────────────────────────────────────
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

      final barColor = hasAuto ? AppColors.accentOrange : AppColors.accentGreen;

      return GlassmorphicContainer(
        width: double.infinity,
        height: R.h(82),
        borderRadius: R.r(16),
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
          padding: EdgeInsets.symmetric(
              horizontal: R.w(14), vertical: R.h(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      size: R.sp(10),
                    ),
                    SizedBox(width: R.w(4)),
                    Text(
                      "DAY $dayNum / 365${hasAuto ? '   ⚡ AUTO' : ''}",
                      style: GoogleFonts.inter(
                        color: barColor,
                        fontSize: R.sp(9),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ]),
                  Text(
                    "${earned.toStringAsFixed(3)} / ${MiningController.dailySOL.toStringAsFixed(2)} SOL",
                    style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: R.sp(9)),
                  ),
                ],
              ),
              SizedBox(height: R.h(6)),
              LinearPercentIndicator(
                lineHeight: R.h(5),
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
              SizedBox(height: R.h(5)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${(prog * 100).toStringAsFixed(2)}% of today",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: R.sp(9)),
                  ),
                  Text(
                    statusText,
                    style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: R.sp(9),
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

  // ── Balance Section ─────────────────────────────────────────────────────────
  Widget _buildBalanceSection() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: R.h(95),
      borderRadius: R.r(20),
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
          Text(
            "MINED BALANCE",
            style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: R.sp(10),
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
                        fontSize: R.sp(30),
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: R.w(5)),
                  Text(
                    "SOL",
                    style: GoogleFonts.inter(
                        color: AppColors.accentGreen,
                        fontSize: R.sp(14),
                        fontWeight: FontWeight.w800),
                  ),
                ],
              )),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  // ── Plan Progress ───────────────────────────────────────────────────────────
  Widget _buildPlanProgressSection() {
    return Obx(() {
      final prog   = controller.planProgress.value;
      final left   = controller.remainingDays.value;
      final earned = controller.totalEarned.value;
      final done   = controller.completedDays.value;
      return GlassmorphicContainer(
        width: double.infinity,
        height: R.h(76),
        borderRadius: R.r(16),
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
          padding: EdgeInsets.symmetric(
              horizontal: R.w(14), vertical: R.h(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "365-DAY PLAN  ·  \$18 → \$100",
                    style: GoogleFonts.inter(
                        color: AppColors.accentLeaf,
                        fontSize: R.sp(9),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8),
                  ),
                  Text(
                    "${earned.toStringAsFixed(1)} / 10,000 SOL",
                    style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: R.sp(9)),
                  ),
                ],
              ),
              SizedBox(height: R.h(6)),
              LinearPercentIndicator(
                lineHeight: R.h(5),
                percent: prog.clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                linearGradient: const LinearGradient(
                    colors: [AppColors.accentLeaf, Color(0xFF2E8B00)]),
                barRadius: const Radius.circular(10),
                padding: EdgeInsets.zero,
              ),
              SizedBox(height: R.h(5)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$done / 365 days mined",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: R.sp(9)),
                  ),
                  Text(
                    "$left days left",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: R.sp(9)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Boost Progress ──────────────────────────────────────────────────────────
  Widget _buildBoostProgressSection() {
    return Obx(() {
      final prog     = controller.boostProgress.value;
      final left     = controller.boostRemainingDays.value;
      final earned   = controller.boostEarned.value;
      final total    = controller.boostTotalSOL.value;
      final complete = controller.boostIsComplete.value;
      return GlassmorphicContainer(
        width: double.infinity,
        height: R.h(72),
        borderRadius: R.r(16),
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
          padding: EdgeInsets.symmetric(
              horizontal: R.w(14), vertical: R.h(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(CupertinoIcons.rocket_fill,
                        color: AppColors.accentPurple, size: R.sp(10)),
                    SizedBox(width: R.w(4)),
                    Text(
                      "BOOST  ·  \$${controller.boostAmount.value.toStringAsFixed(0)} → \$${(controller.boostAmount.value * 2).toStringAsFixed(0)}",
                      style: GoogleFonts.inter(
                          color: AppColors.accentPurple,
                          fontSize: R.sp(9),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8),
                    ),
                    if (complete) ...[
                      SizedBox(width: R.w(6)),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: R.w(6), vertical: R.h(2)),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(R.r(4)),
                        ),
                        child: Text("DONE",
                            style: GoogleFonts.inter(
                                color: AppColors.accentGreen,
                                fontSize: R.sp(7),
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  Text(
                    "${earned.toStringAsFixed(1)} / ${total.toStringAsFixed(0)} SOL",
                    style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: R.sp(9)),
                  ),
                ],
              ),
              SizedBox(height: R.h(6)),
              LinearPercentIndicator(
                lineHeight: R.h(5),
                percent: prog.clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                linearGradient: const LinearGradient(
                    colors: [AppColors.accentPurple, Color(0xFFCC44FF)]),
                barRadius: const Radius.circular(10),
                padding: EdgeInsets.zero,
              ),
              SizedBox(height: R.h(5)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${(prog * 100).toStringAsFixed(2)}% complete",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: R.sp(9)),
                  ),
                  Text(
                    complete ? "Boost Complete!" : "$left days left",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: R.sp(9)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Mining Orb ──────────────────────────────────────────────────────────────
  Widget _buildMiningOrb() {
    return Obx(() {
      final active   = controller.isMining.value;
      final complete = controller.isComplete.value;
      final paid     = controller.hasPaid.value;
      final started  = controller.dayStarted.value;
      final canStart = controller.canStartNewDay.value;
      final hasAuto  = controller.hasAutoStart.value;

      final isPaused  = paid && started && !active && !complete;
      final isWaiting = paid && !started && !canStart && !active && !complete;

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

      final orbSize = R.w(140);

      return GestureDetector(
        onTap: paid ? controller.toggleMining : _showConfirmDialog,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (active)
              Container(
                width: R.w(160),
                height: R.w(160),
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
              width: orbSize,
              height: orbSize,
              borderRadius: orbSize / 2,
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
                  Icon(orbIcon, color: orbIconColor, size: R.sp(35)),
                  SizedBox(height: R.h(5)),
                  Text(
                    orbLabel,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: R.sp(12),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (orbSubLabel.isNotEmpty) ...[
                    SizedBox(height: R.h(2)),
                    Text(
                      orbSubLabel,
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: R.sp(8)),
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

  // ── Cycle Bar ───────────────────────────────────────────────────────────────
  Widget _buildCycleProgressBar() {
    return Obx(() => LinearPercentIndicator(
          lineHeight: R.h(6),
          percent: controller.cycleProgress.value,
          backgroundColor: Colors.white10,
          linearGradient: const LinearGradient(
              colors: [AppColors.accentPurple, AppColors.accentGreen]),
          barRadius: const Radius.circular(10),
          padding: EdgeInsets.zero,
        ));
  }

  // ── Action Buttons ──────────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _smallButton(
              "CLAIM", CupertinoIcons.drop_fill, AppColors.accentGreen, null),
        ),
        SizedBox(width: R.w(8)),
        Expanded(
          child: _smallButton("BOOST", CupertinoIcons.rocket_fill,
              AppColors.accentPurple, _showBoostDialog),
        ),
        SizedBox(width: R.w(8)),
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
        height: R.h(64),
        borderRadius: R.r(18),
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
        borderGradient: LinearGradient(colors: [
          AppColors.accentLeaf.withOpacity(0.55),
          Colors.transparent,
        ]),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: R.w(16)),
          child: Row(
            children: [
              Container(
                width: R.w(36),
                height: R.w(36),
                decoration: BoxDecoration(
                  color: AppColors.accentLeaf.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(R.r(10)),
                ),
                child: Icon(CupertinoIcons.lock_fill,
                    color: AppColors.accentLeaf, size: R.sp(17)),
              ),
              SizedBox(width: R.w(12)),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "\$18 ENTRY FEE",
                    style: GoogleFonts.inter(
                      color: AppColors.accentLeaf,
                      fontSize: R.sp(13),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: R.h(2)),
                  Text(
                    "Tap to unlock 365-day Solana mining plan",
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: R.sp(10)),
                  ),
                ],
              ),
              const Spacer(),
              Icon(CupertinoIcons.chevron_right,
                  color: AppColors.accentLeaf.withOpacity(0.6),
                  size: R.sp(15)),
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
        height: R.h(60),
        borderRadius: R.r(15),
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
            Icon(icon, color: color, size: R.sp(16)),
            SizedBox(width: R.w(5)),
            Text(label,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: R.sp(11),
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _activeAutoButton() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: R.h(60),
      borderRadius: R.r(15),
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
              color: AppColors.accentOrange, size: R.sp(16)),
          SizedBox(width: R.w(5)),
          Text("AUTO ON",
              style: GoogleFonts.inter(
                  color: AppColors.accentOrange,
                  fontSize: R.sp(11),
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── Stats Grid ──────────────────────────────────────────────────────────────
  Widget _buildStatsGrid() {
    return Obx(() => Row(
          children: [
            Expanded(
                child: _statBox("SPEED", "450 TH/S", AppColors.accentGreen)),
            SizedBox(width: R.w(8)),
            Expanded(
                child: _statBox("MINED DAYS",
                    "${controller.completedDays.value}", Colors.orangeAccent)),
            SizedBox(width: R.w(8)),
            Expanded(
                child: _statBox("DAYS LEFT",
                    "${controller.remainingDays.value}",
                    AppColors.accentLeaf)),
          ],
        ));
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(R.w(10)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(R.r(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: R.sp(9),
                  fontWeight: FontWeight.bold)),
          Text(value,
              style: GoogleFonts.inter(
                  color: color,
                  fontSize: R.sp(14),
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────
  void _showConfirmDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          "Confirm Payment",
          style: GoogleFonts.inter(
              fontWeight: FontWeight.bold, fontSize: R.sp(16)),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: R.h(6)),
          child: Text(
            "\$18.00 payment required\n\n"
            "You will earn 10,000 SOL over 365 days\n\n"
            "Tap the ORB each day to start mining and earn daily SOL\n\n"
            "Add \$10 Auto Start so mining begins automatically",
            style: GoogleFonts.inter(fontSize: R.sp(12)),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel",
                style: GoogleFonts.inter(fontSize: R.sp(14))),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              controller.activatePlan();
            },
            child: Text("Pay \$18",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: R.sp(14))),
          ),
        ],
      ),
    );
  }

  void _showAutoStartDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: GlassmorphicContainer(
            width: R.w(300),
            height: R.h(305),
            borderRadius: R.r(22),
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
              padding: EdgeInsets.fromLTRB(
                  R.w(20), R.h(24), R.w(20), R.h(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.bolt_fill,
                      color: AppColors.accentOrange, size: R.sp(32)),
                  SizedBox(height: R.h(10)),
                  Text(
                    "AUTO START MINING",
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: R.sp(15),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1),
                  ),
                  SizedBox(height: R.h(8)),
                  Text(
                    "Mining starts automatically each day\nNo need to tap the ORB!\nSit back and earn SOL hands-free",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: R.sp(11),
                        height: 1.5),
                  ),
                  SizedBox(height: R.h(16)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: R.h(12)),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(R.r(12)),
                      border: Border.all(
                          color: AppColors.accentOrange.withOpacity(0.3)),
                    ),
                    child: Column(children: [
                      Text(
                        "\$10.00",
                        style: GoogleFonts.inter(
                            color: AppColors.accentOrange,
                            fontSize: R.sp(26),
                            fontWeight: FontWeight.w900),
                      ),
                      Text(
                        "one-time fee · lifetime auto mining",
                        style: GoogleFonts.inter(
                            color: Colors.white38, fontSize: R.sp(9)),
                      ),
                    ]),
                  ),
                  SizedBox(height: R.h(18)),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          height: R.h(46),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(R.r(13)),
                            border:
                                Border.all(color: Colors.white12, width: 1),
                          ),
                          alignment: Alignment.center,
                          child: Text("Cancel",
                              style: GoogleFonts.inter(
                                  color: Colors.white60,
                                  fontSize: R.sp(13))),
                        ),
                      ),
                    ),
                    SizedBox(width: R.w(10)),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          controller.activateAutoStart();
                        },
                        child: Container(
                          height: R.h(46),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              AppColors.accentOrange,
                              AppColors.accentOrange.withOpacity(0.75),
                            ]),
                            borderRadius: BorderRadius.circular(R.r(13)),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.bolt_fill,
                                  color: Colors.white, size: R.sp(14)),
                              SizedBox(width: R.w(6)),
                              Text("Pay \$10",
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: R.sp(13),
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
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

  void _showBoostDialog() {
    final TextEditingController amountCtrl = TextEditingController();
    double? previewSOL;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Center(
          child: Material(
            color: Colors.transparent,
            child: GlassmorphicContainer(
              width: R.w(300),
              height: R.h(310),
              borderRadius: R.r(22),
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
                padding: EdgeInsets.fromLTRB(
                    R.w(20), R.h(22), R.w(20), R.h(18)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.rocket_fill,
                        color: AppColors.accentPurple, size: R.sp(28)),
                    SizedBox(height: R.h(8)),
                    Text(
                      "BOOST MINING",
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: R.sp(16),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1),
                    ),
                    SizedBox(height: R.h(4)),
                    Text(
                      "Max \$50  ·  Earn 2x in 80 days",
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: R.sp(10)),
                    ),
                    SizedBox(height: R.h(18)),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(R.r(13)),
                        border: Border.all(
                            color: AppColors.accentPurple.withOpacity(0.45),
                            width: 1),
                      ),
                      child: TextField(
                        controller: amountCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: R.sp(16)),
                        decoration: InputDecoration(
                          hintText: "Enter amount (\$1 – \$50)",
                          hintStyle: GoogleFonts.inter(
                              color: Colors.white30, fontSize: R.sp(11)),
                          prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: R.w(12), vertical: R.h(13)),
                            child: Text(
                              "\$",
                              style: GoogleFonts.inter(
                                  color: AppColors.accentPurple,
                                  fontSize: R.sp(17),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                              minWidth: 0, minHeight: 0),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: R.w(12), vertical: R.h(14)),
                        ),
                        onChanged: (val) {
                          final v = double.tryParse(val);
                          setState(() {
                            previewSOL = (v != null && v >= 1 && v <= 50)
                                ? v * 2.0 * (10000.0 / 18.0)
                                : null;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: R.h(12)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: previewSOL != null
                          ? Container(
                              key: const ValueKey('preview'),
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                  horizontal: R.w(12), vertical: R.h(10)),
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen.withOpacity(0.07),
                                borderRadius:
                                    BorderRadius.circular(R.r(10)),
                                border: Border.all(
                                    color: AppColors.accentGreen
                                        .withOpacity(0.2)),
                              ),
                              child: Column(children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.arrow_up_right,
                                        color: AppColors.accentGreen,
                                        size: R.sp(12)),
                                    SizedBox(width: R.w(5)),
                                    Text(
                                      "You'll earn: ${previewSOL!.toStringAsFixed(2)} SOL",
                                      style: GoogleFonts.inter(
                                          color: AppColors.accentGreen,
                                          fontSize: R.sp(11),
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                SizedBox(height: R.h(3)),
                                Text("in 80 days",
                                    style: GoogleFonts.inter(
                                        color: Colors.white38,
                                        fontSize: R.sp(9))),
                              ]),
                            )
                          : SizedBox(key: const ValueKey('empty'), height: R.h(44)),
                    ),
                    SizedBox(height: R.h(16)),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            height: R.h(46),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(R.r(13)),
                              border: Border.all(
                                  color: Colors.white12, width: 1),
                            ),
                            alignment: Alignment.center,
                            child: Text("Cancel",
                                style: GoogleFonts.inter(
                                    color: Colors.white60,
                                    fontSize: R.sp(13))),
                          ),
                        ),
                      ),
                      SizedBox(width: R.w(10)),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final v = double.tryParse(amountCtrl.text);
                            if (v == null || v < 1 || v > 50) return;
                            Navigator.pop(ctx);
                            controller.activateBoost(v);
                          },
                          child: Container(
                            height: R.h(46),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                AppColors.accentPurple,
                                AppColors.accentPurple.withOpacity(0.75),
                              ]),
                              borderRadius: BorderRadius.circular(R.r(13)),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.rocket_fill,
                                    color: Colors.white, size: R.sp(14)),
                                SizedBox(width: R.w(6)),
                                Text("BOOST",
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: R.sp(13),
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
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

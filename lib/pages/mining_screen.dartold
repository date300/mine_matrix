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

class MiningController extends GetxController {
  // ── Main Plan ──────────────────────────────────────
  static const double entryFee        = 18.0;
  static const int    planDays        = 360;
  static const double targetVXL       = 10000.0;
  static const double perTickEarning  = targetVXL / (planDays * 864000.0);
  static const int    totalPlanTicks  = planDays * 864000;

  // ── Boost Plan ─────────────────────────────────────
  static const int boostDays       = 80;
  static const int totalBoostTicks = boostDays * 864000;

  var isMining       = false.obs;
  var hasPaid        = false.obs;
  var isComplete     = false.obs;
  var balance        = 0.0.obs;
  var cycleProgress  = 0.0.obs;
  var planProgress   = 0.0.obs;
  var remainingDays  = planDays.obs;
  var totalEarned    = 0.0.obs;

  // Boost
  var boostPaid          = false.obs;
  var boostIsComplete    = false.obs;
  var boostAmount        = 0.0.obs;
  var boostProgress      = 0.0.obs;
  var boostRemainingDays = boostDays.obs;
  var boostEarned        = 0.0.obs;
  var boostTotalVXL      = 0.0.obs;

  Timer? _timer;
  int    _elapsedTicks      = 0;
  int    _boostElapsedTicks = 0;
  double _boostPerTick      = 0.0;

  void activatePlan() {
    hasPaid.value       = true;
    isComplete.value    = false;
    _elapsedTicks       = 0;
    balance.value       = 0;
    totalEarned.value   = 0;
    planProgress.value  = 0;
    remainingDays.value = planDays;
  }

  void activateBoost(double amount) {
    boostPaid.value          = true;
    boostIsComplete.value    = false;
    boostAmount.value        = amount;
    _boostElapsedTicks       = 0;
    boostProgress.value      = 0;
    boostEarned.value        = 0;
    boostRemainingDays.value = boostDays;
    // $50 → $100 worth VXL | $18 = 10000 VXL → $X boost = X*2*(10000/18) VXL
    final total = amount * 2.0 * (10000.0 / 18.0);
    boostTotalVXL.value = total;
    _boostPerTick       = total / totalBoostTicks;
  }

  void toggleMining() {
    if (!hasPaid.value || isComplete.value) return;
    isMining.value = !isMining.value;
    if (isMining.value) {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        // ── Main Plan ──
        if (_elapsedTicks >= totalPlanTicks) {
          isComplete.value = true;
          isMining.value   = false;
          t.cancel();
          return;
        }
        balance.value       += perTickEarning;
        totalEarned.value   += perTickEarning;
        cycleProgress.value  = (cycleProgress.value + 0.005) % 1.0;
        _elapsedTicks++;
        planProgress.value  = _elapsedTicks / totalPlanTicks;
        remainingDays.value =
            (planDays - _elapsedTicks / 864000.0).ceil().clamp(0, planDays);

        // ── Boost Plan (runs simultaneously) ──
        if (boostPaid.value && !boostIsComplete.value) {
          if (_boostElapsedTicks < totalBoostTicks) {
            balance.value            += _boostPerTick;
            boostEarned.value        += _boostPerTick;
            _boostElapsedTicks++;
            boostProgress.value       = _boostElapsedTicks / totalBoostTicks;
            boostRemainingDays.value  =
                (boostDays - _boostElapsedTicks / 864000.0)
                    .ceil()
                    .clamp(0, boostDays);
          } else {
            boostIsComplete.value = true;
          }
        }
      });
    } else {
      _timer?.cancel();
    }
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
          SafeArea(child: _buildMiningContent()),
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
          Obx(() => controller.boostPaid.value
              ? _buildBoostProgressSection()
              : const SizedBox.shrink()),
          const Spacer(),
          _buildMiningOrb(),
          const Spacer(),
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

  // ── Entry Fee Button ────────────────────────────
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
                    "Tap to unlock mining plan",
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

  // ── Balance Section ─────────────────────────────
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

  // ── Plan Progress ────────────────────────────────
  Widget _buildPlanProgressSection() {
    return Obx(() {
      final prog   = controller.planProgress.value;
      final left   = controller.remainingDays.value;
      final earned = controller.totalEarned.value;
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
                    "360-DAY PLAN  •  \$18 → \$100",
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
                    "${(prog * 100).toStringAsFixed(2)}% complete",
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

  // ── Boost Progress ───────────────────────────────
  Widget _buildBoostProgressSection() {
    return Obx(() {
      final prog     = controller.boostProgress.value;
      final left     = controller.boostRemainingDays.value;
      final earned   = controller.boostEarned.value;
      final total    = controller.boostTotalVXL.value;
      final complete = controller.boostIsComplete.value;
      return Padding(
        padding: EdgeInsets.only(bottom: 0.h),
        child: GlassmorphicContainer(
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
        ),
      );
    });
  }

  // ── Mining Orb ───────────────────────────────────
  Widget _buildMiningOrb() {
    return Obx(() {
      final active   = controller.isMining.value;
      final complete = controller.isComplete.value;
      final paid     = controller.hasPaid.value;

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
                      color: AppColors.accentGreen.withOpacity(0.5), width: 2),
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
              borderGradient: LinearGradient(
                colors: complete
                    ? [AppColors.accentLeaf, const Color(0xFF2E8B00)]
                    : active
                        ? [AppColors.accentGreen, AppColors.accentPurple]
                        : paid
                            ? [Colors.white24, Colors.white10]
                            : [
                                AppColors.accentLeaf.withOpacity(0.45),
                                Colors.white10,
                              ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    complete
                        ? CupertinoIcons.checkmark_seal_fill
                        : active
                            ? CupertinoIcons.hammer_fill
                            : paid
                                ? CupertinoIcons.bolt_fill
                                : CupertinoIcons.lock_fill,
                    color: complete
                        ? AppColors.accentLeaf
                        : active
                            ? AppColors.accentGreen
                            : paid
                                ? Colors.white38
                                : AppColors.accentLeaf.withOpacity(0.75),
                    size: 35.sp,
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    complete
                        ? "COMPLETE"
                        : active
                            ? "MINING"
                            : paid
                                ? "START"
                                : "LOCKED",
                    style: GoogleFonts.inter(
                      color: !paid
                          ? AppColors.accentLeaf.withOpacity(0.85)
                          : Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (!paid) ...[
                    SizedBox(height: 2.h),
                    Text(
                      "\$18 to unlock",
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 9.sp),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
            child: _smallButton(
                "CLAIM", CupertinoIcons.drop_fill, AppColors.accentGreen, null)),
        SizedBox(width: 12.w),
        Expanded(
            child: _smallButton("BOOST", CupertinoIcons.rocket_fill,
                AppColors.accentPurple, _showBoostDialog)),
      ],
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
            Icon(icon, color: color, size: 18.sp),
            SizedBox(width: 8.w),
            Text(label,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Obx(() => Row(
          children: [
            Expanded(
                child:
                    _statBox("SPEED", "450 TH/S", AppColors.accentGreen)),
            SizedBox(width: 8.w),
            Expanded(child: _statBox("REFS", "12", Colors.orangeAccent)),
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

  // ── Confirm Dialog ───────────────────────────────
  void _showConfirmDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          "Confirm Payment",
          style:
              GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Text(
            "\$18.00 পেমেন্ট করে মাইনিং প্ল্যান আনলক করুন\n\nলক্ষ্যমাত্রা: \$100 সমতুল্য VXL অর্জন করুন",
            style: GoogleFonts.inter(fontSize: 13.sp),
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

  // ── Boost Dialog ─────────────────────────────────
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
                    // Header
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

                    // Amount Input
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
                            if (v != null && v >= 1 && v <= 50) {
                              previewVXL = v * 2.0 * (10000.0 / 18.0);
                            } else {
                              previewVXL = null;
                            }
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Preview
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
                                    color:
                                        AppColors.accentGreen.withOpacity(0.2)),
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

                    // Buttons
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
                                      color: Colors.white60,
                                      fontSize: 13.sp)),
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

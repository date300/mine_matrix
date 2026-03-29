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
  static const Color background = Color(0xFF0D0D12);
  static const Color accentGreen = Color(0xFF14F195);
  static const Color accentPurple = Color(0xFF9945FF);
  static const Color glassWhite = Color(0xAAFFFFFF);
  static const Color accentGold = Color(0xFFFFD700);
}

void main() {
  runApp(const VexylonApp());
}

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
  // ===== প্ল্যান কনফিগ =====
  static const double entryFee = 18.0;       // $18 এন্ট্রি ফি
  static const int planDays = 360;            // ৩৬০ দিন
  static const double targetVXL = 10000.0;   // ১০,০০০ VXL = $100

  // ১০০ms টিক-এ কত VXL: 10000 / (360 * 24 * 60 * 60 * 10)
  static const double perTickEarning = targetVXL / (planDays * 864000.0);
  static const int totalPlanTicks = planDays * 864000;

  var isMining    = false.obs;
  var hasPaid     = false.obs;
  var isComplete  = false.obs;
  var balance     = 0.0.obs;
  var cycleProgress = 0.0.obs;
  var planProgress  = 0.0.obs;
  var remainingDays = planDays.obs;
  var totalEarned   = 0.0.obs;

  Timer? _timer;
  int _elapsedTicks = 0;

  void activatePlan() {
    hasPaid.value     = true;
    isComplete.value  = false;
    _elapsedTicks     = 0;
    balance.value     = 0;
    totalEarned.value = 0;
    planProgress.value  = 0;
    remainingDays.value = planDays;
  }

  void toggleMining() {
    if (!hasPaid.value || isComplete.value) return;
    isMining.value = !isMining.value;
    if (isMining.value) {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
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
        planProgress.value = _elapsedTicks / totalPlanTicks;
        remainingDays.value =
            (planDays - _elapsedTicks / 864000.0).ceil().clamp(0, planDays);
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
          // পার্টিকেল ব্যাকগ্রাউন্ড
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
            child: Obx(() => controller.hasPaid.value
                ? _buildMiningContent()
                : _buildActivationScreen()),
          ),
        ],
      ),
    );
  }

  // ============ অ্যাক্টিভেশন স্ক্রিন ($18 এন্ট্রি) ============
  Widget _buildActivationScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 430.h,
          borderRadius: 24.r,
          blur: 20,
          alignment: Alignment.center,
          border: 1,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentGold.withOpacity(0.08),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderGradient: LinearGradient(
            colors: [AppColors.accentGold.withOpacity(0.6), Colors.transparent],
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.rocket_fill,
                    color: AppColors.accentGold, size: 48.sp),
                SizedBox(height: 10.h),
                Text(
                  "MINING PLAN",
                  style: GoogleFonts.inter(
                    color: AppColors.accentGold,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  "একবার পেমেন্ট করো, ৩৬০ দিন মাইন করো",
                  style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 10.sp),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 22.h),
                _planRow("Entry Fee",        "\$18.00",              AppColors.accentGold),
                _divider(),
                _planRow("Duration",         "360 Days",             AppColors.accentGreen),
                _divider(),
                _planRow("Total Reward",     "\$100 (10,000 VXL)",   AppColors.accentPurple),
                _divider(),
                _planRow("Daily Earning",    "~27.78 VXL / day",     Colors.white70),
                _divider(),
                _planRow("Net Profit",       "\$82.00",              AppColors.accentGreen),
                SizedBox(height: 26.h),
                GestureDetector(
                  onTap: _showConfirmDialog,
                  child: Container(
                    width: double.infinity,
                    height: 52.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentGold, Color(0xFFFF8C00)],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGold.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "ACTIVATE FOR \$18",
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
      ),
    );
  }

  Widget _planRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 11.sp)),
          Text(value,
              style: GoogleFonts.inter(
                  color: color, fontSize: 12.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(color: Colors.white.withOpacity(0.05), height: 1);

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text("Confirm Payment",
            style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp)),
        content: Text(
          "\$18.00 পেমেন্ট করে ৩৬০-দিনের মাইনিং প্ল্যান অ্যাক্টিভ করবে?\nমোট পাবে: \$100 সমপরিমাণ VXL কয়েন।",
          style: GoogleFonts.inter(color: Colors.white60, fontSize: 12.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("বাতিল",
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12.sp)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.activatePlan();
            },
            child: Text("PAY \$18",
                style: GoogleFonts.inter(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }

  // ============ মেইন মাইনিং কনটেন্ট ============
  Widget _buildMiningContent() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Column(
        children: [
          SizedBox(height: 15.h),
          _buildBalanceSection(),
          SizedBox(height: 10.h),
          _buildPlanProgressSection(),
          const Spacer(),
          _buildMiningOrb(),
          const Spacer(),
          _buildCycleProgressBar(),
          SizedBox(height: 25.h),
          _buildActionButtons(),
          SizedBox(height: 12.h),
          _buildStatsGrid(),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildBalanceSection() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 95.h,
      borderRadius: 20.r,
      blur: 20,
      alignment: Alignment.center,
      border: 0.5,
      linearGradient: LinearGradient(
          colors: [AppColors.accentGreen.withOpacity(0.05),
                   Colors.white.withOpacity(0.02)]),
      borderGradient: LinearGradient(
          colors: [AppColors.accentGreen.withOpacity(0.2), Colors.transparent]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("MINED BALANCE",
              style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2)),
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(controller.balance.value.toStringAsFixed(4),
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 30.sp,
                      fontWeight: FontWeight.bold)),
              SizedBox(width: 5.w),
              Text("VXL",
                  style: GoogleFonts.inter(
                      color: AppColors.accentGreen,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800)),
            ],
          )),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  // ৩৬০ দিনের প্ল্যান প্রোগ্রেস
  Widget _buildPlanProgressSection() {
    return Obx(() {
      final prog    = controller.planProgress.value;
      final left    = controller.remainingDays.value;
      final earned  = controller.totalEarned.value;
      return GlassmorphicContainer(
        width: double.infinity,
        height: 76.h,
        borderRadius: 16.r,
        blur: 10,
        alignment: Alignment.center,
        border: 0.5,
        linearGradient: LinearGradient(
            colors: [AppColors.accentGold.withOpacity(0.06),
                     Colors.white.withOpacity(0.02)]),
        borderGradient: LinearGradient(
            colors: [AppColors.accentGold.withOpacity(0.35), Colors.transparent]),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("360-DAY PLAN  •  \$18 → \$100",
                      style: GoogleFonts.inter(
                          color: AppColors.accentGold,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8)),
                  Text("${earned.toStringAsFixed(1)} / 10,000 VXL",
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 9.sp)),
                ],
              ),
              SizedBox(height: 6.h),
              LinearPercentIndicator(
                lineHeight: 5.h,
                percent: prog.clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                linearGradient: const LinearGradient(
                    colors: [AppColors.accentGold, Color(0xFFFF8C00)]),
                barRadius: const Radius.circular(10),
                padding: EdgeInsets.zero,
              ),
              SizedBox(height: 5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${(prog * 100).toStringAsFixed(2)}% complete",
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

  Widget _buildMiningOrb() {
    return Obx(() {
      final active    = controller.isMining.value;
      final complete  = controller.isComplete.value;
      return GestureDetector(
        onTap: controller.toggleMining,
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
                Colors.black.withOpacity(0.3)
              ]),
              borderGradient: LinearGradient(
                colors: complete
                    ? [AppColors.accentGold, Colors.orange]
                    : active
                        ? [AppColors.accentGreen, AppColors.accentPurple]
                        : [Colors.white24, Colors.white10],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    complete
                        ? CupertinoIcons.checkmark_seal_fill
                        : active
                            ? CupertinoIcons.hammer_fill
                            : CupertinoIcons.bolt_fill,
                    color: complete
                        ? AppColors.accentGold
                        : active
                            ? AppColors.accentGreen
                            : Colors.white38,
                    size: 35.sp,
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    complete ? "COMPLETE" : active ? "MINING" : "START",
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900),
                  ),
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
                "CLAIM", CupertinoIcons.drop_fill, AppColors.accentGreen)),
        SizedBox(width: 12.w),
        Expanded(
            child: _smallButton(
                "BOOST", CupertinoIcons.rocket_fill, AppColors.accentPurple)),
      ],
    );
  }

  Widget _smallButton(String label, IconData icon, Color color) {
    return GlassmorphicContainer(
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
    );
  }

  Widget _buildStatsGrid() {
    return Obx(() => Row(
          children: [
            Expanded(
                child: _statBox("SPEED", "450 TH/S", AppColors.accentGreen)),
            SizedBox(width: 8.w),
            Expanded(child: _statBox("REFS", "12", Colors.orangeAccent)),
            SizedBox(width: 8.w),
            Expanded(
                child: _statBox("DAYS LEFT",
                    "${controller.remainingDays.value}", AppColors.accentGold)),
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
}

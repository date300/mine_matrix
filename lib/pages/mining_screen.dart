import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animated_background/animated_background.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppColors {
  static const Color background = Color(0xFF0D0D12);
  static const Color accentGreen = Color(0xFF14F195);
  static const Color accentPurple = Color(0xFF9945FF);
  static const Color glassWhite = Color(0xAAFFFFFF);
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
  // Flow
  var isMining = false.obs;
  var joined = false.obs;
  var joiningAmount = 0.0.obs;

  // Balances (demo): 1 coin == 1 USD for display
  var coinBalance = 0.0.obs; // earned coins
  var dollarValue = 0.0.obs; // dollar view

  // Mining timing
  var totalSeconds = 0.obs;
  var remainingSeconds = 0.obs;

  // Progress [0..1]
  var progress = 0.0.obs;

  Timer? _timer;

  // Mining target (demo)
  double _coinsTarget = 100.0;

  // Boost
  var boostAmount = 0.0.obs; // 1..50
  var boostDaysTotal = 0.obs;

  // Join/Pool (demo display)
  var directRefReward = 0.0.obs; // $5
  var globalPoolReward = 0.0.obs; // $5

  // Referral demo counters/reward
  var referralCount = 0.obs;
  var referralReward = 0.0.obs; // computed by level

  void _computeReferralReward() {
    final r = referralCount.value;
    double reward = 0.0;

    // Your level conditions (demo mapping):
    // Level 1: 10 referral -> $2
    // Level 2: 5 referral -> $1.5
    // Level 3: 1 referral -> $1.5
    if (r >= 10) {
      reward = 2.0;
    } else if (r >= 5) {
      reward = 1.5;
    } else if (r >= 1) {
      reward = 1.5;
    }
    referralReward.value = reward;
  }

  // Entry is fixed to $18 in your request
  void join18() {
    if (joined.value) return;

    joined.value = true;
    joiningAmount.value = 18.0;

    directRefReward.value = 5.0;
    globalPoolReward.value = 5.0;

    _setupMining(
      coinsTarget: 100.0, // 18$ -> 120 days -> 100$ coins (demo)
      daysTotal: 120,
      boostUsed: 0.0,
    );
  }

  void toggleMining() {
    if (!joined.value) return;

    if (isMining.value) {
      isMining.value = false;
      _timer?.cancel();
      _timer = null;
      return;
    }

    isMining.value = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds.value <= 0) {
        isMining.value = false;
        t.cancel();
        return;
      }

      remainingSeconds.value -= 1;

      final total = totalSeconds.value;
      final done = (total - remainingSeconds.value).clamp(0, total);
      progress.value = total == 0 ? 0.0 : done / total;

      // Earn coins linearly by progress
      coinBalance.value = (_coinsTarget * progress.value).clamp(0.0, _coinsTarget);
      dollarValue.value = coinBalance.value; // 1:1 demo display
    });
  }

  void claim() {
    if (!joined.value) return;
    // Demo: Claim pauses mining and keeps earned amount
    isMining.value = false;
    _timer?.cancel();
    _timer = null;
  }

  // Boost rules:
  // - boost range allowed 1..50
  // - 50$ -> 60 days -> 100 coins
  // - 1..50 => days linearly reduced (120 -> 60)
  void boost({required double amount}) {
    if (!joined.value) return;

    final b = amount.clamp(1.0, 50.0);

    final days = _daysTotalForBoost(b);
    final coinsTarget = _coinsTargetForBoost(b);

    _setupMining(
      coinsTarget: coinsTarget,
      daysTotal: days,
      boostUsed: b,
    );
  }

  double _coinsTargetForBoost(double boost) {
    // Your text: $50 boost gets 100 coins. Demo keeps target=100 for 1..50.
    return 100.0;
  }

  int _daysTotalForBoost(double boost) {
    // Linear mapping:
    // boost=1 -> 120 days
    // boost=50 -> 60 days
    final b = boost.clamp(1.0, 50.0);
    final t = (b - 1.0) / (50.0 - 1.0); // 0..1
    final days = 120.0 - t * 60.0; // 120..60
    return days.round().clamp(60, 120);
  }

  void _setupMining({
    required double coinsTarget,
    required int daysTotal,
    required double boostUsed,
  }) {
    _timer?.cancel();
    _timer = null;

    _coinsTarget = coinsTarget;

    coinBalance.value = 0.0;
    dollarValue.value = 0.0;
    progress.value = 0.0;

    boostAmount.value = boostUsed;
    boostDaysTotal.value = boostUsed <= 0.0 ? 120 : daysTotal;

    totalSeconds.value = daysTotal * 24 * 60 * 60;
    remainingSeconds.value = totalSeconds.value;

    // Auto-start after join/boost (demo)
    isMining.value = true;
    toggleMining();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

class MiningScreen extends StatefulWidget {
  const MiningScreen({super.key});
  @override
  State<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen> with TickerProviderStateMixin {
  final MiningController controller = Get.put(MiningController());
  final TextEditingController _refInput = TextEditingController(text: "10");

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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Column(
                children: [
                  SizedBox(height: 15.h),
                  _buildBalanceSection(),
                  SizedBox(height: 14.h),
                  _buildJoinSection(),
                  const Spacer(),
                  _buildMiningOrb(),
                  SizedBox(height: 12.h),
                  _buildProgressBar(),
                  SizedBox(height: 12.h),
                  _buildMineStatsRow(),
                  SizedBox(height: 16.h),
                  _buildActionButtons(),
                  SizedBox(height: 12.h),
                  _buildBoostSheet(),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 130.h,
      borderRadius: 20.r,
      blur: 20,
      alignment: Alignment.center,
      border: 0.5,
      linearGradient: LinearGradient(
        colors: [
          AppColors.accentGreen.withOpacity(0.05),
          Colors.white.withOpacity(0.02),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [AppColors.accentGreen.withOpacity(0.2), Colors.transparent],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "MINED",
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.coinBalance.value.toStringAsFixed(2),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  "COIN",
                  style: GoogleFonts.inter(
                    color: AppColors.accentGreen,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),
          Obx(
            () => Text(
              "≈ ${controller.dollarValue.value.toStringAsFixed(2)} USD",
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildJoinSection() {
    return Obx(() {
      if (controller.joined.value) {
        return Column(
          children: [
            _smallInfoRow(
              "JOINED WITH",
              "\$${controller.joiningAmount.value.toStringAsFixed(0)}",
              AppColors.accentGreen,
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _smallInfoRow(
                    "DIRECT REF",
                    "\$${controller.directRefReward.value.toStringAsFixed(0)}",
                    Colors.white38,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _smallInfoRow(
                    "GLOBAL POOL",
                    "\$${controller.globalPoolReward.value.toStringAsFixed(0)}",
                    Colors.white38,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _buildReferralDemo(),
          ],
        );
      }

      return GlassmorphicContainer(
        width: double.infinity,
        height: 90.h,
        borderRadius: 20.r,
        blur: 20,
        alignment: Alignment.center,
        border: 0.5,
        linearGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.transparent,
          ],
        ),
        borderGradient: LinearGradient(
          colors: [AppColors.accentPurple.withOpacity(0.25), Colors.transparent],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "JOIN ENTRY",
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "\$18",
                  style: GoogleFonts.inter(
                    color: AppColors.accentGreen,
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  "FREE MINING (120 DAYS)",
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            _primaryButton(
              label: "JOIN NOW",
              icon: CupertinoIcons.add_circled_solid,
              onTap: controller.join18,
              color: AppColors.accentGreen,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildReferralDemo() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 74.h,
      borderRadius: 18.r,
      blur: 15,
      alignment: Alignment.center,
      border: 0.5,
      linearGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.03),
          Colors.transparent,
        ],
      ),
      borderGradient: LinearGradient(
        colors: [AppColors.accentGreen.withOpacity(0.18), Colors.transparent],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _refInput,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: "ref count (demo)",
                  hintStyle: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.03),
                ),
                onChanged: (v) {
                  final n = int.tryParse(v.trim()) ?? 0;
                  controller.referralCount.value = n;
                  controller._computeReferralReward();
                },
              ),
            ),
            SizedBox(width: 10.w),
            Obx(
              () => _smallTag(
                "LEVEL REWARD",
                "\$${controller.referralReward.value.toStringAsFixed(1)}",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallTag(String t, String v) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t,
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            v,
            style: GoogleFonts.inter(
              color: AppColors.accentGreen,
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallInfoRow(String title, String value, Color valueColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            value,
            style: GoogleFonts.inter(
              color: valueColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.65)],
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 18.sp),
            SizedBox(width: 10.w),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiningOrb() {
    return Obx(() {
      bool active = controller.isMining.value;
      return GestureDetector(
        onTap: controller.joined.value ? controller.toggleMining : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (active)
              Container(
                width: 160.w,
                height: 160.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accentGreen.withOpacity(0.5), width: 2),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(duration: const Duration(seconds: 3))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), curve: Curves.easeInOutSine)
                  .then()
                  .scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1)),
            GlassmorphicContainer(
              width: 140.w,
              height: 140.w,
              borderRadius: 70.w,
              blur: 15,
              alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.3)],
              ),
              borderGradient: LinearGradient(
                colors: active ? [AppColors.accentGreen, AppColors.accentPurple] : [Colors.white24, Colors.white10],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    active ? CupertinoIcons.hammer_fill : CupertinoIcons.bolt_fill,
                    color: active ? AppColors.accentGreen : Colors.white38,
                    size: 35.sp,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    !controller.joined.value ? "JOIN FIRST" : (active ? "MINING" : "START"),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            )
                .animate(target: active ? 1 : 0)
                .shimmer(duration: const Duration(milliseconds: 1500), color: Colors.white24),
          ],
        ),
      );
    });
  }

  Widget _buildProgressBar() {
    return Obx(() {
      final p = controller.progress.value.clamp(0.0, 1.0);
      final rem = controller.remainingSeconds.value;
      final total = controller.totalSeconds.value;

      String fmt(int s) {
        final dd = s ~/ (24 * 60 * 60);
        final hh = (s % (24 * 60 * 60)) ~/ (60 * 60);
        return "${dd}d ${hh}h";
      }

      return Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: LinearPercentIndicator(
              lineHeight: 8.h,
              percent: p,
              backgroundColor: Colors.white10,
              linearGradient: const LinearGradient(colors: [AppColors.accentPurple, AppColors.accentGreen]),
              barRadius: const Radius.circular(10),
              padding: EdgeInsets.zero,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${(p * 100).toStringAsFixed(1)}%",
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "Remaining: ${fmt(rem)}",
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "Total: ${total == 0 ? "-" : fmt(total)}",
                style: GoogleFonts.inter(
                  color: Colors.white30,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildMineStatsRow() {
    return Obx(() {
      final isJoined = controller.joined.value;
      final active = controller.isMining.value;

      final boostTxt = controller.boostAmount.value <= 0.0
          ? "None"
          : "\$${controller.boostAmount.value.toStringAsFixed(0)}";

      return Row(
        children: [
          Expanded(
            child: _statBox(
              "STATUS",
              !isJoined ? "NOT JOINED" : (active ? "RUNNING" : "PAUSED"),
              AppColors.accentGreen,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _statBox(
              "BOOST",
              boostTxt,
              AppColors.accentPurple,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 250.ms);
    });
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _glassButton(
            label: "CLAIM",
            icon: CupertinoIcons.check_mark_circled_solid,
            color: AppColors.accentGreen,
            onTap: controller.joined.value ? controller.claim : null,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _glassButton(
            label: "BOOST",
            icon: CupertinoIcons.rocket_fill,
            color: AppColors.accentPurple,
            onTap: controller.joined.value ? _showBoostDialog : null,
          ),
        ),
      ],
    );
  }

  Widget _glassButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: GlassmorphicContainer(
        height: 60.h,
        borderRadius: 16.r,
        blur: 10,
        alignment: Alignment.center,
        border: 0.5,
        linearGradient: LinearGradient(colors: [Colors.white.withOpacity(0.05), Colors.transparent]),
        borderGradient: LinearGradient(colors: [Colors.white24, Colors.transparent]),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                label,
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
    );
  }

  Widget _buildBoostSheet() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "DEMO RULES",
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            "• \$18 join = 120 দিনে 100 Coins\n• Boost: \$1..\$50 (50 এর বেশি নয়)\n• \$50 boost = 60 দিনে 100 Coins\n• 1..50 হলে দিন ধীরে কমবে (ডেমো লিনিয়ার)",
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBoostDialog() async {
    double temp = 50.0;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF12121A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            "BOOST AMOUNT (1..50)",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "\$${temp.toStringAsFixed(0)}",
                    style: GoogleFonts.inter(
                      color: AppColors.accentPurple,
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Slider(
                    value: temp,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: AppColors.accentPurple,
                    inactiveColor: Colors.white24,
                    onChanged: (v) => setState(() => temp = v),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    "50 এর বেশি দেয়া যাবে না (ডেমো ক্ল্যাম্প করা হবে)।",
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                "CANCEL",
                style: GoogleFonts.inter(color: Colors.white54, fontWeight: FontWeight.w900),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              onPressed: () {
                controller.boost(amount: temp);
                Navigator.of(ctx).pop();
              },
              child: Text(
                "BOOST",
                style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _refInput.dispose();
    Get.delete<MiningController>();
    super.dispose();
  }
}

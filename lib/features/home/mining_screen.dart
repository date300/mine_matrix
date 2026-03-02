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

void main() {
  runApp(const VexylonApp());
}

class VexylonApp extends StatelessWidget {
  const VexylonApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ScreenUtil ইনিশিয়ালাইজেশন (রেস্পন্সিভ ডিজাইনের জন্য)
    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 13/14 Pro সাইজ
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Vexylon Pro',
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF0D0D12),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          home: const MiningScreen(),
        );
      },
    );
  }
}

// ---------------------------------------------------------
// GETX CONTROLLER (লজিক অংশ)
// ---------------------------------------------------------
class MiningController extends GetxController {
  var isMining = false.obs;
  var balance = 4520.5000.obs;
  var progress = 0.0.obs;
  
  Timer? _miningTimer;

  void toggleMining() {
    isMining.value = !isMining.value;
    if (isMining.value) {
      _startMiningTimer();
    } else {
      _miningTimer?.cancel();
    }
  }

  void _startMiningTimer() {
    _miningTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      balance.value += 0.0005;
      progress.value += 0.002;
      if (progress.value >= 1.0) {
        progress.value = 0.0;
      }
    });
  }

  @override
  void onClose() {
    _miningTimer?.cancel();
    super.onClose();
  }
}

// ---------------------------------------------------------
// UI SCREEN (ডিজাইন অংশ)
// ---------------------------------------------------------
class MiningScreen extends StatefulWidget {
  const MiningScreen({super.key});

  @override
  State<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen> with TickerProviderStateMixin {
  // GetX কন্ট্রোলার ইনজেক্ট করা হলো
  final MiningController controller = Get.put(MiningController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ডাইনামিক ব্যাকগ্রাউন্ড (Animated Background)
          AnimatedBackground(
            vsync: this,
            behaviour: RandomParticleBehaviour(
              options: ParticleOptions(
                baseColor: const Color(0xFF14F195).withOpacity(0.2),
                spawnOpacity: 0.1,
                opacityChangeRate: 0.25,
                minOpacity: 0.1,
                maxOpacity: 0.3,
                particleCount: 20,
                spawnMaxRadius: 15,
                spawnMinRadius: 5,
                spawnMaxSpeed: 20,
                spawnMinSpeed: 10,
              ),
            ),
            child: Container(),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  _buildHeader().animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
                  SizedBox(height: 30.h),
                  _buildBalanceSection().animate().fadeIn(delay: 200.ms).scale(),
                  SizedBox(height: 40.h),
                  _buildMiningOrb().animate().fadeIn(delay: 400.ms).scale(),
                  SizedBox(height: 30.h),
                  _buildProgressBar().animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                  SizedBox(height: 40.h),
                  _buildActionButtons().animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                  SizedBox(height: 15.h),
                  _buildStatsGrid().animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
                  SizedBox(height: 50.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // হেডার সেকশন
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "HELLO, MINER!",
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            Text(
              "VEXYLON PRO",
              style: GoogleFonts.sfProDisplay(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        GlassmorphicContainer(
          width: 45.w,
          height: 45.w,
          borderRadius: 15.r,
          blur: 15,
          alignment: Alignment.center,
          border: 1,
          linearGradient: LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]),
          borderGradient: LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.0)]),
          child: Icon(CupertinoIcons.bell_fill, color: const Color(0xFF14F195), size: 22.sp),
        ),
      ],
    );
  }

  // ব্যালেন্স সেকশন (Glassmorphism + GetX Reactive)
  Widget _buildBalanceSection() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 140.h,
      borderRadius: 24.r,
      blur: 20,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFF14F195).withOpacity(0.1), Colors.white.withOpacity(0.02)],
      ),
      borderGradient: LinearGradient(colors: [const Color(0xFF14F195).withOpacity(0.3), Colors.white.withOpacity(0.0)]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("CURRENT MINED BALANCE", style: GoogleFonts.inter(color: Colors.white54, fontSize: 11.sp, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          SizedBox(height: 10.h),
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    controller.balance.value.toStringAsFixed(4),
                    style: GoogleFonts.sfProDisplay(color: Colors.white, fontSize: 40.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8.w),
                  Text("VXL", style: GoogleFonts.inter(color: const Color(0xFF14F195), fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ],
              )),
        ],
      ),
    );
  }

  // মাইনিং অর্ব (অ্যানিমেটেড বাটন)
  Widget _buildMiningOrb() {
    return GestureDetector(
      onTap: controller.toggleMining,
      child: Obx(() {
        bool isMining = controller.isMining.value;
        return Container(
          width: 180.w,
          height: 180.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: isMining
                ? [BoxShadow(color: const Color(0xFF14F195).withOpacity(0.3), blurRadius: 40, spreadRadius: 10)]
                : [],
          ),
          child: GlassmorphicContainer(
            width: 180.w,
            height: 180.w,
            borderRadius: 90.w,
            blur: 15,
            alignment: Alignment.center,
            border: isMining ? 2 : 1,
            linearGradient: LinearGradient(colors: [Colors.black.withOpacity(0.5), Colors.black.withOpacity(0.2)]),
            borderGradient: LinearGradient(
              colors: isMining 
                ? [const Color(0xFF14F195), const Color(0xFF9945FF)] 
                : [Colors.white24, Colors.white10]
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // এখানে Lottie অ্যানিমেশন যোগ করতে পারেন 
                Icon(
                  isMining ? CupertinoIcons.hammer_fill : CupertinoIcons.bolt_slash_fill,
                  color: isMining ? const Color(0xFF14F195) : Colors.grey,
                  size: 40.sp,
                ).animate(target: isMining ? 1 : 0).shimmer(duration: 1000.ms, color: Colors.white),
                SizedBox(height: 8.h),
                Text(
                  isMining ? "MINING..." : "TAP TO START",
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // প্রোগ্রেস বার (Percent Indicator)
  Widget _buildProgressBar() {
    return Obx(() {
      return LinearPercentIndicator(
        lineHeight: 8.h,
        percent: controller.progress.value,
        backgroundColor: Colors.white.withOpacity(0.1),
        linearGradient: const LinearGradient(colors: [Color(0xFF9945FF), Color(0xFF14F195)]),
        barRadius: const Radius.circular(10),
        animation: false, // GetX থেকে রিয়েলটাইম আপডেট হচ্ছে
      );
    });
  }

  // অ্যাকশন বাটনস
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(child: _glassButton("CLAIM", CupertinoIcons.arrow_down_circle_fill, const Color(0xFF14F195))),
        SizedBox(width: 15.w),
        Expanded(child: _glassButton("BOOST", CupertinoIcons.bolt_circle_fill, const Color(0xFF9945FF))),
      ],
    );
  }

  Widget _glassButton(String label, IconData icon, Color color) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 80.h,
      borderRadius: 20.r,
      blur: 15,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.01)]),
      borderGradient: LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.transparent]),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28.sp),
            SizedBox(height: 6.h),
            Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // স্ট্যাটাস গ্রিড
  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: Obx(() => _statCard("HASHRATE", controller.isMining.value ? "450 TH/S" : "0 TH/S", CupertinoIcons.gauge, const Color(0xFF14F195)))),
        SizedBox(width: 15.w),
        Expanded(child: _statCard("REFERRALS", "12 USERS", CupertinoIcons.person_2_fill, Colors.orangeAccent)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 90.h,
      borderRadius: 20.r,
      blur: 10,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      border: 1,
      linearGradient: LinearGradient(colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.01)]),
      borderGradient: LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.transparent]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18.sp),
              SizedBox(width: 6.w),
              Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 10.h),
          Text(value, style: GoogleFonts.sfProDisplay(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

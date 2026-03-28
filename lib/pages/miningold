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

// কালার প্যালেট
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

// কন্ট্রোলার লজিক
class MiningController extends GetxController {
  var isMining = false.obs;
  var balance = 4520.5000.obs;
  var progress = 0.0.obs;
  Timer? _timer;

  void toggleMining() {
    isMining.value = !isMining.value;
    if (isMining.value) {
      // ফিক্স: ১০০.ms এর বদলে সরাসরি Duration ব্যবহার
      _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        balance.value += 0.0005;
        progress.value = (progress.value + 0.002) % 1.0;
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

class MiningScreen extends StatefulWidget {
  const MiningScreen({super.key});
  @override
  State<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen> with TickerProviderStateMixin {
  final MiningController controller = Get.put(MiningController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ব্যাকগ্রাউন্ড এনিমেশন
          AnimatedBackground(
            vsync: this,
            behaviour: RandomParticleBehaviour(
              options: const ParticleOptions(
                baseColor: AppColors.accentGreen, 
                spawnOpacity: 0.1, 
                particleCount: 15
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
                  const Spacer(),
                  _buildMiningOrb(),
                  const Spacer(),
                  _buildProgressBar(),
                  SizedBox(height: 25.h),
                  _buildActionButtons(),
                  SizedBox(height: 12.h),
                  _buildStatsGrid(),
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
      height: 100.h,
      borderRadius: 20.r,
      blur: 20,
      alignment: Alignment.center,
      border: 0.5,
      linearGradient: LinearGradient(
        colors: [AppColors.accentGreen.withOpacity(0.05), Colors.white.withOpacity(0.02)]
      ),
      borderGradient: LinearGradient(
        colors: [AppColors.accentGreen.withOpacity(0.2), Colors.transparent]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("MINED BALANCE", 
            style: GoogleFonts.inter(
              color: Colors.white54, 
              fontSize: 10.sp, 
              fontWeight: FontWeight.w600, 
              letterSpacing: 1.2
            )
          ),
          Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(controller.balance.value.toStringAsFixed(4), 
                style: GoogleFonts.inter(
                  color: Colors.white, 
                  fontSize: 32.sp, 
                  fontWeight: FontWeight.bold
                )
              ),
              SizedBox(width: 5.w),
              Text("VXL", 
                style: GoogleFonts.inter(
                  color: AppColors.accentGreen, 
                  fontSize: 14.sp, 
                  fontWeight: FontWeight.w800
                )
              ),
            ],
          )),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildMiningOrb() {
    return Obx(() {
      bool active = controller.isMining.value;
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
                  border: Border.all(color: AppColors.accentGreen.withOpacity(0.5), width: 2),
                ),
              ).animate(onPlay: (c) => c.repeat())
               .rotate(duration: const Duration(seconds: 3)) // ফিক্স: কনফ্লিক্ট দূর করা হয়েছে
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
                colors: [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.3)]
              ),
              borderGradient: LinearGradient(
                colors: active ? [AppColors.accentGreen, AppColors.accentPurple] : [Colors.white24, Colors.white10]
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(active ? CupertinoIcons.hammer_fill : CupertinoIcons.bolt_fill, 
                    color: active ? AppColors.accentGreen : Colors.white38, 
                    size: 35.sp
                  ),
                  SizedBox(height: 5.h),
                  Text(active ? "MINING" : "START", 
                    style: GoogleFonts.inter(
                      color: Colors.white, 
                      fontSize: 12.sp, 
                      fontWeight: FontWeight.w900
                    )
                  ),
                ],
              ),
            ).animate(target: active ? 1 : 0)
             .shimmer(duration: const Duration(milliseconds: 1500), color: Colors.white24), // ফিক্স
          ],
        ),
      );
    });
  }

  Widget _buildProgressBar() {
    return Obx(() => LinearPercentIndicator(
      lineHeight: 6.h,
      percent: controller.progress.value,
      backgroundColor: Colors.white10,
      linearGradient: const LinearGradient(colors: [AppColors.accentPurple, AppColors.accentGreen]),
      barRadius: const Radius.circular(10),
      padding: EdgeInsets.zero,
    ));
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(child: _smallButton("CLAIM", CupertinoIcons.drop_fill, AppColors.accentGreen)),
        SizedBox(width: 12.w),
        Expanded(child: _smallButton("BOOST", CupertinoIcons.rocket_fill, AppColors.accentPurple)),
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
      linearGradient: LinearGradient(colors: [Colors.white.withOpacity(0.05), Colors.transparent]),
      borderGradient: LinearGradient(colors: [Colors.white24, Colors.transparent]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(width: 8.w),
          Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _statBox("SPEED", "450 TH/S", AppColors.accentGreen)),
        SizedBox(width: 12.w),
        Expanded(child: _statBox("REFS", "12", Colors.orangeAccent)),
      ],
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(15.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp, fontWeight: FontWeight.bold)),
          Text(value, style: GoogleFonts.inter(color: color, fontSize: 16.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

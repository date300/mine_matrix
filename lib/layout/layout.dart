import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animated_background/animated_background.dart';

// আপনার প্রোজেক্টের পাথ অনুযায়ী ইম্পোর্টগুলো চেক করে নিন
import 'topbar.dart';
import 'nevbar.dart';
import '../pages/home_screen.dart';
import '../pages/mining_screen.dart';
import '../pages/wallet_screen.dart';

// গ্লোবাল কালার এবং স্টাইল
class AppColors {
  static const Color background = Color(0xFF0D0D12);
  static const Color accentGreen = Color(0xFF14F195);
  static const Color accentPurple = Color(0xFF9945FF);
}

class AppLayoutController extends GetxController {
  var selectedIndex = 1.obs; // ডিফল্ট মাইনিং স্ক্রিন
}

class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> with TickerProviderStateMixin {
  final controller = Get.put(AppLayoutController());

  final List<Widget> pages = [
    const HomeScreen(),
    const MiningScreen(),
    const WalletScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          // এটিই আপনার মাইনিং পেজের সেই নির্দিষ্ট এনিমেশন ব্যাকগ্রাউন্ড
          AnimatedBackground(
            vsync: this,
            behaviour: RandomParticleBehaviour(
              options: ParticleOptions(
                baseColor: AppColors.accentGreen.withOpacity(0.2),
                spawnOpacity: 0.1,
                opacityChangeRate: 0.25, // এনিমেশনের গতির স্টাইল
                minOpacity: 0.1,
                maxOpacity: 0.3,
                particleCount: 20, // পার্টিকেলের সঠিক সংখ্যা
              ),
            ),
            child: const SizedBox.expand(),
          ),

          // মেইন কন্টেন্ট লেয়ার
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const TopBar(),
                Expanded(
                  child: Obx(() => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: pages[controller.selectedIndex.value],
                  )),
                ),
              ],
            ),
          ),
        ],
      ),

      // নেভিগেশন বার
      bottomNavigationBar: Obx(() => FloatingBottomNav(
        currentIndex: controller.selectedIndex.value,
        onTap: (index) => controller.selectedIndex.value = index,
      )),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animated_background/animated_background.dart';

import 'topbar.dart';
import 'nevbar.dart';
import '../pages/home_screen.dart';
import '../pages/mining_screen.dart';
import '../pages/wallet_screen.dart';

class AppColors {
  static const Color blue = Color(0xFF2196F3);
  static const Color accentGreen = Color(0xFF14F195);
  static const Color accentPurple = Color(0xFF9945FF);
  static const Color glassWhite = Color(0xAAFFFFFF);
  static const Color background = Color(0xFF0D0D12);
}

class AppLayoutController extends GetxController {
  var selectedIndex = 1.obs;
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
      backgroundColor: AppColors.background, // বেস ডার্ক কালার
      extendBody: true,
      body: Stack(
        children: [
          // মাইনিং পেজের হুবহু এনিমেটেড ব্যাকগ্রাউন্ড
          AnimatedBackground(
            vsync: this,
            behaviour: RandomParticleBehaviour(
              options: ParticleOptions(
                baseColor: AppColors.accentGreen.withOpacity(0.2),
                spawnOpacity: 0.1,
                opacityChangeRate: 0.25, // এটি এনিমেশনকে স্মুথ করবে
                minOpacity: 0.1,
                maxOpacity: 0.3,
                particleCount: 20, // মাইনিং স্ক্রিনের মতো সংখ্যা
              ),
            ),
            child: const SizedBox.expand(),
          ),

          // মেইন কন্টেন্ট
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const TopBar(),
                Expanded(
                  child: Obx(() => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    // পেজ পরিবর্তনের সময় ফেইড এনিমেশন
                    child: pages[controller.selectedIndex.value],
                  )),
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: Obx(() => FloatingBottomNav(
        currentIndex: controller.selectedIndex.value,
        onTap: (index) => controller.selectedIndex.value = index,
      )),
    );
  }
}

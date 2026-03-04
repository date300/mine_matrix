import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animated_background/animated_background.dart';
import 'topbar.dart';
import 'nevbar.dart';
import '../pages/home_screen.dart';
import '../pages/mining_screen.dart';
import '../pages/wallet_screen.dart';

class AppColors {
  static const Color background = Color(0xFF0D0D12);
  static const Color accentGreen = Color(0xFF14F195);
  static const Color accentPurple = Color(0xFF9945FF);
  static const Color blue = Color(0xFF2196F3);
  static const Color glassWhite = Color(0xAAFFFFFF);
}

class AppLayoutController extends GetxController {
  var selectedIndex = 1.obs; // ডিফল্টভাবে মাইনিং পেজ (১) সিলেক্ট করা
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
      extendBody: true, // নিচের নেভিবারকে স্বচ্ছ করতে
      
      body: Stack(
        children: [
          // ১. ব্যাকগ্রাউন্ড এনিমেশন (সবার নিচে থাকবে এবং সব পেজে দেখাবে)
          AnimatedBackground(
            vsync: this,
            behaviour: RandomParticleBehaviour(
              options: const ParticleOptions(
                baseColor: AppColors.accentGreen,
                spawnOpacity: 0.1,
                opacityChangeRate: 0.25,
                minOpacity: 0.1,
                maxOpacity: 0.3,
                particleCount: 25,
              ),
            ),
            child: const SizedBox.expand(),
          ),

          // ২. টপবার এবং পেজ কন্টেন্ট
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ফিক্সড টপবার
                const TopBar(),
                
                // পেজ কন্টেন্ট
                Expanded(
                  child: Obx(() => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: pages[controller.selectedIndex.value],
                  )),
                ),
              ],
            ),
          ),
        ],
      ),

      // ট্রান্সপারেন্ট নেভিগেশন বার
      bottomNavigationBar: Obx(() => FloatingBottomNav(
        currentIndex: controller.selectedIndex.value,
        onTap: (index) => controller.selectedIndex.value = index,
      )),
    );
  }
}

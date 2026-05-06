import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animated_background/animated_background.dart';
import 'topbar.dart';
import 'nevbar.dart';
import '../pages/home/home_screen.dart';
import '../pages/mining/mining_screen.dart';
import '../pages/wallet/wallet_screen.dart';
import '../pages/refer/refer_screen.dart';
import '../pages/withdraw/Withdraw_scren.dart';

class AppColors {
  static const Color background = Color(0xFF0D0D12);
  static const Color accentGreen = Color(0xFF14F195);
  static const Color accentPurple = Color(0xFF9945FF);
  static const Color blue = Color(0xFF2196F3);
  static const Color glassWhite = Color(0xAAFFFFFF);
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
    const HomeScreen(),      // Index 0
    const MiningScreen(),    // Index 1
    const ReferScreen(),     // Index 2
    const WalletScreen(),    // Index 3
    const WithdrawScreen(),  // Index 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
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
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const TopBar(),
                Expanded(
                  child: Obx(() => IndexedStack(
                    index: controller.selectedIndex.value,
                    children: pages,
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

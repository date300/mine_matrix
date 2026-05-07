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

// ✅ Breakpoint Helper
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;
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
    const ReferScreen(),
    const WalletScreen(),
    const WithdrawScreen(),
  ];

  // ✅ Desktop এর জন্য Navigation Rail Labels
  final List<NavigationRailDestination> _railDestinations = const [
    NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
    NavigationRailDestination(icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt), label: Text('Mining')),
    NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Refer')),
    NavigationRailDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: Text('Wallet')),
    NavigationRailDestination(icon: Icon(Icons.arrow_circle_up_outlined), selectedIcon: Icon(Icons.arrow_circle_up), label: Text('Withdraw')),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
        final isMobile = constraints.maxWidth < 600;

        return Scaffold(
          backgroundColor: AppColors.background,
          extendBody: !isDesktop, // Desktop এ extendBody বন্ধ
          body: Stack(
            children: [
              // ✅ Animated Background সব ডিভাইসে
              AnimatedBackground(
                vsync: this,
                behaviour: RandomParticleBehaviour(
                  options: ParticleOptions(
                    baseColor: AppColors.accentGreen,
                    spawnOpacity: 0.1,
                    opacityChangeRate: 0.25,
                    minOpacity: 0.1,
                    maxOpacity: 0.3,
                    // Desktop এ বেশি particle, Mobile এ কম
                    particleCount: isDesktop ? 50 : isTablet ? 35 : 25,
                  ),
                ),
                child: const SizedBox.expand(),
              ),

              // ✅ Desktop Layout — Side Navigation Rail
              if (isDesktop)
                SafeArea(
                  child: Row(
                    children: [
                      // Left Side Navigation Rail
                      Obx(() => NavigationRail(
                        backgroundColor: Colors.transparent,
                        selectedIndex: controller.selectedIndex.value,
                        onDestinationSelected: (index) =>
                            controller.selectedIndex.value = index,
                        extended: constraints.maxWidth >= 1400, // খুব বড় স্ক্রিনে label দেখাবে
                        selectedIconTheme: const IconThemeData(color: AppColors.accentGreen),
                        selectedLabelTextStyle: const TextStyle(color: AppColors.accentGreen),
                        unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.5)),
                        destinations: _railDestinations,
                      )),
                      const VerticalDivider(width: 1, color: Colors.white12),
                      // Main Content Area
                      Expanded(
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
                ),

              // ✅ Tablet Layout — TopBar + Bottom Nav (wider)
              if (isTablet)
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

              // ✅ Mobile Layout — আগের মতোই
              if (isMobile)
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

          // ✅ Desktop এ Bottom Nav দেখাবে না
          bottomNavigationBar: isDesktop
              ? null
              : Obx(() => FloatingBottomNav(
                    currentIndex: controller.selectedIndex.value,
                    onTap: (index) => controller.selectedIndex.value = index,
                  )),
        );
      },
    );
  }
}

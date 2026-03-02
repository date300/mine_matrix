import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animated_background/animated_background.dart';

// সঠিক পাথ অনুযায়ী ইম্পোর্টগুলো
import 'topbar.dart';
import 'nevbar.dart';
import '../pages/home_screen.dart';
import '../pages/mining_screen.dart';
import '../pages/wallet_screen.dart';

// --- আপডেট করা AppColors ক্লাস (সবগুলো মিসিং কালার এখানে যোগ করা হয়েছে) ---
class AppColors {
  static const Color blue = Color(0xFF2196F3); 
  static const Color accentGreen = Color(0xFF14F195); // এটি মিসিং ছিল
  static const Color accentPurple = Color(0xFF9945FF); // এটিও যোগ করা হলো
  static const Color glassWhite = Color(0xAAFFFFFF); 
  static const Color background = Color(0xFF0D0D12);
}

// পেজ ইনডেক্স কন্ট্রোল করার জন্য GetX Controller
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

  // স্ক্রিন লিস্ট
  final List<Widget> pages = [
    const HomeScreen(),
    const MiningScreen(),
    const WalletScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // গ্লোবাল এনিমেটেড ব্যাকগ্রাউন্ড
          AnimatedBackground(
            vsync: this,
            behaviour: RandomParticleBehaviour(
              options: ParticleOptions(
                baseColor: AppColors.accentGreen.withOpacity(0.2),
                spawnOpacity: 0.1,
                particleCount: 25,
              ),
            ),
            child: Container(),
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
                    child: pages[controller.selectedIndex.value],
                  )),
                ),
              ],
            ),
          ),
        ],
      ),

      // কাস্টম নেভিগেশন বার (FloatingBottomNav আপনার nevbar.dart এ ডিফাইন করা আছে)
      bottomNavigationBar: Obx(() => FloatingBottomNav(
        currentIndex: controller.selectedIndex.value,
        onTap: (index) => controller.selectedIndex.value = index,
      )),
    );
  }
}

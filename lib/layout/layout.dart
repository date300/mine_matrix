import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animated_background/animated_background.dart';

// সঠিক পাথ অনুযায়ী ইম্পোর্টগুলো ঠিক করা হলো
import 'topbar.dart';
import 'nevbar.dart'; // আপনার ফাইলের নাম 'nevbar.dart' ছিল, তাই সেটিই দেওয়া হলো
import '../pages/home_screen.dart';
import '../pages/mining_screen.dart';
import '../pages/wallet_screen.dart';

// পেজ ইনডেক্স কন্ট্রোল করার জন্য GetX Controller
class AppLayoutController extends GetxController {
  var selectedIndex = 1.obs; // ডিফল্ট মাইニング স্ক্রিন
}

class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> with TickerProviderStateMixin {
  final controller = Get.put(AppLayoutController());

  // স্ক্রিন লিস্ট - এখানে আপনার পেজগুলো কানেক্ট করা হলো
  final List<Widget> pages = [
    const HomeScreen(),   // pages/home_screen.dart থেকে
    const MiningScreen(), // pages/mining_screen.dart থেকে
    const WalletScreen(), // pages/wallet_screen.dart থেকে
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
                baseColor: const Color(0xFF14F195).withOpacity(0.2),
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
                const TopBar(), // layout/topbar.dart থেকে
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

      // কাস্টম নেভিগেশন বার (আপনার nevbar.dart এ FloatingBottomNav থাকতে হবে)
      bottomNavigationBar: Obx(() => FloatingBottomNav(
        currentIndex: controller.selectedIndex.value,
        onTap: (index) => controller.selectedIndex.value = index,
      )),
    );
  }
}

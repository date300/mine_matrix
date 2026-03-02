import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animated_background/animated_background.dart';
import 'topbar.dart';
import 'navbar.dart';

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

  // স্ক্রিন লিস্ট (এখানে তোমার মাইনিং স্ক্রিন ও অন্য পেজগুলো দাও)
  final List<Widget> pages = [
    const Center(child: Text("HOME PAGE", style: TextStyle(color: Colors.white))),
    const MiningScreen(), // তোমার আগের মাইনিং স্ক্রিনটি এখানে দাও
    const Center(child: Text("WALLET PAGE", style: TextStyle(color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // নেভিগেশন বারের নিচ দিয়ে ব্যাকগ্রাউন্ড দেখার জন্য
      body: Stack(
        children: [
          // গ্লোবাল এনিমেটেড ব্যাকগ্রাউন্ড (সব পেজের জন্য এক)
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
                const TopBar(), // টপ বার
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
      
      // কাস্টম নেভিগেশন বার
      bottomNavigationBar: Obx(() => FloatingBottomNav(
        currentIndex: controller.selectedIndex.value,
        onTap: (index) => controller.selectedIndex.value = index,
      )),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../../core/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              _buildTopBar(),
              const SizedBox(height: 25),
              _buildMiningHero(),
              const SizedBox(height: 30),
              
              // সেকশন: একাউন্ট ওভারভিউ
              const Text("আপনার একাউন্ট ওভারভিউ", 
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildTripleWallet(),
              
              const SizedBox(height: 35),
              // সেকশন: গ্লোবাল ম্যাট্রিক্স (PDF লজিক অনুযায়ী)
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("গ্লোবাল ইনকাম ট্র্যাকার", 
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Icon(CupertinoIcons.info_circle, color: Colors.white38, size: 20),
                ],
              ),
              const Text("সিস্টেমে প্রতি জয়েনিং থেকে \$৫ এই পুলে জমা হয়", 
                style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 15),
              _buildMatrixStatus(),
              
              const SizedBox(height: 35),
              // সেকশন: ডিস্ট্রিবিউশন লজিক (\$১৮ ব্যাখ্যা)
              const Text("ফান্ড ডিস্ট্রিবিউশন লজিক (\$১৮)", 
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildDistributionInfo(),
              
              const SizedBox(height: 30),
              _buildActionGrid(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  // ১. প্রিমিয়াম হেডার
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white12,
              child: Icon(CupertinoIcons.person_alt_circle, color: Colors.white.withOpacity(0.8), size: 30),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("স্বাগতম ইউজার!", style: TextStyle(color: Colors.white54, fontSize: 13)),
                Text("মাইনিং প্রো ড্যাশবোর্ড", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
          child: const Icon(CupertinoIcons.bell_fill, color: Colors.amber, size: 22),
        ),
      ],
    );
  }

  // ২. মাইনিং কার্ড (লাইভ এনিমেশন ফিল)
  Widget _buildMiningHero() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [AppColors.blue.withOpacity(0.4), Colors.purple.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                const Text("মাইনিং ব্যালেন্স (লাইভ)", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                const Text("০.০০৪৫৭৮৯০", 
                  style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 20),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {},
                  child: Container(
                    height: 55,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10)],
                    ),
                    child: const Center(
                      child: Text("২৪ ঘণ্টার মাইনিং শুরু করুন", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ৩. ৩ ধরনের ওয়ালেট
  Widget _buildTripleWallet() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _walletCard("মাইনিং ওয়ালেট", "\$১২.৫০", "কয়েন থেকে আয়", Colors.orange),
          _walletCard("ইনকাম ওয়ালেট", "\$৪৫.০০", "রেফার ও ম্যাট্রিক্স", AppColors.emeraldLight),
          _walletCard("ডিপোজিট", "\$১৮.০০", "এক্টিভেশন ফান্ড", Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _walletCard(String label, String val, String sub, Color col) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: col.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: col.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 5),
          Text(val, style: TextStyle(color: col, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  // ৪. গ্লোবাল ম্যাট্রিক্স (১০, ৫, ১ রেফার শর্ত)
  Widget _buildMatrixStatus() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _matrixRow("লেভেল ১ পুল (\$২.০০)", "১০ জন রেফার প্রয়োজন", 0.7),
          const Divider(color: Colors.white10, height: 30),
          _matrixRow("লেভেল ২ পুল (\$১.৫০)", "৫ জন রেফার প্রয়োজন", 0.4),
          const Divider(color: Colors.white10, height: 30),
          _matrixRow("লেভেল ৩ পুল (\$১.৫০)", "১ জন রেফার প্রয়োজন", 1.0),
        ],
      ),
    );
  }

  Widget _matrixRow(String title, String condition, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            Text(condition, style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            color: AppColors.emeraldLight,
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  // ৫. \$১৮ ডিস্ট্রিবিউশন ইনফো
  Widget _buildDistributionInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.blue.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          _distRow("কোম্পানি প্রফিট", "\$৮.০০", "সিস্টেম মেইনটেন্যান্স"),
          const SizedBox(height: 15),
          _distRow("স্পন্সর বোনাস", "\$৫.০০", "সরাসরি আপনার আপলাইন পাবে"),
          const SizedBox(height: 15),
          _distRow("গ্লোবাল ফান্ড", "\$৫.০০", "যোগ্য মেম্বারদের মাঝে বন্টন"),
        ],
      ),
    );
  }

  Widget _distRow(String label, String amount, String note) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            Text(note, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        Text(amount, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ৬. কুইক অ্যাকশন গ্রিড
  Widget _buildActionGrid() {
    return Row(
      children: [
        Expanded(child: _actionBtn("বুস্টিং জোন", CupertinoIcons.rocket_fill, Colors.purpleAccent)),
        const SizedBox(width: 15),
        Expanded(child: _actionBtn("টিম ভিউ", CupertinoIcons.person_2_fill, Colors.blueAccent)),
      ],
    );
  }

  Widget _actionBtn(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}

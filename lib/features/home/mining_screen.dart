import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'dart:async'; // টাইমার এবং রিয়াল-টাইম আপডেটের জন্য

// কন্ডিশনাল ইমপোর্ট: প্ল্যাটফর্ম অনুযায়ী সঠিক ফাইলটি লোড হবে
import '../../../widgets/wallet_connect_stub.dart'
    if (dart.library.js) '../../../widgets/wallet_connect_button.dart';
import '../../../web3/web3_stub.dart'
    if (dart.library.js) '../../../web3/web3_service.dart';

void main() {
  runApp(const VexylonApp());
}

class VexylonApp extends StatelessWidget {
  const VexylonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vexylon Pro Mining',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0C10), // ডার্ক নিয়ন ব্যাকগ্রাউন্ড
      ),
      // এখানে web3Service পাস করতে পারবেন (বর্তমানে null রাখা হয়েছে ডেমোর জন্য)
      home: const MiningScreen(web3Service: null),
    );
  }
}

class MiningScreen extends StatefulWidget {
  final Web3Service? web3Service; // <-- Optional parameter added

  const MiningScreen({super.key, this.web3Service});

  @override
  State<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _miningTimer;
  
  bool isMining = false; // শুরুতে মাইনিং বন্ধ
  double balance = 4520.5000;
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  void _toggleMining() {
    setState(() {
      isMining = !isMining;
      if (isMining) {
        _controller.repeat();
        _startMiningTimer();
      } else {
        _controller.stop();
        _miningTimer?.cancel();
      }
    });
  }

  void _startMiningTimer() {
    _miningTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        balance += 0.0005; // ব্যালেন্স বৃদ্ধি
        progress += 0.002; // প্রোগ্রেস বৃদ্ধি
        if (progress >= 1.0) {
          progress = 0.0;
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _miningTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Stack(
        children: [
          // ওপরের দিকে হালকা নিয়ন গ্লো
          Positioned(
            top: -50,
            left: MediaQuery.of(context).size.width / 2 - 100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF14F195).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(), // হেডার আপডেট করা হয়েছে
                  const SizedBox(height: 30),
                  _buildBalanceSection(),
                  const SizedBox(height: 40),
                  _buildMiningOrb(),
                  const SizedBox(height: 30),
                  _buildProgressBar(),
                  const SizedBox(height: 40),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "স্ট্যাটাস ও অ্যাকশন",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildActionButtons(),
                  const SizedBox(height: 15),
                  _buildStatsGrid(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("HELLO, MINER!", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold)),
            const Text("VEXYLON PRO", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          ],
        ),
        // ডানদিকের অংশ (ওয়ালেট কানেক্ট বাটন + নোটিফিকেশন আইকন)
        Row(
          children: [
            // এখানে Web3Service পাস করা হলো
            WalletConnectButton(web3Service: widget.web3Service), 
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(CupertinoIcons.bell_fill, color: Color(0xFF14F195), size: 20),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildBalanceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text("CURRENT MINED BALANCE", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                balance.toStringAsFixed(4),
                style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 8),
              const Text("COIN", style: TextStyle(color: Color(0xFF14F195), fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF14F195).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text("≈ \$125.00 USD", style: TextStyle(color: Color(0xFF14F195), fontSize: 12, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildMiningOrb() {
    return GestureDetector(
      onTap: _toggleMining,
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isMining)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: 160 + (15 * math.sin(_controller.value * 2 * math.pi)),
                    height: 160 + (15 * math.sin(_controller.value * 2 * math.pi)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF14F195).withOpacity(0.05),
                    ),
                  );
                },
              ),
            RotationTransition(
              turns: _controller,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF14F195).withOpacity(0.2), width: 1),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
                border: Border.all(color: isMining ? const Color(0xFF14F195) : Colors.white24, width: 3),
                boxShadow: isMining ? [BoxShadow(color: const Color(0xFF14F195).withOpacity(0.2), blurRadius: 15)] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isMining ? CupertinoIcons.hammer_fill : CupertinoIcons.bolt_slash_fill, color: isMining ? const Color(0xFF14F195) : Colors.grey, size: 28),
                  const SizedBox(height: 5),
                  Text(isMining ? "RUNNING" : "START", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isMining ? 1.0 : 0.3,
      child: Container(
        width: 220,
        height: 6,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF9945FF), Color(0xFF14F195)]),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(child: _actionBtn("CLAIM", CupertinoIcons.arrow_down_circle_fill, const Color(0xFF14F195))),
        const SizedBox(width: 15),
        Expanded(child: _actionBtn("BOOST", CupertinoIcons.bolt_circle_fill, const Color(0xFF9945FF))),
      ],
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(child: _statCard("HASHRATE", isMining ? "450 TH/S" : "0 TH/S", CupertinoIcons.gauge, const Color(0xFF14F195))),
        const SizedBox(width: 15),
        Expanded(child: _statCard("REFERRALS", "12 USERS", CupertinoIcons.person_2_fill, Colors.orangeAccent)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:reown_appkit/reown_appkit.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  ReownAppKitModal? _appKitModal;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeReown();
  }

  void _initializeReown() async {
    _appKitModal = ReownAppKitModal(
      context: context,
      projectId: 'de4fd9cc5d44e0e8a830b232a38184da',
      // 'const' সরিয়ে দেওয়া হয়েছে যাতে এরর না আসে
      metadata: ReownAppKitModalMetadata(
        name: 'Web3 Mine Matrix',
        description: 'Decentralized Mining Platform',
        url: 'https://yourwebsite.com',
        icons: ['https://yourwebsite.com/logo.png'],
        redirect: Redirect(
          native: 'web3minematrix://',
          universal: 'https://yourwebsite.com',
        ),
      ),
    );

    await _appKitModal!.init();
    _appKitModal!.addListener(_onUpdate);

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _onUpdate() => setState(() {});

  @override
  void dispose() {
    _appKitModal?.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _appKitModal == null) {
      return SizedBox(height: 60.h);
    }

    bool isConnected = _appKitModal!.isConnected;
    
    // মডালের সেশন থেকে অ্যাড্রেস পাওয়ার সবচেয়ে নিরাপদ উপায়
    String? address;
    if (isConnected) {
      // যদি সরাসরি .address না পাওয়া যায়, তবে accounts লিস্ট থেকে নিবে
      final session = _appKitModal?.session;
      if (session != null) {
        address = session.accounts.isNotEmpty 
            ? session.accounts.first.split(':').last 
            : null;
      }
    }

    String displayAddress = (isConnected && address != null)
        ? '${address.substring(0, 4)}...${address.substring(address.length - 4)}'
        : 'Connect';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLogo(),
          _buildWalletButton(isConnected, displayAddress),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("WEB3", style: GoogleFonts.inter(color: Colors.white60, fontSize: 10.sp)),
        Text("MINE MATRIX", style: GoogleFonts.inter(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildWalletButton(bool connected, String addr) {
    return GestureDetector(
      onTap: () => _appKitModal!.openModalView(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: connected ? Colors.green.withOpacity(0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: connected ? Colors.green : Colors.white24),
        ),
        child: Row(
          children: [
            Icon(connected ? Icons.account_balance_wallet : Icons.link, color: Colors.white, size: 18.sp),
            SizedBox(width: 8.w),
            Text(addr, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

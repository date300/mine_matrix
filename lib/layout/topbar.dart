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

  final Color accentGreen = const Color(0xFF14F195);
  final Color accentPurple = const Color(0xFF9945FF);

  @override
  void initState() {
    super.initState();
    _initializeReown();
  }

  void _initializeReown() async {
    // ReownAppKitModal তৈরি করার সময় metadata ক্লাসটির নাম হবে ReownAppKitModalMetadata
    _appKitModal = ReownAppKitModal(
      context: context,
      projectId: 'de4fd9cc5d44e0e8a830b232232a38184da', // আপনার Project ID
      metadata: const ReownAppKitModalMetadata( // এখানে ModalMetadata হবে
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

  void _onUpdate() {
    if (mounted) setState(() {});
  }

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
    
    // লেটেস্ট ভার্সনে অ্যাড্রেস পাওয়ার সঠিক উপায়:
    String? address = _appKitModal?.session?.address;

    String displayAddress = (isConnected && address != null)
        ? '${address.substring(0, 4)}...${address.substring(address.length - 4)}'
        : 'Connect';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLogo(),
          Row(
            children: [
              _buildWalletBtn(isConnected, displayAddress),
              SizedBox(width: 12.w),
              _buildNotificationButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "WEB3",
          style: GoogleFonts.inter(
            color: Colors.white60,
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          "MINE MATRIX",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildWalletBtn(bool connected, String addr) {
    return GestureDetector(
      onTap: () => _appKitModal!.openModalView(),
      child: GlassmorphicContainer(
        width: connected ? 140.w : 50.w,
        height: 45.w,
        borderRadius: 15.r,
        blur: 15,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
        ),
        borderGradient: LinearGradient(
          colors: [
            connected ? accentGreen.withOpacity(0.5) : accentPurple.withOpacity(0.5),
            Colors.transparent
          ]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              connected ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.link,
              color: connected ? accentGreen : Colors.white,
              size: 20.sp
            ),
            if (connected) ...[
              SizedBox(width: 8.w),
              Text(
                addr,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return GlassmorphicContainer(
      width: 45.w,
      height: 45.w,
      borderRadius: 15.r,
      blur: 15,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
      ),
      borderGradient: LinearGradient(
        colors: [Colors.white.withOpacity(0.2), Colors.transparent]
      ),
      child: Icon(CupertinoIcons.bell_fill, color: accentGreen, size: 22.sp),
    );
  }
}


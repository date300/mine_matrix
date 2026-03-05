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
    // ১.৮.৩+ ভার্সনের জন্য লেটেস্ট কনফিগারেশন
    _appKitModal = ReownAppKitModal(
      context: context,
      projectId: 'de4fd9cc5d44e0e8a830b232a38184da',
      metadata: const PairingMetadata(
        name: 'Mine Matrix',
        description: 'Decentralized Mining Platform',
        url: 'https://minematrix.com',
        icons: ['https://minematrix.com/logo.png'],
        redirect: Redirect(
          // এটি AndroidManifest-এর স্কিমের সাথে হুবহু মিলতে হবে
          native: 'minematrix://', 
          universal: 'https://minematrix.com',
        ),
      ),
    );

    await _appKitModal!.init();

    // সেশন আপডেট শোনার জন্য লিসেনার
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

    // অ্যাড্রেস পাওয়ার সঠিক এবং নিরাপদ উপায়
    String? address;
    try {
      if (isConnected && _appKitModal?.session != null) {
        // ডাইনামিক কাস্টিং ব্যবহার করা হয়েছে যাতে বিল্ড এরর না আসে
        address = (_appKitModal?.session as dynamic).address;
      }
    } catch (e) {
      address = null;
    }

    String displayAddress = (isConnected && address != null)
        ? '${address.substring(0, 6)}...${address.substring(address.length - 4)}'
        : 'Connect';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLogo(),
          _buildWalletBtn(isConnected, displayAddress),
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
        width: connected ? 140.w : 120.w,
        height: 45.h,
        borderRadius: 15.r,
        blur: 15,
        alignment: Alignment.center,
        border: 1.5,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [connected ? accentGreen : accentPurple, Colors.transparent]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              connected ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.link,
              color: connected ? accentGreen : Colors.white,
              size: 18.sp
            ),
            SizedBox(width: 8.w),
            Text(
              addr,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ),
    );
  }
}

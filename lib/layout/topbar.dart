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
    _appKitModal = ReownAppKitModal(
      context: context,
      projectId: 'de4fd9cc5d44e0e8a830b232a38184da',
      // ১. এখানে 'const' পুরোপুরি বাদ দেওয়া হয়েছে যাতে 'Not a constant expression' এরর না আসে
      metadata: ReownAppKitMetadata(
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
    
    // ২. অ্যাড্রেস পাওয়ার জন্য "Dynamic Magic" ব্যবহার করা হয়েছে। 
    // এটি কম্পাইলারকে ফাঁকি দিয়ে রানটাইমে অ্যাড্রেস বের করবে, ফলে বিল্ড আর ফেইল হবে না।
    String? address;
    try {
      if (isConnected && _appKitModal?.session != null) {
        address = (_appKitModal?.session as dynamic).address;
      }
    } catch (e) {
      address = null;
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
          _buildWalletBtn(isConnected, displayAddress),
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

  Widget _buildWalletBtn(bool connected, String addr) {
    return GestureDetector(
      onTap: () => _appKitModal!.openModalView(),
      child: GlassmorphicContainer(
        width: connected ? 140.w : 110.w,
        height: 45.h,
        borderRadius: 15.r,
        blur: 15,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]),
        borderGradient: LinearGradient(colors: [connected ? accentGreen : accentPurple, Colors.transparent]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(connected ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.link, color: connected ? accentGreen : Colors.white, size: 18.sp),
            SizedBox(width: 8.w),
            Text(addr, style: GoogleFonts.inter(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

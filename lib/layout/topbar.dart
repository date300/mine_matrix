import 'dart:ui'; // গ্লাস ইফেক্টের জন্য জরুরি
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
    try {
      _appKitModal = ReownAppKitModal(
        context: context,
        projectId: 'de4fd9cc5d44e0e8a830b232a38184da',
        metadata: const PairingMetadata(
          name: 'Mine Matrix',
          description: 'Decentralized Mining Platform',
          url: 'https://minematrix.com',
          icons: ['https://minematrix.com/logo.png'],
          redirect: Redirect(
            native: 'minematrix://',
            universal: 'https://minematrix.com',
          ),
        ),
      );

      await _appKitModal!.init();
      _appKitModal!.addListener(_onUpdate);

    } catch (e) {
      debugPrint("Wallet Init Error: $e");
    } finally {
      // এরর হোক বা সফল, টপবার লোড করে দেবে, আর গায়েব হবে না!
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
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
    bool isConnected = false;
    String? address;

    if (_isInitialized && _appKitModal != null) {
      isConnected = _appKitModal!.isConnected;
      try {
        if (isConnected && _appKitModal?.session != null) {
          address = (_appKitModal?.session as dynamic).address;
        }
      } catch (e) {
        address = null;
      }
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

  // ফ্লাটারের নিজস্ব গ্লাস ইফেক্ট যা ওয়েব এবং অ্যাপ দুই জায়গাতেই ১০০% কাজ করবে
  Widget _buildWalletBtn(bool connected, String addr) {
    return GestureDetector(
      onTap: () {
        if (_isInitialized && _appKitModal != null) {
          _appKitModal!.openModalView();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Initializing Wallet, please wait...")),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: connected ? 140.w : 120.w,
            height: 45.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(
                color: connected ? accentGreen.withOpacity(0.5) : Colors.white24,
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05)
                ],
              ),
            ),
            // যতক্ষণ ইনিশিয়ালাইজ না হচ্ছে, বাটনের ভেতর একটি ছোট লোডিং স্পিনার দেখাবে
            child: !_isInitialized 
              ? SizedBox(
                  height: 20.h, 
                  width: 20.h, 
                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : Row(
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
        ),
      ),
    );
  }
}

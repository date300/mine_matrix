import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
// এটি পেস্ট করুন:
import 'package:mine_matrix/providers/auth_provider.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  final Color accentGreen = const Color(0xFF14F195);

  @override
  void initState() {
    super.initState();
    // অ্যাপ চালু হলেই ওয়ালেট ইনিশিয়ালাইজ হবে
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).initWallet(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Consumer ব্যবহার করে Provider থেকে ডেটা নিচ্ছি
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        String displayAddress = (auth.isConnected && auth.address != null && auth.address!.length > 10)
            ? '${auth.address!.substring(0, 6)}...${auth.address!.substring(auth.address!.length - 4)}'
            : 'Connect';

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLogo(),
              _buildWalletBtn(auth, displayAddress, context),
            ],
          ),
        );
      },
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

  Widget _buildWalletBtn(AuthProvider auth, String addr, BuildContext context) {
    return GestureDetector(
      onTap: () => auth.openWalletModal(context), // প্রোভাইডার থেকে কল হচ্ছে
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            height: 45.h,
            constraints: BoxConstraints(minWidth: 110.w),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(
                color: auth.isConnected ? accentGreen.withOpacity(0.5) : Colors.white24,
                width: 1.5,
              ),
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
              ),
            ),
            child: !auth.isInitialized
                ? SizedBox(
                    height: 18.h,
                    width: 18.h,
                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        auth.isConnected ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.link,
                        color: auth.isConnected ? accentGreen : Colors.white,
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        addr,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

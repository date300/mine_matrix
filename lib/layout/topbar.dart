import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  late W3MService _w3mService;
  bool _isInitialized = false;

  final Color accentGreen = const Color(0xFF14F195);
  final Color accentPurple = const Color(0xFF9945FF);

  @override
  void initState() {
    super.initState();
    _initializeW3M();
  }

  // ওয়ালেট কানেক্ট সার্ভিস ইনিশিয়ালাইজ করা
  void _initializeW3M() async {
    _w3mService = W3MService(
      projectId: 'de4fd9cc5d44e0e8a830b232a38184da', // https://cloud.walletconnect.com থেকে আইডি নিন
      metadata: const PairReownMetadata(
        name: 'Web3 Mine Matrix',
        description: 'Decentralized Mining Platform',
        url: 'https://yourwebsite.com',
        icons: ['https://yourwebsite.com/logo.png'],
        redirect: Redirect(
          native: 'web3minematrix://', // আপনার অ্যাপের স্কিম
          universal: 'https://yourwebsite.com',
        ),
      ),
    );

    await _w3mService.init();
    setState(() {
      _isInitialized = true;
    });
    
    // কানেকশন স্ট্যাটাস চেঞ্জ হলে ইউআই আপডেট করার জন্য
    _w3mService.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    setState(() {});
  }

  @override
  void dispose() {
    _w3mService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox.shrink(); // লোড না হওয়া পর্যন্ত কিছু দেখাবে না
    }

    // ওয়ালেট কানেক্টেড কি না চেক করা
    bool isConnected = _w3mService.isConnected;
    // শর্ট অ্যাড্রেস ফরম্যাট (যেমন: 0x12...abcd)
    String displayAddress = isConnected 
        ? '${_w3mService.session!.address!.substring(0, 4)}...${_w3mService.session!.address!.substring(_w3mService.session!.address!.length - 4)}'
        : '';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // টেক্সট সেকশন
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "WEB3",
                style: GoogleFonts.inter(
                  color: Colors.white60, 
                  fontSize: 12.sp, 
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                "MINE MATRIX",
                style: GoogleFonts.inter(
                  color: Colors.white, 
                  fontSize: 24.sp, 
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          
          Row(
            children: [
              // ওয়ালেট কানেক্ট বাটন
              GestureDetector(
                onTap: () {
                  _w3mService.openModal(context);
                },
                child: GlassmorphicContainer(
                  width: isConnected ? 130.w : 45.w, // কানেক্ট হলে চওড়া হবে
                  height: 45.w,
                  borderRadius: 15.r,
                  blur: 15,
                  alignment: Alignment.center,
                  border: 1,
                  linearGradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1), 
                      Colors.white.withOpacity(0.05)
                    ]
                  ),
                  borderGradient: LinearGradient(
                    colors: [
                      isConnected ? accentGreen.withOpacity(0.5) : accentPurple.withOpacity(0.5), 
                      Colors.transparent
                    ]
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isConnected ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.link, 
                        color: isConnected ? accentGreen : Colors.white, 
                        size: 20.sp
                      ),
                      if (isConnected) ...[
                        SizedBox(width: 8.w),
                        Text(
                          displayAddress,
                          style: GoogleFonts.inter(
                            color: Colors.white, 
                            fontSize: 12.sp, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              
              SizedBox(width: 12.w),

              // নোটিফিকেশন বাটন
              GlassmorphicContainer(
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
                child: Icon(
                  CupertinoIcons.bell_fill, 
                  color: accentGreen, 
                  size: 22.sp
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

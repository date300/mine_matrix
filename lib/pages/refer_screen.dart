import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class ReferScreen extends StatefulWidget {
  const ReferScreen({super.key});

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen> {
  bool _isLoading = true;
  String _referralCode = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfile();
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;

      if (token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('https://ltcminematrix.com/api/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final user = data['user'];
          if (mounted) {
            setState(() {
              _referralCode = user['referral_code']?.toString() ?? "";
              _isLoading = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final referLink = "https://ltcminematrix.com?ref=$_referralCode";

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF14F195)),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 30.h),

                    // Hero Icon
                    Container(
                      height: 120.h,
                      width: 120.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF14F195).withOpacity(0.2),
                            Colors.transparent
                          ],
                        ),
                      ),
                      child: Icon(Icons.hub_rounded,
                          size: 60.sp, color: const Color(0xFF14F195)),
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

                    SizedBox(height: 20.h),

                    Text(
                      "Refer & Build Network",
                      style: GoogleFonts.inter(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      "Earn rewards from 3 levels of connections!\nInvite friends and grow your mining team.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),

                    SizedBox(height: 30.h),

                    // Code & Link Section (Side by Side for modern look)
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoBox(
                            title: "Referral Code",
                            content: _referralCode.isEmpty ? "N/A" : _referralCode,
                            isCode: true,
                          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 15.h),
                    
                    _buildInfoBox(
                      title: "Referral Link",
                      content: referLink,
                      isCode: false,
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.2),

                    SizedBox(height: 35.h),

                    // Multi-Level Network Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Your Network Stats",
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),

                    // Level 1, 2, 3 Cards
                    _buildLevelCard(
                      levelName: "Level 1",
                      description: "Direct Referrals",
                      rewardPer: "10%",
                      userCount: "0", // এগুলো পরে API থেকে ডাইনামিক করতে পারবেন
                      iconColor: const Color(0xFF14F195),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                    
                    SizedBox(height: 12.h),

                    _buildLevelCard(
                      levelName: "Level 2",
                      description: "Indirect Referrals",
                      rewardPer: "5%",
                      userCount: "0",
                      iconColor: Colors.orangeAccent,
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                    
                    SizedBox(height: 12.h),

                    _buildLevelCard(
                      levelName: "Level 3",
                      description: "Sub-Indirect Referrals",
                      rewardPer: "2%",
                      userCount: "0",
                      iconColor: Colors.blueAccent,
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

                    SizedBox(height: 35.h),

                    // Share Button
                    SizedBox(
                      width: double.infinity,
                      height: 55.h,
                      child: ElevatedButton.icon(
                        // লিংটি সরাসরি শেয়ার ফাংশনে পাস করে দেওয়া হলো
                        onPressed: () => auth.shareReferralLink(referLink),
                        icon: const Icon(Icons.share_rounded, color: Colors.black),
                        label: Text(
                          "Share Invite Link",
                          style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold, 
                              color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14F195),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.r)),
                          elevation: 5,
                        ),
                      ),
                    ).animate().scale(delay: 800.ms),

                    SizedBox(height: 50.h),
                  ],
                ),
              ),
      ),
    );
  }

  // Code/Link Box Widget
  Widget _buildInfoBox({required String title, required String content, required bool isCode}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B22),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12.sp),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF14F195),
                    fontSize: isCode ? 20.sp : 14.sp,
                    fontWeight: isCode ? FontWeight.bold : FontWeight.w500,
                    letterSpacing: isCode ? 2 : 0,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Copied $title!"),
                      backgroundColor: const Color(0xFF14F195),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.copy_rounded, color: Colors.white70, size: 18.sp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Level Card Widget
  Widget _buildLevelCard({
    required String levelName,
    required String description,
    required String rewardPer,
    required String userCount,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B22),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Level Icon
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline_rounded, color: iconColor, size: 24.sp),
          ),
          SizedBox(width: 15.w),
          
          // Level Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  levelName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),

          // Stats (Percentage & Users)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rewardPer,
                style: GoogleFonts.inter(
                  color: iconColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Icon(Icons.person, color: Colors.white54, size: 12.sp),
                  SizedBox(width: 4.w),
                  Text(
                    userCount,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}

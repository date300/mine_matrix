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

                    // Top Hub Icon
                    Container(
                      height: 110.h,
                      width: 110.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF14F195).withOpacity(0.2),
                            Colors.transparent
                          ],
                        ),
                      ),
                      child: Icon(Icons.account_tree_rounded,
                          size: 55.sp, color: const Color(0xFF14F195)),
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
                    SizedBox(height: 8.h),
                    Text(
                      "Grow your team and earn rewards from\nthree levels of mining network.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),

                    SizedBox(height: 30.h),

                    // Referral Info Box
                    _buildInfoBox(
                      title: "Your Referral Code",
                      content: _referralCode.isEmpty ? "N/A" : _referralCode,
                      isCode: true,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                    SizedBox(height: 15.h),

                    _buildInfoBox(
                      title: "Your Referral Link",
                      content: referLink,
                      isCode: false,
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                    SizedBox(height: 35.h),

                    // Network Stats Title
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Network Earnings",
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),

                    // Multi-Level Cards
                    _buildLevelCard(
                      levelName: "Level 1",
                      description: "Direct Friends",
                      reward: "10% Reward",
                      iconColor: const Color(0xFF14F195),
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),

                    SizedBox(height: 12.h),

                    _buildLevelCard(
                      levelName: "Level 2",
                      description: "Friends of Friends",
                      reward: "5% Reward",
                      iconColor: Colors.orangeAccent,
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),

                    SizedBox(height: 12.h),

                    _buildLevelCard(
                      levelName: "Level 3",
                      description: "Sub-Network",
                      reward: "2% Reward",
                      iconColor: Colors.blueAccent,
                    ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1),

                    SizedBox(height: 40.h),

                    // Fixed Share Button
                    SizedBox(
                      width: double.infinity,
                      height: 55.h,
                      child: ElevatedButton.icon(
                        // ERROR FIXED: Removed argument to match your AuthProvider
                        onPressed: () => auth.shareReferralLink(),
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
                        ),
                      ),
                    ).animate().scale(delay: 700.ms),

                    SizedBox(height: 50.h),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoBox({required String title, required String content, required bool isCode}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B22),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11.sp)),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF14F195),
                    fontSize: isCode ? 22.sp : 13.sp,
                    fontWeight: isCode ? FontWeight.bold : FontWeight.w400,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Copied to clipboard!")),
                  );
                },
                icon: Icon(Icons.copy_rounded, color: Colors.white70, size: 18.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard({
    required String levelName,
    required String description,
    required String reward,
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
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.group_add_rounded, color: iconColor, size: 22.sp),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(levelName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp)),
                Text(description, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11.sp)),
              ],
            ),
          ),
          Text(reward, style: GoogleFonts.inter(color: iconColor, fontWeight: FontWeight.bold, fontSize: 14.sp)),
        ],
      ),
    );
  }
}

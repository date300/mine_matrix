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
    // উইজেট বিল্ড হওয়ার পর API কল শুরু হবে
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfile();
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;

      if (token == null) {
        debugPrint("Error: No Auth Token Found!");
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // API Request-এ ১৫ সেকেন্ডের টাইমআউট দেওয়া হয়েছে
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
              // API থেকে referral_code স্ট্রিং হিসেবে নেওয়া হচ্ছে
              _referralCode = user['referral_code']?.toString() ?? "";
              _isLoading = false;
            });
          }
        } else {
          debugPrint("API error message: ${data['message']}");
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        debugPrint("Server error code: ${response.statusCode}");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Profile fetch Exception: $e");
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
                    SizedBox(height: 40.h),

                    // Hero Icon
                    Container(
                      height: 150.h,
                      width: 150.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF14F195).withOpacity(0.2),
                            Colors.transparent
                          ],
                        ),
                      ),
                      child: Icon(Icons.people_alt_rounded,
                          size: 80.sp, color: const Color(0xFF14F195)),
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

                    SizedBox(height: 30.h),

                    Text(
                      "Refer & Earn",
                      style: GoogleFonts.inter(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      "Invite your friends and get 10% of their \nmining rewards instantly!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // Referral Code Box
                    _buildInfoBox(
                      title: "Your Referral Code",
                      content: _referralCode.isEmpty ? "N/A" : _referralCode,
                      isCode: true,
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                    SizedBox(height: 25.h),

                    // Referral Link Box
                    _buildInfoBox(
                      title: "Your Referral Link",
                      content: referLink,
                      isCode: false,
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                    SizedBox(height: 30.h),

                    // Share Button
                    SizedBox(
                      width: double.infinity,
                      height: 55.h,
                      child: ElevatedButton.icon(
                        onPressed: () => auth.shareReferralLink(),
                        icon: const Icon(Icons.share, color: Colors.black),
                        label: Text(
                          "Share with Friends",
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14F195),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.r)),
                        ),
                      ),
                    ),

                    SizedBox(height: 100.h),
                  ],
                ),
              ),
      ),
    );
  }

  // কোড ডুপ্লিকেশন কমাতে ছোট একটি উইজেট মেথড
  Widget _buildInfoBox({required String title, required String content, required bool isCode}) {
    return Container(
      padding: EdgeInsets.all(20.w),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B22),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12.sp),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  content,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF14F195),
                    fontSize: isCode ? 24.sp : 14.sp,
                    fontWeight: isCode ? FontWeight.bold : FontWeight.w500,
                    letterSpacing: isCode ? 2 : 0,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Copied to clipboard!")),
                  );
                },
                icon: Icon(Icons.copy, color: Colors.white, size: 20.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

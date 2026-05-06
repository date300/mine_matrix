import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_error_widget.dart';

// --- Colors ---
class AppColors {
  static const Color background    = Color(0xFF0A0A0F);
  static const Color surface       = Color(0xFF12121A);
  static const Color accentGreen   = Color(0xFF00FFA3);
  static const Color accentBlue    = Color(0xFF00D4FF);
  static const Color accentRed     = Color(0xFFFF4D4D);
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B8B9E);
  static const Color border        = Color(0xFF2A2A3A);
  static const Color cardBg        = Color(0xFF161620);
}

const String _baseUrl = 'https://web3.ltcminematrix.com';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amountController = TextEditingController();
  final _walletController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  double _withdrawableBalance = 0.0;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String? _token() => Provider.of<AuthProvider>(context, listen: false).token;

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_token()}',
  };

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchBalance(),
      _fetchHistory(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  // আপনার API অনুযায়ী ব্যালেন্স ফেচ করা (Mining Stats থেকে)
  Future<void> _fetchBalance() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/mining/stats'), headers: _headers());
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        _withdrawableBalance = double.tryParse(d['withdrawable'].toString()) ?? 0.0;
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  // হিস্ট্রি ফেচ করা (GET /withdraw/history)
  Future<void> _fetchHistory() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/withdraw/history'), headers: _headers());
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        _history = d['data'] ?? [];
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  // উইথড্র রিকোয়েস্ট সাবমিট (POST /withdraw)
  Future<void> _submitWithdraw() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final wallet = _walletController.text.trim();

    // Frontend Validation (API লজিক অনুযায়ী)
    if (amount < 5) {
      _showToast("Minimum withdraw is \$5", isError: true);
      return;
    }
    if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(wallet)) {
      _showToast("Invalid BEP20 Wallet Address", isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/withdraw'),
        headers: _headers(),
        body: jsonEncode({'amount': amount, 'wallet': wallet}),
      );

      final d = jsonDecode(res.body);
      if (res.statusCode == 200 && d['success'] == true) {
        _showToast("Withdrawal request submitted!");
        _amountController.clear();
        _walletController.clear();
        _loadData();
      } else {
        _showToast(d['error'] ?? "Withdrawal failed", isError: true);
      }
    } catch (e) {
      _showToast("Connection error", isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: isError ? AppColors.accentRed : AppColors.accentGreen,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(20.w),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.accentGreen,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 60.h),
                  _header(),
                  SizedBox(height: 24.h),
                  _balanceCard(),
                  SizedBox(height: 24.h),
                  _inputForm(),
                  SizedBox(height: 32.h),
                  _sectionTitle("Recent History"),
                  SizedBox(height: 12.h),
                  _historyList(),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
    );
  }

  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Withdraw', style: GoogleFonts.inter(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.bold)),
      Text('Cash out your earnings to BEP20', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14.sp)),
    ],
  );

  Widget _balanceCard() => Container(
    width: double.infinity,
    padding: EdgeInsets.all(24.w),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24.r),
      gradient: LinearGradient(colors: [AppColors.accentBlue.withOpacity(0.2), AppColors.surface]),
      border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
    ),
    child: Column(
      children: [
        Text('Withdrawable Balance', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14.sp)),
        SizedBox(height: 8.h),
        Text('\$${_withdrawableBalance.toStringAsFixed(2)}', 
          style: GoogleFonts.inter(color: Colors.white, fontSize: 36.sp, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _inputForm() => Column(
    children: [
      _customTextField(
        controller: _amountController,
        label: "Amount to Withdraw",
        hint: "Min \$5.00",
        icon: Icons.attach_money_rounded,
        isNumber: true,
      ),
      SizedBox(height: 16.h),
      _customTextField(
        controller: _walletController,
        label: "BEP20 Wallet Address",
        hint: "0x...",
        icon: Icons.account_balance_wallet_rounded,
      ),
      SizedBox(height: 24.h),
      GestureDetector(
        onTap: _isSubmitting ? null : _submitWithdraw,
        child: Container(
          width: double.infinity,
          height: 56.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.accentBlue, Color(0xFF0066FF)]),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [BoxShadow(color: AppColors.accentBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Center(
            child: _isSubmitting 
              ? const CircularProgressIndicator(color: Colors.black)
              : Text('Confirm Withdrawal', style: GoogleFonts.inter(color: Colors.black, fontSize: 16.sp, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    ],
  );

  Widget _customTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, bool isNumber = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12.sp)),
      SizedBox(height: 8.h),
      TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
          prefixIcon: Icon(icon, color: AppColors.accentBlue, size: 20.sp),
          filled: true,
          fillColor: AppColors.surface,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: AppColors.accentBlue)),
        ),
      ),
    ],
  );

  Widget _historyList() {
    if (_history.isEmpty) {
      return Center(child: Text("No withdrawal records found", style: GoogleFonts.inter(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final status = item['status'].toString().toLowerCase();
        Color statusColor = AppColors.textSecondary;
        if (status == 'pending') statusColor = Colors.orange;
        if (status == 'approved') statusColor = AppColors.accentGreen;
        if (status == 'rejected') statusColor = AppColors.accentRed;

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: AppColors.border)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\$${item['amount']}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  SizedBox(height: 4.h),
                  Text(item['created_at'].toString().substring(0, 10), style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11.sp)),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r), border: Border.all(color: statusColor.withOpacity(0.3))),
                child: Text(status.toUpperCase(), style: GoogleFonts.inter(color: statusColor, fontSize: 10.sp, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold));
}

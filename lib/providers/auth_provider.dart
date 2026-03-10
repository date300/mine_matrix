import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:reown_appkit/reown_appkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  ReownAppKitModal? _appKitModal;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _sessionId;
  String? _referralCode;
  String? _lastLoggedAddress;

  // গেটারস (Getters)
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  
  // এই লাইনটি আপনার এরর ফিক্স করবে (Topbar.dart এ এটিই খুঁজছিল)
  bool get isConnected => _appKitModal?.isConnected ?? false;
  
  String? get address => _appKitModal?.session?.address;

  // ১. অ্যাপ ওপেন হলে সেশন চেক করা
  Future<void> initAuth(BuildContext context) async {
    _setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('session_id');

    if (_sessionId != null) {
      _isLoggedIn = true;
      debugPrint("Session found. User is already logged in.");
    }
    _setLoading(false);

    // এরপর ওয়ালেট ইনিশিয়ালাইজ করুন
    await _initWallet(context);
  }

  // ২. রেফারেল কোড সেভ করা
  void setReferralCode(String code) {
    _referralCode = code;
    debugPrint("Referral Code Set: $_referralCode");
  }

  // ৩. ওয়ালেট সেটআপ
  Future<void> _initWallet(BuildContext context) async {
    if (_isInitialized) return;

    try {
      _appKitModal = ReownAppKitModal(
        context: context,
        projectId: 'de4fd9cc5d44e0e8a830b232a38184da',
        metadata: const PairingMetadata(
          name: 'Mine Matrix',
          description: 'Decentralized Mining Platform',
          url: 'https://minematrix.com',
          icons: ['https://minematrix.com/logo.png'],
          redirect: Redirect(native: 'minematrix://', universal: 'https://minematrix.com'),
        ),
      );

      await _appKitModal!.init();
      _appKitModal!.addListener(_onWalletUpdate);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Wallet Init Error: $e");
    }
  }

  // ৪. ওয়ালেট স্ট্যাটাস আপডেট লজিক
  void _onWalletUpdate() {
    final currentAddress = address;

    // যদি কানেক্ট হয় এবং (লগইন না থাকে অথবা নতুন অ্যাড্রেস হয়)
    if (isConnected && currentAddress != null) {
      if (!_isLoggedIn || currentAddress != _lastLoggedAddress) {
        _lastLoggedAddress = currentAddress;
        _loginToBackend(currentAddress);
      }
    } else if (!isConnected) {
      _lastLoggedAddress = null;
      // যদি চান ওয়ালেট ডিসকানেক্ট হলে লগআউট হয়ে যাবে, তবে এখানে logout() কল করতে পারেন।
    }
    notifyListeners(); // UI আপডেট করার জন্য
  }

  // ৫. ব্যাকএন্ড এপিআই কল
  Future<void> _loginToBackend(String walletAddress) async {
    final url = Uri.parse('http://192.168.0.113:8000/auth/login.php');
    _setLoading(true);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'wallet_address': walletAddress,
          'referred_by': _referralCode ?? ""
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('session_id', data['session_id']);

          _sessionId = data['session_id'];
          _isLoggedIn = true;
          debugPrint("Backend Login Success!");
        } else {
          _lastLoggedAddress = null;
          _isLoggedIn = false;
        }
      }
    } catch (e) {
      debugPrint("Login Request Failed: $e");
      _lastLoggedAddress = null;
    } finally {
      _setLoading(false);
    }
  }

  void openModal(BuildContext context) {
    if (_isInitialized && _appKitModal != null) {
      _appKitModal!.openModalView();
    }
  }

  // ৬. লগআউট
  Future<void> logout() async {
    _setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_id');

    if (_appKitModal != null && isConnected) {
      await _appKitModal!.disconnect();
    }

    _isLoggedIn = false;
    _sessionId = null;
    _lastLoggedAddress = null;
    _referralCode = null;

    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _appKitModal?.removeListener(_onWalletUpdate);
    super.dispose();
  }
}

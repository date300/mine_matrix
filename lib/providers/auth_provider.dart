import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:reown_appkit/reown_appkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class AuthProvider extends ChangeNotifier {
  ReownAppKitModal? _appKitModal;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isLoggingIn = false;

  String? _token;
  String? _referralCode;
  String? _inputReferralCode;
  String? _lastLoggedAddress;

  Map<String, dynamic>? _userData;

  // BASE URL (সব জায়গায় একই সাবডোমেইন ব্যবহার করা হয়েছে)
  final String _baseUrl = "https://web3.ltcminematrix.com";

  // --- Getters ---
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isConnected => _appKitModal?.isConnected ?? false;
  bool get isAuthenticated => isConnected && _isLoggedIn;

  String? get token => _token;
  String? get referralCode => _referralCode;
  Map<String, dynamic>? get userData => _userData;

  String? get address {
    final session = _appKitModal?.session;
    if (session == null) return null;
    // প্রথমে Solana চেক করবে, না পেলে EVM/EIP155 চেক করবে
    return session.getAddress('solana') ?? session.getAddress('eip155');
  }

  String? get balance => _userData?['balance']?.toString();

  String get myReferralLink {
    if (_referralCode == null) return "";
    return "$_baseUrl?ref=$_referralCode";
  }

  // =========================
  // 1. INIT AUTH
  // =========================
  Future<void> initAuth(BuildContext context) async {
    _setLoading(true);

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token != null) {
      bool valid = await verifyToken();

      if (valid) {
        _isLoggedIn = true;
        final userStr = prefs.getString('user');
        if (userStr != null) {
          _userData = jsonDecode(userStr);
          _referralCode = _userData?['referral_code'];
        }
      } else {
        // টোকেন ইনভ্যালিড হলে লোকাল ডাটা ক্লিয়ার
        await prefs.remove('token');
        await prefs.remove('user');
        _token = null;
      }
    }

    _setLoading(false);
    // ওয়ালেট সার্ভিসটি সবার শেষে ইনিশিয়ালাইজ হবে
    await initWallet(context);
  }

  // =========================
  // 2. TOKEN VERIFY
  // =========================
  Future<bool> verifyToken() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/user/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // =========================
  // 3. REFERRAL LOGIC
  // =========================
  void setInputReferralCode(String code) {
    _inputReferralCode = code;
  }

  void generateReferralCode() {
    if (_referralCode != null) return;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    _referralCode = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
    notifyListeners();
  }

  // =========================
  // 4. WALLET INIT (FIXED REDIRECT)
  // =========================
  Future<void> initWallet(BuildContext context) async {
    if (_isInitialized) return;

    try {
      _appKitModal = ReownAppKitModal(
        context: context,
        projectId: 'de4fd9cc5d44e0e8a830b232a38184da',
        metadata: const PairingMetadata(
          name: 'Mine Matrix',
          description: 'Decentralized Mining Platform',
          url: 'https://web3.ltcminematrix.com',
          icons: ['https://web3.ltcminematrix.com/logo.png'],
          
          // ? রিডাইরেক্ট সেটিংস ফিক্স (অ্যান্ড্রয়েড ও আইওএস এর জন্য)
          redirect: Redirect(
            native: 'ltcminematrix://',
            universal: 'https://web3.ltcminematrix.com',
          ),
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

  // =========================
  // 5. WALLET UPDATE LISTENER
  // =========================
  void _onWalletUpdate() {
    final currentAddress = address;

    if (isConnected && currentAddress != null) {
      // যদি ওয়ালেট পরিবর্তন করা হয়, তবে অটো লগআউট হবে
      if (_userData?['wallet_address'] != null &&
          _userData!['wallet_address'] != currentAddress) {
        logout();
        return;
      }

      // অটোমেটিক ব্যাকএন্ড লগইন
      if (currentAddress != _lastLoggedAddress && !_isLoggingIn) {
        _isLoggingIn = true;
        _lastLoggedAddress = currentAddress;
        _setLoading(true);

        _loginToBackend(currentAddress).then((success) {
          _isLoggedIn = success;
          if (!success) _lastLoggedAddress = null;
          _isLoggingIn = false;
          _setLoading(false);
          notifyListeners();
        });
      }
    } else if (!isConnected) {
      // ওয়ালেট ডিসকানেক্ট করলে লোকাল স্টেট ক্লিয়ার
      if (_lastLoggedAddress != null || _isLoggedIn) {
        _lastLoggedAddress = null;
        _isLoggedIn = false;
        notifyListeners();
      }
    }
  }

  // =========================
  // 6. LOGIN API
  // =========================
  Future<bool> _loginToBackend(String walletAddress) async {
    final url = Uri.parse('$_baseUrl/api/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'wallet_address': walletAddress,
          'referred_by': _inputReferralCode ?? ""
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          await prefs.setString('user', jsonEncode(data['user']));

          _token = data['token'];
          _userData = data['user'];
          _referralCode = _userData?['referral_code'];
          return true;
        }
      }
      debugPrint("Login API Error: ${response.body}");
    } catch (e) {
      debugPrint("Login Request Failed: $e");
    }
    return false;
  }

  // =========================
  // 7. PUBLIC ACTIONS
  // =========================
  void openModal(BuildContext context) {
    if (_isInitialized && _appKitModal != null) {
      _appKitModal!.openModalView();
    }
  }

  void shareReferralLink() {
    if (_referralCode != null && myReferralLink.isNotEmpty) {
      Share.share("Join Mine Matrix: $myReferralLink");
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');

    if (_appKitModal != null && isConnected) {
      await _appKitModal!.disconnect();
    }

    _isLoggedIn = false;
    _token = null;
    _userData = null;
    _lastLoggedAddress = null;
    _referralCode = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

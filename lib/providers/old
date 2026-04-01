 
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
  String? _token;
  String? _referralCode;
  String? _lastLoggedAddress;
  Map<String, dynamic>? _userData;

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
    return session.getAddress('solana') ?? session.getAddress('eip155');
  }

  String? get balance => _userData?['balance']?.toString();
  String? get walletAddress => _userData?['wallet_address'];

  String get myReferralLink {
    if (_referralCode == null) return "";
    return "https://ltcminematrix.com?ref=$_referralCode";
  }

  // --- Init ---
  Future<void> initAuth(BuildContext context) async {
    _setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token != null) {
      _isLoggedIn = true;
      final userStr = prefs.getString('user');
      if (userStr != null) {
        _userData = jsonDecode(userStr);
        _referralCode = _userData?['referral_code'];
      }
    }

    _setLoading(false);
    await initWallet(context);
  }

  void setReferralCode(String code) {
    _referralCode = code;
    notifyListeners();
  }

  void generateReferralCode() {
    if (_referralCode != null) return;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    _referralCode = String.fromCharCodes(
        Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    notifyListeners();
  }

  // --- Wallet Init ---
  Future<void> initWallet(BuildContext context) async {
    if (_isInitialized) return;

    try {
      _appKitModal = ReownAppKitModal(
        context: context,
        projectId: 'de4fd9cc5d44e0e8a830b232a38184da',
        metadata: const PairingMetadata(
          name: 'Mine Matrix',
          description: 'Decentralized Mining Platform',
          url: 'https://ltcminematrix.com',
          icons: ['https://ltcminematrix.com/logo.png'],
          redirect: Redirect(
              native: 'ltcminematrix://',
              universal: 'https://ltcminematrix.com'),
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

  void _onWalletUpdate() {
    final currentAddress = address;

    if (isConnected && currentAddress != null) {
      if (currentAddress != _lastLoggedAddress) {
        _lastLoggedAddress = currentAddress;
        _setLoading(true);

        _loginToBackend(currentAddress).then((success) {
          if (success) {
            _isLoggedIn = true;
          } else {
            _lastLoggedAddress = null;
            _isLoggedIn = false;
          }
          _setLoading(false);
          notifyListeners();
        });
      }
    } else if (!isConnected) {
      if (_lastLoggedAddress != null || _isLoggedIn) {
        _lastLoggedAddress = null;
        _isLoggedIn = false;
        notifyListeners();
      }
    }
  }

  // --- Login to Backend ---
  Future<bool> _loginToBackend(String walletAddress) async {
    final url = Uri.parse('https://ltcminematrix.com/api/auth/login');

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

          // ✅ JWT Token সেভ
          await prefs.setString('token', data['token']);
          _token = data['token'];

          // ✅ User data সেভ
          await prefs.setString('user', jsonEncode(data['user']));
          _userData = data['user'];
          _referralCode = _userData?['referral_code'];

          return true;
        }
      }
    } catch (e) {
      debugPrint("Login Failed: $e");
    }
    return false;
  }

  void openModal(BuildContext context) {
    if (_isInitialized && _appKitModal != null) {
      _appKitModal!.openModalView();
    }
  }

  // --- Share Referral ---
  void shareReferralLink() {
    if (_referralCode != null && myReferralLink.isNotEmpty) {
      Share.share(
        "Join Mine Matrix with my referral link: $myReferralLink",
        subject: "Mine Matrix Referral",
      );
    }
  }

  // --- Logout ---
  Future<void> logout() async {
    _setLoading(true);
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
    _setLoading(false);
    notifyListeners();
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

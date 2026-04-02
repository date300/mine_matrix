import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// AuthProvider — Phantom Deep Link (Solana)
// Reown/WalletConnect সম্পূর্ণ বাদ দেওয়া হয়েছে
// topbar.dart এর সাথে backward compatible
// ============================================================

class AuthProvider extends ChangeNotifier {
  bool _isInitialized = false; // ✅ topbar এর জন্য
  bool _isLoading     = false;
  bool _isLoggedIn    = false;

  String? _token;
  String? _walletAddress;
  String? _referralCode;
  String? _inputReferralCode;

  Map<String, dynamic>? _userData;

  // --- Base URLs ---
  static const String _baseUrl = 'https://web3.ltcminematrix.com';
  static const String _apiUrl  = 'https://ltcminematrix.com/api';

  // --- Getters ---
  bool get isInitialized   => _isInitialized; // ✅ topbar এ লাগে
  bool get isLoading       => _isLoading;
  bool get isLoggedIn      => _isLoggedIn;
  bool get isConnected     => _walletAddress != null;
  bool get isAuthenticated => isConnected && _isLoggedIn;

  String? get token        => _token;
  String? get address      => _walletAddress;
  String? get referralCode => _referralCode;
  Map<String, dynamic>? get userData => _userData;

  String? get balance => _userData?['balance']?.toString();

  String get myReferralLink {
    if (_referralCode == null) return "";
    return "$_baseUrl?ref=$_referralCode";
  }

  // =========================
  // INIT AUTH
  // =========================
  Future<void> initAuth(BuildContext context) async {
    _setLoading(true);

    final prefs = await SharedPreferences.getInstance();
    _token         = prefs.getString('token');
    _walletAddress = prefs.getString('wallet_address');

    if (_token != null) {
      bool valid = await verifyToken();
      if (valid) {
        _isLoggedIn = true;
        final userStr = prefs.getString('user');
        if (userStr != null) {
          _userData     = jsonDecode(userStr);
          _referralCode = _userData?['referral_code'];
        }
      } else {
        await _clearPrefs();
      }
    }

    _isInitialized = true; // ✅ init শেষ
    _setLoading(false);
    notifyListeners();
  }

  // =========================
  // INIT WALLET
  // topbar.dart এ initWallet(context) call হয় — এটা initAuth কে delegate করে
  // =========================
  Future<void> initWallet(BuildContext context) async {
    // Phantom এর জন্য আলাদা init দরকার নেই
    // শুধু initialized mark করে দাও
    if (_isInitialized) return;
    _isInitialized = true;
    notifyListeners();
  }

  // =========================
  // TOKEN VERIFY
  // =========================
  Future<bool> verifyToken() async {
    try {
      final res = await http.get(
        Uri.parse('$_apiUrl/user/profile'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // =========================
  // REFERRAL
  // =========================
  void setInputReferralCode(String code) {
    _inputReferralCode = code;
  }

  void generateReferralCode() {
    if (_referralCode != null) return;

    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();

    _referralCode = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );

    notifyListeners();
  }

  // =========================
  // OPEN MODAL
  // topbar.dart এ openModal(context) call হয়
  // Phantom connect flow শুরু করে
  // =========================
  void openModal(BuildContext context) {
    connectWallet(context);
  }

  // =========================
  // CONNECT WALLET
  // =========================
  Future<void> connectWallet(BuildContext context) async {
    if (kIsWeb) {
      _connectPhantomWeb(context);
    } else {
      await _connectPhantomMobile();
    }
  }

  // -------------------------------------------------------
  // MOBILE: Phantom deep link
  // -------------------------------------------------------
  Future<void> _connectPhantomMobile() async {
    final params = Uri(
      queryParameters: {
        'app_url'      : _baseUrl,
        'redirect_link': '$_baseUrl/phantom-callback',
        'cluster'      : 'mainnet-beta',
      },
    ).query;

    final phantomUri   = Uri.parse('phantom://v1/connect?$params');
    final universalUri = Uri.parse('https://phantom.app/ul/v1/connect?$params');

    if (await canLaunchUrl(phantomUri)) {
      await launchUrl(phantomUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(universalUri, mode: LaunchMode.externalApplication);
    }
  }

  // -------------------------------------------------------
  // WEB: Phantom browser extension
  // -------------------------------------------------------
  void _connectPhantomWeb(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Phantom Wallet Connect'),
        content: const Text(
          'Desktop এ Phantom extension install করুন।\n\n'
          'Mobile এ Mine Matrix app ব্যবহার করুন।',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await launchUrl(
                Uri.parse('https://phantom.app'),
                mode: LaunchMode.externalApplication,
              );
            },
            child: const Text('Phantom Install'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
        ],
      ),
    );
  }

  // =========================
  // PHANTOM CALLBACK HANDLER
  // main.dart বা router এ deep link handle করার পর এটা call করো
  // =========================
  Future<void> handlePhantomCallback(Uri callbackUri) async {
    try {
      final walletAddress = callbackUri.queryParameters['public_key'];

      if (walletAddress != null && walletAddress.isNotEmpty) {
        await _onWalletConnected(walletAddress);
      }
    } catch (e) {
      debugPrint("Phantom callback error: $e");
    }
  }

  // =========================
  // WALLET CONNECTED → LOGIN
  // =========================
  Future<void> _onWalletConnected(String walletAddress) async {
    _walletAddress = walletAddress;
    _setLoading(true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wallet_address', walletAddress);

    final success = await _loginToBackend(walletAddress);

    _isLoggedIn = success;
    _setLoading(false);
    notifyListeners();
  }

  // Manual set (Web JS interop থেকে)
  Future<void> setWalletAddress(String walletAddress) async {
    await _onWalletConnected(walletAddress);
  }

  // =========================
  // LOGIN API
  // =========================
  Future<bool> _loginToBackend(String walletAddress) async {
    final url = Uri.parse('$_apiUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'wallet_address': walletAddress,
          'referred_by'   : _inputReferralCode ?? "",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();

          await prefs.setString('token', data['token']);
          await prefs.setString('user', jsonEncode(data['user']));

          _token        = data['token'];
          _userData     = data['user'];
          _referralCode = _userData?['referral_code'];

          return true;
        }
      } else {
        debugPrint("API ERROR: ${response.body}");
      }
    } catch (e) {
      debugPrint("Login Failed: $e");
    }

    return false;
  }

  // =========================
  // SHARE
  // =========================
  void shareReferralLink() {
    if (_referralCode != null && myReferralLink.isNotEmpty) {
      Share.share(
        "Join Mine Matrix: $myReferralLink",
        subject: "Referral",
      );
    }
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    await _clearPrefs();

    _isLoggedIn    = false;
    _token         = null;
    _userData      = null;
    _walletAddress = null;
    _referralCode  = null;

    notifyListeners();
  }

  // =========================
  // HELPERS
  // =========================
  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('wallet_address');
    _token         = null;
    _walletAddress = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}


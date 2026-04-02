import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:reown_appkit/reown_appkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // --- Base URLs ---
  static const String _baseUrl = 'https://web3.ltcminematrix.com';
  static const String _apiUrl = 'https://ltcminematrix.com/api';

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

  String get myReferralLink {
    if (_referralCode == null) return "";
    return "$_baseUrl?ref=$_referralCode";
  }

  // =========================
  // INIT
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
        await prefs.remove('token');
        await prefs.remove('user');
        _token = null;
      }
    }

    _setLoading(false);
    await initWallet(context);
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
    Random rnd = Random();

    _referralCode = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );

    notifyListeners();
  }

  // =========================
  // WALLET INIT
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
          url: _baseUrl,
          icons: ['$_baseUrl/logo.png'],
          redirect: Redirect(
            native: 'ltcminematrix://',
            universal: _baseUrl,
            linkMode: true,
          ),
        ),

        // ✅ Popular wallets — Binance সহ
        featuredWalletIds: {
          'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // MetaMask
          '4622a2b2d6af1c9844944291e5e7351a6aa24cd7b23099efac1b2fd875da31a0', // Trust Wallet
          '8a0ee50d1f22f6651afcae7eb4253e52a3310b90af5daef78a8c4929a9bb99d4', // Binance Web3
          'fd20dc426fb37566d803205b19bbc1d4096b248ac04548e3cfb6b3a38bd033aa', // Coinbase
        },
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
  // OPEN WALLET MODAL
  // =========================
  void openModal(BuildContext context) {
    if (!_isInitialized || _appKitModal == null) return;
    _appKitModal!.openModalView();
  }

  // ✅ Mobile browser থেকে manually wallet app open করতে
  // যেমন: openWalletApp(wcUri, 'bnc://') for Binance
  //        openWalletApp(wcUri, 'metamask://') for MetaMask
  //        openWalletApp(wcUri, 'trust://') for Trust Wallet
  Future<void> openWalletApp(String wcUri, String walletScheme) async {
    final encoded = Uri.encodeComponent(wcUri);

    // Wallet এর নিজস্ব deep link দিয়ে try করো
    final customUri = Uri.parse('${walletScheme}wc?uri=$encoded');
    if (await canLaunchUrl(customUri)) {
      await launchUrl(customUri, mode: LaunchMode.externalApplication);
      return;
    }

    // Fallback: WalletConnect এর নিজস্ব link
    final fallbackUri = Uri.parse('https://walletconnect.com/wc?uri=$encoded');
    if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }
  }

  // =========================
  // WALLET UPDATE
  // =========================
  void _onWalletUpdate() {
    final currentAddress = address;

    if (isConnected && currentAddress != null) {

      // wallet change fix
      if (_userData?['wallet_address'] != null &&
          _userData!['wallet_address'] != currentAddress) {
        logout();
        return;
      }

      // duplicate login fix
      if (currentAddress != _lastLoggedAddress && !_isLoggingIn) {
        _isLoggingIn = true;
        _lastLoggedAddress = currentAddress;
        _setLoading(true);

        _loginToBackend(currentAddress).then((success) {
          _isLoggedIn = success;

          if (!success) {
            _lastLoggedAddress = null;
          }

          _isLoggingIn = false;
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
          'referred_by': _inputReferralCode ?? "",
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

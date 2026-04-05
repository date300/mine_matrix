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

  // --- Getters ---
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isConnected => _appKitModal?.isConnected ?? false;
  bool get isAuthenticated => isConnected && _isLoggedIn;

  String? get token => _token;
  String? get referralCode => _referralCode;
  Map<String, dynamic>? get userData => _userData;

  // ✅ FIX: wallet address সবসময় database থেকে আসবে (JWT token থাকলে)
  // Session থেকে আর নেওয়া হবে না
  String? get address => _userData?['wallet_address']?.toString();

  // ✅ FIX: session identifier - database address প্রথমে, তারপর session fallback
  String? get _sessionIdentifier {
    // JWT আছে এবং database-এ wallet address আছে → সেটাই ব্যবহার করো
    if (_userData?['wallet_address'] != null) {
      return _userData!['wallet_address'].toString();
    }

    // fallback: session থেকে নাও (login হওয়ার আগে)
    final session = _appKitModal?.session;
    if (session == null) return null;

    return session.getAddress('solana') ??
        session.getAddress('eip155') ??
        session.getAddress('email') ??
        session.getAddress('social') ??
        session.topic ??
        session.peer?.metadata.url;
  }

  String? get balance => _userData?['balance']?.toString();

  String get myReferralLink {
    if (_referralCode == null) return "";
    return "https://web3.ltcminematrix.com?ref=$_referralCode";
  }

  // =========================
  // INIT
  // =========================
  Future<void> initAuth(BuildContext context) async {
    _setLoading(true);

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token != null) {
      // ✅ Token valid হলে database থেকে fresh user data আনো
      final valid = await verifyTokenAndFetchUser();

      if (valid) {
        _isLoggedIn = true;
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
        Uri.parse('https://web3.ltcminematrix.com/api/user/profile'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ✅ NEW: Token verify করো + database থেকে user data আনো
  Future<bool> verifyTokenAndFetchUser() async {
    try {
      final res = await http.get(
        Uri.parse('https://web3.ltcminematrix.com/api/user/profile'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // API response-এ user data থাকলে সেটা save করো
        if (data['user'] != null) {
          _userData = data['user'];
        } else if (data['data'] != null) {
          _userData = data['data'];
        } else {
          // Response নিজেই user object হলে
          _userData = data;
        }

        _referralCode = _userData?['referral_code'];

        // SharedPreferences আপডেট করো
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_userData));

        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Token verify failed: $e");

      // Network error হলে cached data থেকে লোড করো
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      if (userStr != null) {
        _userData = jsonDecode(userStr);
        _referralCode = _userData?['referral_code'];
        notifyListeners();
        return true;
      }
    }

    return false;
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
          url: 'https://web3.ltcminematrix.com',
          icons: ['https://web3.ltcminematrix.com/logo.png'],
          redirect: Redirect(
            native: 'web3.ltcminematrix://',
            universal: 'https://web3.ltcminematrix.com',
          ),
        ),
        featuresConfig: FeaturesConfig(
          socials: [
            AppKitSocialOption.Email,
            AppKitSocialOption.Google,
            AppKitSocialOption.Apple,
            AppKitSocialOption.Telegram,
            AppKitSocialOption.Discord,
          ],
          showMainWallets: true,
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
  // WALLET UPDATE
  // =========================
  void _onWalletUpdate() {
    final currentIdentifier = _sessionIdentifier;

    debugPrint("=== WALLET UPDATE ===");
    debugPrint("isConnected: $isConnected");
    debugPrint("identifier: $currentIdentifier");

    if (isConnected && currentIdentifier != null) {

      // ✅ FIX: database-এর wallet address দিয়ে wallet change চেক করো
      final dbWalletAddress = _userData?['wallet_address'];
      if (dbWalletAddress != null) {
        final sessionAddress = _appKitModal?.session?.getAddress('solana') ??
            _appKitModal?.session?.getAddress('eip155');

        if (sessionAddress != null && sessionAddress != dbWalletAddress) {
          debugPrint("Wallet changed! Logging out...");
          logout();
          return;
        }
      }

      // Duplicate login block
      if (currentIdentifier != _lastLoggedAddress && !_isLoggingIn) {
        _isLoggingIn = true;
        _lastLoggedAddress = currentIdentifier;
        _setLoading(true);

        // Login করো session address দিয়ে
        final sessionAddress = _appKitModal?.session?.getAddress('solana') ??
            _appKitModal?.session?.getAddress('eip155') ??
            _appKitModal?.session?.getAddress('email') ??
            _appKitModal?.session?.getAddress('social') ??
            currentIdentifier;

        _loginToBackend(sessionAddress).then((success) {
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
    final url = Uri.parse('https://web3.ltcminematrix.com/api/auth/login');

    try {
      debugPrint("Logging in with: $walletAddress");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'wallet_address': walletAddress,
          'referred_by': _inputReferralCode ?? ""
        }),
      );

      debugPrint("Login response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();

          await prefs.setString('token', data['token']);
          await prefs.setString('user', jsonEncode(data['user']));

          _token = data['token'];

          // ✅ _userData সবসময় database response থেকে সেট হয়
          // এখান থেকেই address getter কাজ করবে
          _userData = data['user'];
          _referralCode = _userData?['referral_code'];

          debugPrint("✅ DB wallet address: ${_userData?['wallet_address']}");

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
  // OPEN WALLET MODAL
  // =========================
  void openModal(BuildContext context) {
    if (_isInitialized && _appKitModal != null) {
      _appKitModal!.openModalView();
    }
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

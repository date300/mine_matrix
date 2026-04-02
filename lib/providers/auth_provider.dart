import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

// ─────────────────────────────────────────────
// Supported Wallets
// ─────────────────────────────────────────────
enum SupportedWallet { metamask, trustwallet, okx }

extension SupportedWalletExt on SupportedWallet {
  String get displayName {
    switch (this) {
      case SupportedWallet.metamask:    return 'MetaMask';
      case SupportedWallet.trustwallet: return 'Trust Wallet';
      case SupportedWallet.okx:         return 'OKX Wallet';
    }
  }

  // Deep-link scheme to open the wallet app with a WC URI
  String wcDeepLink(String wcUri) {
    final encoded = Uri.encodeComponent(wcUri);
    switch (this) {
      case SupportedWallet.metamask:
        return 'metamask://wc?uri=$encoded';
      case SupportedWallet.trustwallet:
        return 'trust://wc?uri=$encoded';
      case SupportedWallet.okx:
        return 'okex://main/wc?uri=$encoded';
    }
  }

  // Fallback: store page if the app is not installed
  String get storeUrl {
    switch (this) {
      case SupportedWallet.metamask:
        return 'https://metamask.io/download/';
      case SupportedWallet.trustwallet:
        return 'https://trustwallet.com/download';
      case SupportedWallet.okx:
        return 'https://www.okx.com/download';
    }
  }
}

// ─────────────────────────────────────────────
// AuthProvider
// ─────────────────────────────────────────────
class AuthProvider extends ChangeNotifier {
  // ── WalletConnect ──
  Web3App? _web3App;
  SessionData? _session;
  bool _isInitialized = false;

  // ── App state ──
  bool _isLoading      = false;
  bool _isLoggedIn     = false;
  bool _isLoggingIn    = false;

  // ── User data ──
  String? _token;
  String? _referralCode;
  String? _inputReferralCode;
  String? _lastLoggedAddress;
  Map<String, dynamic>? _userData;

  // ─── Getters ───
  bool get isInitialized  => _isInitialized;
  bool get isLoading      => _isLoading;
  bool get isLoggedIn     => _isLoggedIn;
  bool get isConnected    => _session != null;
  bool get isAuthenticated => isConnected && _isLoggedIn;

  String? get token       => _token;
  String? get referralCode => _referralCode;
  Map<String, dynamic>? get userData => _userData;
  String? get balance     => _userData?['balance']?.toString();

  /// Returns the connected Solana wallet address (or EVM as fallback)
  String? get address {
    if (_session == null) return null;

    final namespaces = _session!.namespaces;

    // Prefer Solana
    final solanaAccounts = namespaces['solana']?.accounts ?? [];
    if (solanaAccounts.isNotEmpty) {
      // Format: "solana:mainnet:<address>"
      return solanaAccounts.first.split(':').last;
    }

    // Fallback: EVM
    final evmAccounts = namespaces['eip155']?.accounts ?? [];
    if (evmAccounts.isNotEmpty) {
      return evmAccounts.first.split(':').last;
    }

    return null;
  }

  String get myReferralLink {
    if (_referralCode == null) return '';
    return 'https://web3.ltcminematrix.com?ref=$_referralCode';
  }

  // ═══════════════════════════════════════════
  // INIT
  // ═══════════════════════════════════════════
  Future<void> initAuth(BuildContext context) async {
    _setLoading(true);

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token != null) {
      final valid = await verifyToken();
      if (valid) {
        _isLoggedIn = true;
        final userStr = prefs.getString('user');
        if (userStr != null) {
          _userData    = jsonDecode(userStr);
          _referralCode = _userData?['referral_code'];
        }
      } else {
        await prefs.remove('token');
        await prefs.remove('user');
        _token = null;
      }
    }

    _setLoading(false);
    await _initWalletConnect();
  }

  // ═══════════════════════════════════════════
  // WalletConnect v2 — INIT
  // ═══════════════════════════════════════════
  Future<void> _initWalletConnect() async {
    if (_isInitialized) return;

    try {
      _web3App = await Web3App.createInstance(
        projectId: 'de4fd9cc5d44e0e8a830b232a38184da', // 🔑 Replace with your WC project ID
        metadata: const PairingMetadata(
          name:        'Mine Matrix',
          description: 'Decentralized Mining Platform',
          url:         'https://web3.ltcminematrix.com',
          icons:       ['https://web3.ltcminematrix.com/logo.png'],
          redirect: Redirect(
            native:    'web3.ltcminematrix://',
            universal: 'https://web3.ltcminematrix.com',
          ),
        ),
      );

      // Listen to session events
      _web3App!.onSessionConnect.subscribe(_onSessionConnect);
      _web3App!.onSessionDelete.subscribe(_onSessionDelete);
      _web3App!.onSessionExpire.subscribe(_onSessionExpire);

      // Restore previous session (if any)
      final sessions = _web3App!.sessions.getAll();
      if (sessions.isNotEmpty) {
        _session = sessions.first;
        debugPrint('WC: Restored session for $address');
      }

      _isInitialized = true;
      notifyListeners();

    } catch (e) {
      debugPrint('WalletConnect Init Error: $e');
    }
  }

  // ═══════════════════════════════════════════
  // CONNECT — show wallet picker
  // ═══════════════════════════════════════════
  Future<void> connectWallet(
    BuildContext context,
    SupportedWallet wallet,
  ) async {
    if (!_isInitialized || _web3App == null) {
      debugPrint('WC not initialized yet');
      return;
    }

    try {
      _setLoading(true);

      // Create a new WC pairing URI
      final connectResponse = await _web3App!.connect(
        requiredNamespaces: {
          // Request Solana
          'solana': const RequiredNamespace(
            chains:  ['solana:mainnet'],
            methods: ['solana_signTransaction', 'solana_signMessage'],
            events:  [],
          ),
        },
        optionalNamespaces: {
          // Also accept EVM wallets as fallback
          'eip155': const RequiredNamespace(
            chains:  ['eip155:1'],
            methods: ['eth_sign', 'personal_sign'],
            events:  ['chainChanged', 'accountsChanged'],
          ),
        },
      );

      final wcUri = connectResponse.uri?.toString();
      if (wcUri == null) {
        debugPrint('WC URI is null');
        _setLoading(false);
        return;
      }

      debugPrint('WC URI: $wcUri');

      // Open selected wallet via deep link
      final deepLink = wallet.wcDeepLink(wcUri);
      final launched = await launchUrl(
        Uri.parse(deepLink),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Wallet not installed → open store
        debugPrint('${wallet.displayName} not installed. Opening store...');
        await launchUrl(Uri.parse(wallet.storeUrl));
        _setLoading(false);
        return;
      }

      // Wait for session approval (timeout: 2 min)
      await connectResponse.session.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw Exception('WalletConnect session timeout'),
      );

      // _onSessionConnect will handle the rest
    } catch (e) {
      debugPrint('Connect Error: $e');
      _setLoading(false);
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════
  // SESSION EVENTS
  // ═══════════════════════════════════════════
  void _onSessionConnect(SessionConnect? event) {
    if (event == null) return;

    _session = event.session;
    debugPrint('WC: Session connected — address: $address');

    final currentAddress = address;
    if (currentAddress == null) return;

    // Wallet changed while logged in → force logout
    if (_userData?['wallet_address'] != null &&
        _userData!['wallet_address'] != currentAddress) {
      logout();
      return;
    }

    // Prevent duplicate login
    if (currentAddress != _lastLoggedAddress && !_isLoggingIn) {
      _isLoggingIn       = true;
      _lastLoggedAddress = currentAddress;

      _loginToBackend(currentAddress).then((success) {
        _isLoggedIn = success;
        if (!success) _lastLoggedAddress = null;
        _isLoggingIn = false;
        _setLoading(false);
        notifyListeners();
      });
    } else {
      _setLoading(false);
      notifyListeners();
    }
  }

  void _onSessionDelete(SessionDelete? event) {
    debugPrint('WC: Session deleted');
    _clearSession();
  }

  void _onSessionExpire(SessionExpire? event) {
    debugPrint('WC: Session expired');
    _clearSession();
  }

  void _clearSession() {
    _session           = null;
    _isLoggedIn        = false;
    _lastLoggedAddress = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════
  // TOKEN VERIFY
  // ═══════════════════════════════════════════
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

  // ═══════════════════════════════════════════
  // LOGIN API
  // ═══════════════════════════════════════════
  Future<bool> _loginToBackend(String walletAddress) async {
    final url = Uri.parse('https://ltcminematrix.com/api/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'wallet_address': walletAddress,
          'referred_by':    _inputReferralCode ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          await prefs.setString('user',  jsonEncode(data['user']));

          _token        = data['token'];
          _userData     = data['user'];
          _referralCode = _userData?['referral_code'];

          return true;
        }
      } else {
        debugPrint('API ERROR: ${response.body}');
      }
    } catch (e) {
      debugPrint('Login Failed: $e');
    }

    return false;
  }

  // ═══════════════════════════════════════════
  // REFERRAL
  // ═══════════════════════════════════════════
  void setInputReferralCode(String code) => _inputReferralCode = code;

  void generateReferralCode() {
    if (_referralCode != null) return;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd   = Random();
    _referralCode = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
    notifyListeners();
  }

  void shareReferralLink() {
    if (_referralCode != null && myReferralLink.isNotEmpty) {
      Share.share('Join Mine Matrix: $myReferralLink', subject: 'Referral');
    }
  }

  // ═══════════════════════════════════════════
  // LOGOUT
  // ═══════════════════════════════════════════
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');

    if (_web3App != null && _session != null) {
      try {
        await _web3App!.disconnectSession(
          topic:  _session!.topic,
          reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
        );
      } catch (e) {
        debugPrint('Disconnect error: $e');
      }
    }

    _session          = null;
    _isLoggedIn       = false;
    _token            = null;
    _userData         = null;
    _lastLoggedAddress = null;
    _referralCode     = null;

    notifyListeners();
  }

  // ═══════════════════════════════════════════
  // DISPOSE
  // ═══════════════════════════════════════════
  @override
  void dispose() {
    _web3App?.onSessionConnect.unsubscribe(_onSessionConnect);
    _web3App?.onSessionDelete.unsubscribe(_onSessionDelete);
    _web3App?.onSessionExpire.unsubscribe(_onSessionExpire);
    super.dispose();
  }

  // ── Helper ──
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

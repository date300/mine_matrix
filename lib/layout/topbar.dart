import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

// =============================================================
// AUTH PROVIDER
// =============================================================
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

  final _appLinks = AppLinks();

  // --- Getters ---
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isConnected =>
      kIsWeb ? _isLoggedIn : (_appKitModal?.isConnected ?? false);
  bool get isAuthenticated => isConnected && _isLoggedIn;

  String? get token => _token;
  String? get referralCode => _referralCode;
  Map<String, dynamic>? get userData => _userData;
  String? get address => _userData?['wallet_address']?.toString();
  String? get balance => _userData?['balance']?.toString();

  String? get _sessionIdentifier {
    if (_userData?['wallet_address'] != null) {
      return _userData!['wallet_address'].toString();
    }
    final session = _appKitModal?.session;
    if (session == null) return null;
    return session.getAddress('solana') ??
        session.getAddress('eip155') ??
        session.getAddress('email') ??
        session.getAddress('social') ??
        session.topic ??
        session.peer?.metadata.url;
  }

  String get myReferralLink {
    if (_referralCode == null) return "";
    return "https://web3.ltcminematrix.com?ref=$_referralCode";
  }

  // =========================
  // DEEP LINK INIT
  // =========================
  Future<void> initDeepLinks() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint("✅ Initial deep link: $initialLink");
        _extractReferralFromLink(initialLink);
      }
      _appLinks.uriLinkStream.listen((uri) {
        debugPrint("✅ Deep link received: $uri");
        _extractReferralFromLink(uri);
      });
    } catch (e) {
      debugPrint("Deep link init error: $e");
    }
  }

  void _extractReferralFromLink(Uri uri) {
    final ref = uri.queryParameters['ref'];
    if (ref != null && ref.trim().isNotEmpty) {
      _inputReferralCode = ref.trim().toUpperCase();
      debugPrint("✅ Referral code from deep link: $_inputReferralCode");
      notifyListeners();
    }
  }

  // =========================
  // INIT TOKEN ONLY — Cache-First
  // =========================
  Future<void> initTokenOnly() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (_token != null) {
      // ✅ Cached data আগে দেখাও
      final userStr = prefs.getString('user');
      if (userStr != null) {
        _userData = jsonDecode(userStr);
        _referralCode = _userData?['referral_code'];
        _isLoggedIn = true;
        notifyListeners();
      }

      // ✅ Background এ verify
      _verifyInBackground(prefs);
    }
  }

  void _verifyInBackground(SharedPreferences prefs) {
    verifyTokenAndFetchUser().then((valid) {
      if (!valid) {
        prefs.remove('token');
        prefs.remove('user');
        _token = null;
        _isLoggedIn = false;
        _userData = null;
        notifyListeners();
      }
    }).catchError((e) {
      debugPrint("Background verify error: $e");
    });
  }

  // =========================
  // TOKEN VERIFY + USER FETCH
  // =========================
  Future<bool> verifyTokenAndFetchUser() async {
    try {
      final res = await http.get(
        Uri.parse('https://web3.ltcminematrix.com/api/user/profile'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data['user'] != null) {
          _userData = data['user'];
        } else if (data['data'] != null) {
          _userData = data['data'];
        } else {
          _userData = data;
        }

        _referralCode = _userData?['referral_code'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_userData));

        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Token verify failed: $e");

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
  // WEB LOGIN — wallet address দিয়ে
  // =========================
  Future<bool> loginWithAddress(String walletAddress) async {
    _setLoading(true);
    final success = await _loginToBackend(walletAddress.trim());
    if (success) {
      _isLoggedIn = true;
      _lastLoggedAddress = walletAddress.trim();
    }
    _setLoading(false);
    notifyListeners();
    return success;
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
  // WALLET INIT — শুধু Mobile এ
  // =========================
  Future<void> initWallet(BuildContext context) async {
    if (kIsWeb) {
      // Web এ Reown SDK লাগবে না
      _isInitialized = true;
      notifyListeners();
      return;
    }

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
  // WALLET UPDATE — শুধু Mobile এ
  // =========================
  void _onWalletUpdate() {
    if (kIsWeb) return;

    final currentIdentifier = _sessionIdentifier;

    debugPrint("=== WALLET UPDATE ===");
    debugPrint("isConnected: $isConnected");
    debugPrint("identifier: $currentIdentifier");

    if (isConnected && currentIdentifier != null) {
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

      if (currentIdentifier != _lastLoggedAddress && !_isLoggingIn) {
        _isLoggingIn = true;
        _lastLoggedAddress = currentIdentifier;
        _setLoading(true);

        final sessionAddress = _appKitModal?.session?.getAddress('solana') ??
            _appKitModal?.session?.getAddress('eip155') ??
            _appKitModal?.session?.getAddress('email') ??
            _appKitModal?.session?.getAddress('social') ??
            currentIdentifier;

        _loginToBackend(sessionAddress).then((success) {
          _isLoggedIn = success;
          if (!success) _lastLoggedAddress = null;
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
          'referred_by': _inputReferralCode ?? "",
        }),
      );

      debugPrint("Login response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();

          _token = data['token'];
          _userData = data['user'];
          _referralCode = _userData?['referral_code'];

          await prefs.setString('token', _token!);
          await prefs.setString('user', jsonEncode(_userData));

          debugPrint("✅ DB wallet address: ${_userData?['wallet_address']}");
          debugPrint("✅ Referral code: $_referralCode");

          return true;
        } else {
          debugPrint(
              "Login failed: status=${data['status']}, message=${data['message']}");
        }
      } else {
        debugPrint("API ERROR ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("Login Failed: $e");
    }

    return false;
  }

  // =========================
  // OPEN MODAL
  // Web → address input dialog
  // Mobile → Reown modal
  // =========================
  void openModal(BuildContext context) {
    if (kIsWeb) {
      _showWebLoginDialog(context);
    } else if (_isInitialized && _appKitModal != null) {
      _appKitModal!.openModalView();
    }
  }

  void _showWebLoginDialog(BuildContext context) {
    final controller = TextEditingController();
    String? errorMsg;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Connect Wallet",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter your wallet address to connect",
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "0x... or Solana address",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  errorText: errorMsg,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel",
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14F195),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final addr = controller.text.trim();
                if (addr.isEmpty) {
                  setState(() => errorMsg = "Address cannot be empty");
                  return;
                }
                Navigator.pop(ctx);
                final success = await loginWithAddress(addr);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text("Login failed. Check your wallet address."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Connect"),
            ),
          ],
        ),
      ),
    );
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
    if (_token != null) {
      try {
        await http.post(
          Uri.parse('https://web3.ltcminematrix.com/api/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        );
      } catch (e) {
        debugPrint("Logout API call failed (ignoring): $e");
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');

    if (!kIsWeb && _appKitModal != null && isConnected) {
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

// =============================================================
// TOP BAR WIDGET
// =============================================================
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    const Color accentGreen = Color(0xFF14F195);

    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final String displayAddress =
            (auth.isConnected &&
                    auth.address != null &&
                    auth.address!.length > 10)
                ? '${auth.address!.substring(0, 6)}...${auth.address!.substring(auth.address!.length - 4)}'
                : 'Connect';

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLogo(),
              _buildWalletBtn(auth, displayAddress, context, accentGreen),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/icon/icon.png',
          height: 28.h,
          width: 28.h,
          fit: BoxFit.contain,
        ),
        SizedBox(width: 6.w),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "WEB3",
              style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 8.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "MINE MATRIX",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWalletBtn(
    AuthProvider auth,
    String addr,
    BuildContext context,
    Color accentGreen,
  ) {
    return GestureDetector(
      onTap: () => auth.openModal(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            height: 38.h,
            constraints: BoxConstraints(minWidth: 90.w),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: auth.isConnected
                    ? accentGreen.withOpacity(0.5)
                    : Colors.white24,
                width: 1.2,
              ),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
            child: !auth.isInitialized
                ? SizedBox(
                    height: 16.h,
                    width: 16.h,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        auth.isConnected
                            ? CupertinoIcons.checkmark_seal_fill
                            : CupertinoIcons.link,
                        color: auth.isConnected ? accentGreen : Colors.white,
                        size: 14.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        addr,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

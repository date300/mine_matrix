import 'dart:convert';
import 'package:http/http.dart' as http;

const String _baseUrl = 'https://web3.ltcminematrix.com';

class MiningService {
  final String token;

  MiningService({required this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ─── GET /api/mining/status ───────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchStatus() async {
    final res = await http
        .get(Uri.parse('$_baseUrl/api/mining/status'), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Status fetch failed: ${res.statusCode}');
  }

  // ─── POST /api/mining/start-day ───────────────────────────────────────────
  Future<void> startDay() async {
    final res = await http
        .post(Uri.parse('$_baseUrl/api/mining/start-day'), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? body['message'] ?? 'Could not start mining');
    }
  }

  // ─── POST /api/mining/claim ───────────────────────────────────────────────
  Future<Map<String, dynamic>> claim() async {
    final res = await http
        .post(Uri.parse('$_baseUrl/api/mining/claim'), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    final body = jsonDecode(res.body);
    throw Exception(body['error'] ?? body['message'] ?? 'Claim failed');
  }

  // ─── POST /api/mining/buy-boost (নতুন যোগ করা হয়েছে) ─────────────────────
  Future<void> buyBoost(double amount) async {
    final res = await http
        .post(
          Uri.parse('$_baseUrl/api/mining/buy-boost'),
          headers: _headers,
          body: jsonEncode({'amount': amount}),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? body['message'] ?? 'Boost purchase failed');
    }
  }

  // ─── POST /api/mining/buy-auto (নতুন যোগ করা হয়েছে) ────────────────
  Future<void> buyAutoMining() async {
    final res = await http
        .post(
          Uri.parse('$_baseUrl/api/mining/buy-auto'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? body['message'] ?? 'Auto-mining unlock failed');
    }
  }
}

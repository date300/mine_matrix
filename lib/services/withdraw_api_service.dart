import 'dart:convert';
import 'package:http/http.dart' as http;

class WithdrawApiService {
  static const String baseUrl = 'https://web3.ltcminematrix.com';

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ------------------------------------------------------------------
  // ব্যালেন্স (withdrawable) আনবে – ধরে নিচ্ছি backend-এ /api/mining/status আছে
  // ------------------------------------------------------------------
  Future<double> getWithdrawableBalance(String token) async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/mining/status'), headers: _headers(token))
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return double.tryParse(data['withdrawable']?.toString() ?? '0') ?? 0;
    }
    throw Exception('Balance fetch failed (${res.statusCode})');
  }

  // ------------------------------------------------------------------
  // উইথড্র হিস্ট্রি – paginated
  // ------------------------------------------------------------------
  Future<(List<Map<String, dynamic>>, bool hasMore)> getHistory(
      String token, {
    int page = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse('$baseUrl/api/withdraw/history')
        .replace(queryParameters: {'page': '$page', 'limit': '$limit'});
    final res = await http
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final data = List<Map<String, dynamic>>.from(body['data'] ?? []);
      return (data, data.length >= limit);
    }
    throw Exception('History fetch failed (${res.statusCode})');
  }

  // ------------------------------------------------------------------
  // উইথড্র রিকোয়েস্ট
  // ------------------------------------------------------------------
  Future<Map<String, dynamic>> requestWithdraw(
      String token, double amount, String wallet) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/withdraw'),
          headers: _headers(token),
          body: jsonEncode({'amount': amount, 'wallet': wallet}),
        )
        .timeout(const Duration(seconds: 20));

    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      return body['data']; // { withdrawId, amount, wallet, status }
    }
    throw Exception(body['error'] ?? 'Withdrawal failed');
  }
}

// lib/web3/web3_web.dart
import 'package:flutter_web3/flutter_web3.dart';

class Web3Service {
  Ethereum ethereum = Ethereum();

  bool get isConnected => ethereum.isConnected;

  Future<String?> getAccount() async {
    final accounts = await ethereum.requestAccount();
    return accounts.isNotEmpty ? accounts.first : null;
  }

  Future<String?> getBalance(String account) async {
    final balanceHex = await ethereum.request('eth_getBalance', [account, 'latest']);
    final balance = BigInt.parse(balanceHex.replaceFirst('0x', ''), radix: 16);
    return (balance / BigInt.from(10).pow(18)).toString();
  }
}

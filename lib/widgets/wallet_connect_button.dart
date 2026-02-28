import 'package:flutter/material.dart';
import '../web3/web3_stub.dart'
    if (dart.library.js) 'web3_service.dart';

class WalletConnectButton extends StatelessWidget {
  final Web3Service? web3Service;

  const WalletConnectButton({super.key, this.web3Service});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Web only logic
        web3Service?.connectWallet();
      },
      child: const Text('Connect Wallet'),
    );
  }
}

// lib/widgets/wallet_connect_stub.dart
import 'package:flutter/material.dart';

class WalletConnectButton extends StatelessWidget {
  // এখানে web3Service প্যারামিটারটি যোগ করা হয়েছে
  final dynamic web3Service; 

  // কনস্ট্রাক্টরে এটি গ্রহণ করার ব্যবস্থা করা হয়েছে
  const WalletConnectButton({super.key, this.web3Service});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wallet only available on Web")),
        );
      },
      child: const Text("Connect Wallet"),
    );
  }
}

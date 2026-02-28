import 'package:flutter/material.dart';

class WalletConnectButton extends StatelessWidget {
  const WalletConnectButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wallet connect not available on Web")),
        );
      },
      child: const Text("Connect Wallet"),
    );
  }
}

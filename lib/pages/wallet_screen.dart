import 'package:flutter/material.dart';
import '../../core/constants.dart';

class WalletScreen extends StatelessWidget {
  // ১. বাইরে থেকে আসা web3Service গ্রহণ করার জন্য এই লাইনটি যোগ করা হয়েছে
  final dynamic web3Service;

  // ২. কনস্ট্রাক্টরে {this.web3Service} যোগ করা হয়েছে যাতে main.dart থেকে ডাটা আসতে পারে
  const WalletScreen({super.key, this.web3Service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // আপনার আগের ডিজাইন অনুযায়ী অ্যাপবার
      appBar: AppBar(
        title: const Text("ওয়ালেট"), 
        centerTitle: true, 
        backgroundColor: Colors.transparent, 
        elevation: 0
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.glassWhite, 
              borderRadius: BorderRadius.circular(20)
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.blue, 
                child: Icon(Icons.arrow_upward, color: Colors.white)
              ),
              title: Text("উইথড্রাল #${index + 100}"),
              subtitle: const Text("সফল হয়েছে"),
              trailing: const Text(
                "-\$২৫.০০", 
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)
              ),
            ),
          );
        },
      ),
    );
  }
}

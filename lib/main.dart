import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Provider প্যাকেজ ইমপোর্ট

// আপনার লেআউট এবং প্রোভাইডার ইমপোর্ট
import 'layout/layout.dart';
import 'providers/auth_provider.dart'; // আপনার AuthProvider এর সঠিক পাথ দিন

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ওয়েব এবং অ্যাপ দুই জায়গাতেই স্ক্রিন সাইজ ঠিক রাখার জন্য এটি অত্যন্ত জরুরি
  await ScreenUtil.ensureScreenSize();

  // Get.put(MiningController()); // এটি পরে ব্যবহার করতে পারবেন

  // অ্যাপটি রান করার সময় MultiProvider দিয়ে র‍্যাপ করা হলো
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()), // AuthProvider যুক্ত করা হলো
      ],
      child: const MiningApp(),
    ),
  );
}

class MiningApp extends StatelessWidget {
  const MiningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Mine Matrix',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF14F195),
            scaffoldBackgroundColor: const Color(0xFF0D0D12),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          home: const AppLayout(), // আপনার মূল লেআউট
        );
      },
    );
  }
}

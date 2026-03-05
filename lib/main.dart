import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// আপনার লেআউট ইমপোর্ট
import 'layout/layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ওয়েব এবং অ্যাপ দুই জায়গাতেই স্ক্রিন সাইজ ঠিক রাখার জন্য এটি অত্যন্ত জরুরি
  await ScreenUtil.ensureScreenSize();

  // Get.put(MiningController());

  runApp(const MiningApp());
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
          home: const AppLayout(),
        );
      },
    );
  }
}

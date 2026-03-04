import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// আপনার লেআউট ইমপোর্ট
import 'layout/layout.dart';

// (যদি MiningController অন্য কোনো ফাইলে থাকে, তবে সেটির ইমপোর্ট এখানে দিতে হবে। 
// আপাতত অ্যাপ যেন ক্র্যাশ না করে তাই এটি কমেন্ট করে রাখলাম। আপনার যদি কন্ট্রোলার বানানো থাকে, তবে // সরিয়ে দেবেন।)

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
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
          // এখানে সরাসরি আপনার তৈরি করা AppLayout কল করা হয়েছে
          home: const AppLayout(),
        );
      },
    );
  }
}

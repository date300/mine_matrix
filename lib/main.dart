import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'layout/layout.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenUtil.ensureScreenSize();
  
  // App খোলার আগেই token load + verify করো
  final authProvider = AuthProvider();
  await authProvider.initTokenOnly();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider), // আগে তৈরি instance pass করো
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
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
          home: const SplashScreen(),
        );
      },
    );
  }
}

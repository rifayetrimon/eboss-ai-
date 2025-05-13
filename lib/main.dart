import 'package:eboss_ai/bindings/app_bindings.dart';
import 'package:eboss_ai/bindings/home_binding.dart';
import 'package:eboss_ai/bindings/login_binding.dart';
import 'package:eboss_ai/pages/auth/login.dart';
import 'package:eboss_ai/pages/home/home.dart';
import 'package:eboss_ai/pages/welcome/splash.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'EBOSS AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color.fromARGB(0, 168, 41, 41),
        fontFamily: 'Roboto',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEAD0DB), Color(0xFFB6CEEB)],
            ),
          ),
          child: child,
        );
      },
      initialBinding: AppBindings(),
      getPages: [
        GetPage(name: '/splash', page: () => const SplashPage()),
        GetPage(
          name: '/login',
          page: () => const LoginPage(),
          binding: LoginBinding(),
        ),
        GetPage(name: '/home', page: () => HomePage(), binding: HomeBinding()),
      ],
      home: const SplashPage(),
    );
  }
}

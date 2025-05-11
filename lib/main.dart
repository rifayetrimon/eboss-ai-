import 'package:eboss_ai/pages/welcome/splash.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Your App Name',
      // Set global theme configurations
      theme: ThemeData(scaffoldBackgroundColor: Colors.transparent),
      // Apply gradient to all routes
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 226, 207, 215),
                Color.fromARGB(255, 200, 214, 231),
              ],
            ),
          ),
          child: child,
        );
      },
      home: const SplashPage(),
    );
  }
}

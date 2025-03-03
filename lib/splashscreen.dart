import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:watchhub/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LandingPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2228),
      body:Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // App Name
            const Text(
              "WatchHub Store",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.8,
                fontFamily: 'Poppins',
              ),
            ),
            // Lottie Animation
         Container(
           child:Lottie.asset(
             'assets/animations/splash.json',
             width: 200,
             height: 200,
             fit: BoxFit.cover,
           ),
         ),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 150),
              child: const Text(
                "Get amazing deals and premium watches. Luxury, quality, and elegance in one place!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontFamily: 'Poppins',
                ),
              ),
            ),



          ],
        ),
      ),
    );
  }
}

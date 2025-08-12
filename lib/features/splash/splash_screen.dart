import 'dart:async';

import 'package:ado_dad_user/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  int step = 1;
  Alignment _circleAlignment = Alignment.topCenter;
  bool _showWhiteLogo = false;

  @override
  void initState() {
    super.initState();
    startSplashSequence();
  }

  void startSplashSequence() {
    Timer(Duration(seconds: 2), () {
      setState(() {
        step = 2;
      });
      // Delay before starting the movement to make it feel smoother
      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          _circleAlignment = Alignment.center; // Move smoothly to center
        });
      });

      // Change the logo to white the moment the circle reaches the center
      Future.delayed(Duration(milliseconds: 600), () {
        setState(() {
          _showWhiteLogo = true; // Switch logo to white
        });
      });
      Timer(Duration(milliseconds: 1), () {
        setState(() {
          step = 3;
        });
        Timer(Duration(seconds: 2), () {
          setState(() {
            step = 4;
          });
          Timer(Duration(seconds: 2), () {
            context.go('/login');
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          step == 4 ? AppColors.primaryColor : AppColors.whiteColor,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // step 1 ; static logo
            // if (step == 1) Image.asset('assets/images/Ado-dad1.png'),

            // step 2 ; blue circle moving down
            // if (step >= 2)
            //   AnimatedAlign(
            //     alignment: _circleAlignment,
            //     key: ValueKey(2),
            //     duration: Duration(seconds: 2),
            //     curve: Curves.easeInOut,
            //     child: Container(
            //       width: 300,
            //       height: 300,
            //       decoration: BoxDecoration(
            //           color: AppColors.primaryColor, shape: BoxShape.circle),
            //       // child: Center(
            //       //   child: Image.asset('assets/images/Ado-dad-white.png'),
            //       // ),
            //     ),
            //   ),

            if (!_showWhiteLogo)
              Image.asset(
                'assets/images/Ado-dad1.png', // Blue logo
                // width: 150,
              ),

            // 🔹 Step 2: Animate Blue Circle from Top to Center
            if (step >= 2)
              AnimatedAlign(
                alignment: _circleAlignment,
                key: ValueKey(2),
                duration: Duration(seconds: 1),
                curve: Curves.easeInOut,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                      color: AppColors.primaryColor, shape: BoxShape.circle),
                ),
              ),

            // 🔹 Step 2 End: Instantly Switch Logo to White
            if (step >= 2)
              AnimatedOpacity(
                duration: Duration(seconds: 2), // Smooth transition
                opacity: _showWhiteLogo ? 0.0 : 0.0, // Fade in white logo
                child: Image.asset(
                  'assets/images/Ado-dad-white.png', // White logo
                  // width: 150,
                ),
              ),

            if (step >= 2)
              Image.asset(
                'assets/images/Ado-dad-white.png',
                cacheWidth: 700, // White logo
                // width: 150,
              ),

            //  step 3 ; bubble animation
            if (step == 3)
              AnimatedContainer(
                duration: Duration(seconds: 2),
                width: 120,
                height: 120,
                decoration:
                    BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Center(
                  child: Image.asset('assets/images/Ado-dad.png'),
                ),
              ),

            // step 4 ; white logo on blue background
            if (step == 4) Image.asset('assets/images/Ado-dad-white.png')
          ],
        ),
      ),
    );
  }
}

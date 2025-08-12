import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({super.key});

  @override
  State<SplashScreen1> createState() => _SplashScreen1State();
}

class _SplashScreen1State extends State<SplashScreen1> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      context.go('/splash-2');
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.5; // 50% of screen width
    return Scaffold(
      // body: Center(
      //   child: Image(image: AssetImage('assets/images/Ado-dad1.png')),
      // ),
      body: Center(
        child: Image.asset(
          'assets/images/Ado-dad1.png',
          width: imageSize,
          height: imageSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class SplashScreen2 extends StatefulWidget {
  const SplashScreen2({super.key});

  @override
  State<SplashScreen2> createState() => _SplashScreen2State();
}

class _SplashScreen2State extends State<SplashScreen2>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late Animation<Offset> _circleAnimation;
  late AnimationController _logoController;
  late Animation<double> _logoFadeAnimation;

  @override
  void initState() {
    super.initState();

    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _circleAnimation = Tween<Offset>(
      begin: const Offset(0, -2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _circleController,
      curve: Curves.easeOutBack,
    ));

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await _circleController.forward();
    await Future.delayed(const Duration(milliseconds: 0));
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    context.go('/splash-3');
  }

  @override
  void dispose() {
    _circleController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final circleSize = screenWidth * 0.6;
    final logoSize = screenWidth * 0.4;
    return Scaffold(
      body: Center(
        child: SlideTransition(
          position: _circleAnimation,
          child: Container(
            // width: 300,
            // height: 300,
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4F46E5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 25,
                  spreadRadius: 1,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: FadeTransition(
              opacity: _logoFadeAnimation,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Blue logo underneath
                      Opacity(
                        opacity: value,
                        child: Image.asset(
                          'assets/images/Ado-dad1.png',
                          // width: 200,
                          // height: 200,
                          width: logoSize,
                          height: logoSize,
                        ),
                      ),
                      // White logo fading out
                      Opacity(
                        opacity: 1,
                        child: Image.asset(
                          'assets/images/Ado-dad-white.png',
                          // width: 200,
                          // height: 200,
                          width: logoSize,
                          height: logoSize,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // FadeTransition(
            //   opacity: _logoFadeAnimation,
            //   child: AnimatedSwitcher(
            //     duration: const Duration(seconds: 0),
            //     transitionBuilder: (child, animation) => FadeTransition(
            //       opacity: animation,
            //       child: ScaleTransition(scale: animation, child: child),
            //     ),
            //     child: Image.asset(
            //       'assets/images/Ado-dad-white.png',
            //       width: 250,
            //       height: 250,
            //     ),
            //   ),
            // ),
          ),
        ),
      ),
    );
  }
}

class SplashScreen3 extends StatefulWidget {
  const SplashScreen3({super.key});

  @override
  State<SplashScreen3> createState() => _SplashScreen3State();
}

class _SplashScreen3State extends State<SplashScreen3>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _scaleAnimation;
  late AnimationController _logoFadeController;
  late Animation<double> _logoFadeAnimation;

  @override
  void initState() {
    super.initState();

    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeOutBack),
    );

    _logoFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoFadeAnimation = CurvedAnimation(
      parent: _logoFadeController,
      curve: Curves.easeIn,
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await _expandController.forward();
    await Future.delayed(const Duration(milliseconds: 0));
    await _logoFadeController.forward();
    await Future.delayed(const Duration(milliseconds: 1000));
    context.go('/splash-4');
  }

  @override
  void dispose() {
    _expandController.dispose();
    _logoFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final circleSize = screenWidth * 0.6;
    final logoSize = screenWidth * 0.4;
    return Scaffold(
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            // width: 300,
            // height: 300,
            width: circleSize,
            height: circleSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  // width: 300,
                  // height: 300,
                  width: circleSize,
                  height: circleSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.white, Color(0x884F46E5)],
                      stops: [0.9, 1.0],
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 0),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: Image.asset(
                      'assets/images/Ado-dad1.png',
                      // width: 250,
                      // height: 250,
                      width: logoSize,
                      height: logoSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SplashScreen4 extends StatefulWidget {
  const SplashScreen4({super.key});

  @override
  State<SplashScreen4> createState() => _SplashScreen4State();
}

class _SplashScreen4State extends State<SplashScreen4> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = screenWidth * 0.4;
    return Scaffold(
      backgroundColor: const Color(0xFF4F46E5),
      body: Center(
        child: Image.asset(
          'assets/images/Ado-dad-white.png',
          // width: 250,
          // height: 250,
          width: logoSize,
          height: logoSize,
        ),
      ),
    );
  }
}

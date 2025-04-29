import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'onborading_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initializing the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 3), // Duration for the animation
      vsync: this,
    );

    // Fade-in animation for the "Your skin care companion" text
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Scale animation for the "Your skin care companion" text
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start the animation
    _controller.forward();

    // Navigate to the next screen after a delay
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 5)); // splash delay

    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool('onboarding_complete') ?? false;

    if (onboardingSeen) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
        (route) => false, // This will remove all previous screens in the stack
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => OnboardingScreen()),
        (route) => false, // This will remove all previous screens in the stack
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller when no longer needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade100, Colors.deepPurple.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Static "GlowSutra" logo text
              Text(
                'GlowSutra',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins', // Elegant font style
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.deepPurple.withOpacity(0.7),
                      offset: Offset(0, 0),
                    ),
                    Shadow(
                      blurRadius: 15.0,
                      color: Colors.deepPurple.withOpacity(0.6),
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Animated "Your skin care companion" tagline text
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: AnimatedOpacity(
                      opacity: _opacityAnimation.value,
                      duration: const Duration(seconds: 3),
                      child: Text(
                        'Your skin care companion',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withOpacity(0.7),
                          fontFamily: 'Poppins', // Elegant font style
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

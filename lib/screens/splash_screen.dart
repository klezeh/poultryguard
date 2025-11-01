// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final String? message; // NEW: Optional message parameter

  const SplashScreen({super.key, this.message}); // NEW: Added message to constructor

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Add TickerProviderStateMixin for AnimationController
class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(seconds: 3), // Match the animation duration to the delay
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    );
    _logoController.forward(); // Start the animation

    _navigateToNextScreen();
  }

  // Method to handle navigation based on authentication state
  _navigateToNextScreen() async {
    // Delay for the duration of the animation or longer if desired
    await Future.delayed(const Duration(seconds: 3));

    // CRITICAL: Check if the widget is still mounted before attempting to navigate.
    // If it's not mounted (e.g., if the user navigated away), stop execution.
    if (!mounted) return;

    // This SplashScreen should primarily handle its animation and then defer
    // to the main.dart's StreamBuilder for actual navigation based on auth/farmId.
    // So, we simply pop it after its animation, allowing main.dart to take over.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    // Alternatively, if this SplashScreen is the very first screen in the app
    // and main.dart is waiting for its completion, you might need a different
    // navigation approach (e.g., signaling completion to a parent FutureBuilder).
    // For now, assuming main.dart's StreamBuilder will handle routing.
  }

  @override
  void dispose() {
    _logoController.dispose(); // Dispose the controller to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background as requested
      body: Center(
        child: Column( // Use Column to hold logo and optional message
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _animation, // Apply the fade animation to the logo
              child: Image.asset(
                'assets/images/app_logo.png', // Ensure this path is correct for your app logo
                width: 200,
                fit: BoxFit.contain, // Ensures the image fits within bounds without distortion
              ),
            ),
            if (widget.message != null && widget.message!.isNotEmpty) // NEW: Display message if provided
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  widget.message!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

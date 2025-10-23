import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/theme_controller.dart';
import 'controllers/news_controller.dart'; // IMPORT BARU

// import your pages
import 'pages/home_page.dart';
import 'pages/onboarding_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Initialize controllers so they're available globally
  final ThemeController themeController = Get.put(ThemeController());
  final NewsController newsController = Get.put(
    NewsController(),
  ); // TAMBAHKAN INI

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        title: 'Kabarind!',
        debugShowCheckedModeBanner: false,

        // Themes
        theme: ThemeData(
          brightness: Brightness.light,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.red.shade700,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey[900],
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.red.shade700,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: themeController.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,

        // LANGSUNG KE ONBOARDING UNTUK TESTING
        home: SplashScreen(), // UBAH KE SPLASH SCREEN
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _textAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _logoAnimationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _textAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _logoRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _textSlideAnimation =
        Tween<Offset>(begin: Offset(0, 0.3), end: Offset(0, 0)).animate(
          CurvedAnimation(
            parent: _textAnimationController,
            curve: Curves.easeOutBack,
          ),
        );

    // Start animations
    _logoAnimationController.forward();

    Future.delayed(Duration(milliseconds: 600), () {
      if (mounted) {
        _textAnimationController.forward();
      }
    });

    // Check onboarding status after animations
    _checkOnboardingStatus();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  void _checkOnboardingStatus() async {
    try {
      // Show splash for 2.5 seconds
      await Future.delayed(Duration(milliseconds: 2500));

      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Read onboarding status from SharedPreferences (production)
      bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      // UNTUK TESTING - SELALU TAMPILKAN ONBOARDING
      // Untuk memaksa selalu menampilkan onboarding saat debugging, uncomment baris di bawah:
      // bool onboardingCompleted = false; // HARDCODE UNTUK TESTING

      print('DEBUG: Onboarding completed: $onboardingCompleted');

      if (onboardingCompleted) {
        print('DEBUG: Navigating to HomePage');

        // Pastikan NewsController sudah siap sebelum ke HomePage
        final newsController = Get.find<NewsController>();
        await newsController.fetchTopHeadlines(); // Load data sebelum navigasi

        Get.offAll(() => HomePage());
      } else {
        print('DEBUG: Navigating to OnboardingPage');
        Get.offAll(() => OnboardingPage());
      }
    } catch (e) {
      print('DEBUG: Error in _checkOnboardingStatus: $e');
      // If there's an error, default to showing onboarding
      if (mounted) {
        Get.offAll(() => OnboardingPage());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[700],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.red[700]!, Colors.red[800]!, Colors.red[900]!],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              AnimatedBuilder(
                animation: _logoAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: Transform.rotate(
                      angle: _logoRotationAnimation.value * 0.1,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.newspaper_rounded,
                          size: 60,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 40),

              // Animated Text
              SlideTransition(
                position: _textSlideAnimation,
                child: FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'Kabarind!',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Stay updated with latest news',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 80),

              // Loading indicator
              FadeTransition(
                opacity: _textFadeAnimation,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

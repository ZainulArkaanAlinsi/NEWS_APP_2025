import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

import 'home_page.dart';

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _iconAnimationController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotationAnimation;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Are you feeling limited\nin the office?",
      description:
          "It is not new. Break the boundary and think outside the box.",
      icon: Icons.work_outline_rounded,
      color: Color(0xFF6366F1),
      gradient: [Color(0xFF4F46E5), Color(0xFF6366F1)],
      bgPattern: Icons.business_center_rounded,
      bgGradient: [Color(0xFF0D0D1F), Color(0xFF1D1D30), Color(0xFF2D2D44)],
    ),
    OnboardingData(
      title: "You can work\nanywhere.",
      description:
          "Freedom is key. As simple as it is, you only need to choose your spot.",
      icon: Icons.public_rounded,
      color: Color(0xFF10B981),
      gradient: [Color(0xFF059669), Color(0xFF10B981)],
      bgPattern: Icons.location_on_rounded,
      bgGradient: [Color(0xFF001F1F), Color(0xFF003030), Color(0xFF004444)],
    ),
    OnboardingData(
      title: "All you need is\nonly a phone",
      description: "or any other device. Connect and create anywhere, anytime.",
      icon: Icons.phone_iphone_rounded,
      color: Color(0xFFF59E0B),
      gradient: [Color(0xFFD97706), Color(0xFFF59E0B)],
      bgPattern: Icons.devices_rounded,
      bgGradient: [Color(0xFF1F0D00), Color(0xFF301B00), Color(0xFF442800)],
    ),
    OnboardingData(
      title: "Ready to Work\nAnywhere?",
      description:
          "Start your journey to flexible working today. Welcome aboard!",
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFFEC4899),
      gradient: [Color(0xFFDB2777), Color(0xFFEC4899)],
      bgPattern: Icons.flag_rounded,
      bgGradient: [Color(0xFF1F0D18), Color(0xFF301525), Color(0xFF441F38)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _iconScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _iconRotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.easeOutBack,
      ),
    );
    _iconAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isVerySmallScreen = screenSize.height < 600;

    return Scaffold(
      body: AnimatedContainer(
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _pages[_currentPage].bgGradient,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _buildBackgroundPattern(context),
              Column(
                children: [
                  _buildHeader(isSmallScreen),
                  Expanded(
                    child: _buildPageView(isSmallScreen, isVerySmallScreen),
                  ),
                  _buildBottomSection(isSmallScreen, isVerySmallScreen),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundPattern(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Multiple blur effects for better depth
          ...List.generate(3, (index) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 1200),
              width: 200 + (index * 100),
              height: 200 + (index * 100),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pages[_currentPage].color.withOpacity(
                  0.3 - (index * 0.1),
                ),
              ),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 60 + (index * 20),
                    sigmaY: 60 + (index * 20),
                  ),
                  child: Container(color: Colors.transparent),
                ),
              ),
            );
          }),

          // Animated pattern icon
          AnimatedSwitcher(
            duration: Duration(milliseconds: 800),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.7, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: Opacity(
              key: ValueKey<IconData>(_pages[_currentPage].bgPattern),
              opacity: 0.06,
              child: Icon(
                _pages[_currentPage].bgPattern,
                size: 450,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20.0 : 24.0,
        vertical: isSmallScreen ? 16.0 : 20.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Enhanced logo
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              'Zernews',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),

          if (_currentPage < _pages.length - 1)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: TextButton(
                onPressed: _completeOnboarding,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withOpacity(0.9),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16.0 : 20.0,
                    vertical: isSmallScreen ? 8.0 : 10.0,
                  ),
                ),
                child: Text(
                  'SKIP',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14.0 : 15.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageView(bool isSmallScreen, bool isVerySmallScreen) {
    return PageView.builder(
      controller: _pageController,
      itemCount: _pages.length,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
        _iconAnimationController.reset();
        _iconAnimationController.forward();
      },
      itemBuilder: (context, index) =>
          _buildPage(_pages[index], isSmallScreen, isVerySmallScreen),
    );
  }

  Widget _buildPage(
    OnboardingData data,
    bool isSmallScreen,
    bool isVerySmallScreen,
  ) {
    final iconSize = isVerySmallScreen
        ? 120.0
        : (isSmallScreen ? 140.0 : 160.0);
    final titleFontSize = isVerySmallScreen
        ? 28.0
        : (isSmallScreen ? 34.0 : 40.0);
    final descriptionFontSize = isVerySmallScreen
        ? 16.0
        : (isSmallScreen ? 18.0 : 19.0);
    final spacing = isVerySmallScreen ? 24.0 : (isSmallScreen ? 40.0 : 50.0);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 30.0 : 40.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Enhanced icon with rotation
              AnimatedBuilder(
                animation: _iconAnimationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _iconRotationAnimation.value,
                    child: Transform.scale(
                      scale: _iconScaleAnimation.value,
                      child: _buildIconContainer(
                        data.icon,
                        data.gradient,
                        iconSize,
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: spacing),

              // Enhanced text animation
              AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: Offset(0.0, 0.3),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Column(
                  key: ValueKey<String>(data.title),
                  children: [
                    Text(
                      data.title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmallScreen ? 16.0 : 20.0),
                    Text(
                      data.description,
                      style: TextStyle(
                        fontSize: descriptionFontSize,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Enhanced feature grid for last page
              if (_pages.indexOf(data) == _pages.length - 1) ...[
                SizedBox(height: isSmallScreen ? 30.0 : 44.0),
                _buildFeatureGrid(data.color, isSmallScreen),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon, List<Color> gradient, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(0.6),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: gradient.first.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, size: size * 0.45, color: Colors.white),
      ),
    );
  }

  Widget _buildFeatureGrid(Color color, bool isSmallScreen) {
    final features = [
      {'icon': Icons.work_rounded, 'text': 'Flexible'},
      {'icon': Icons.location_on_rounded, 'text': 'Anywhere'},
      {'icon': Icons.access_time_rounded, 'text': 'Efficient'},
      {'icon': Icons.security_rounded, 'text': 'Secure'},
      {'icon': Icons.people_rounded, 'text': 'Collaborative'},
      {'icon': Icons.trending_up_rounded, 'text': 'Productive'},
    ];

    return Wrap(
      spacing: isSmallScreen ? 12.0 : 16.0,
      runSpacing: isSmallScreen ? 12.0 : 16.0,
      alignment: WrapAlignment.center,
      children: features.map((feature) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 400),
          child: _buildFeatureChip(
            feature['icon'] as IconData,
            feature['text'] as String,
            color,
            isSmallScreen,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeatureChip(
    IconData icon,
    String text,
    Color color,
    bool isSmallScreen,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 20.0,
        vertical: isSmallScreen ? 10.0 : 12.0,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 16.0 : 18.0, color: color),
          SizedBox(width: isSmallScreen ? 6.0 : 8.0),
          Text(
            text,
            style: TextStyle(
              fontSize: isSmallScreen ? 13.0 : 14.0,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(bool isSmallScreen, bool isVerySmallScreen) {
    final buttonPadding = isVerySmallScreen
        ? EdgeInsets.symmetric(horizontal: 24, vertical: 14)
        : EdgeInsets.symmetric(
            horizontal: 32,
            vertical: isSmallScreen ? 16 : 18,
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 30.0 : 40.0,
        isSmallScreen ? 16.0 : 20.0,
        isSmallScreen ? 30.0 : 40.0,
        isSmallScreen ? 24.0 : 34.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Enhanced dot indicator
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_pages.length, (index) {
                bool isActive = _currentPage == index;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 400),
                    margin: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 3.0 : 4.0,
                    ),
                    height: isSmallScreen ? 6.0 : 7.0,
                    width: isActive
                        ? (isSmallScreen ? 24.0 : 28.0)
                        : (isSmallScreen ? 6.0 : 7.0),
                    decoration: BoxDecoration(
                      color: isActive
                          ? _pages[index].color
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: _pages[index].color.withOpacity(0.7),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: Offset(0, 0),
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ),

          SizedBox(height: isSmallScreen ? 30.0 : 40.0),

          // Enhanced main button
          AnimatedContainer(
            duration: Duration(milliseconds: 500),
            width: double.infinity,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton(
                onPressed: _currentPage == _pages.length - 1
                    ? _completeOnboarding
                    : _nextPage,
                style: ElevatedButton.styleFrom(
                  padding: buttonPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 12,
                  backgroundColor: _pages[_currentPage].color,
                  shadowColor: _pages[_currentPage].color.withOpacity(0.5),
                  animationDuration: Duration(milliseconds: 300),
                ),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: Row(
                    key: ValueKey<int>(_currentPage),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == _pages.length - 1
                            ? 'GET STARTED'
                            : 'CONTINUE',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 17.0 : 18.0,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 10.0 : 12.0),
                      Icon(
                        _currentPage == _pages.length - 1
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        size: isSmallScreen ? 20.0 : 22.0,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Enhanced back button
          if (_currentPage > 0) ...[
            SizedBox(height: isSmallScreen ? 14.0 : 20.0),
            TextButton(
              onPressed: _previousPage,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.7),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Previous',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 14.0 : 16.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 600),
        curve: Curves.easeInOutQuart,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOutQuart,
      );
    }
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    Get.offAll(
      () => HomePage(),
      transition: Transition.fadeIn,
      duration: Duration(milliseconds: 1000),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final IconData bgPattern;
  final List<Color> bgGradient;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.bgPattern,
    required this.bgGradient,
  });
}

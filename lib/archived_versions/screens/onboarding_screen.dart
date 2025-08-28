import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:payment_reminder_app/screens/auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _backgroundAnimationController;
  late Animation<Color?> _backgroundColorAnimation;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      animationAsset: 'assets/animations/welcome.json',
      title: 'Welcome to PayTrack',
      description:
          'Your personal payment reminder assistant that helps you stay on top of all your bills and expenses.',
      backgroundColor: const Color(0xFF6366F1),
      secondaryColor: const Color(0xFF8B5CF6),
    ),
    OnboardingData(
      animationAsset: 'assets/animations/notification.json',
      title: 'Never Miss a Payment',
      description:
          'Get timely reminders for all your upcoming bills and never worry about late fees again.',
      backgroundColor: const Color(0xFF059669),
      secondaryColor: const Color(0xFF10B981),
    ),
    OnboardingData(
      animationAsset: 'assets/animations/stats.json',
      title: 'Track Your Spending',
      description:
          'Visualize your payment history, manage your budget, and gain insights into your spending patterns.',
      backgroundColor: const Color(0xFFDC2626),
      secondaryColor: const Color(0xFFEF4444),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _backgroundColorAnimation = ColorTween(
      begin: _onboardingData[0].backgroundColor,
      end: _onboardingData[0].backgroundColor,
    ).animate(_backgroundAnimationController);
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    _backgroundColorAnimation = ColorTween(
      begin: _backgroundColorAnimation.value,
      end: _onboardingData[page].backgroundColor,
    ).animate(_backgroundAnimationController);

    _backgroundAnimationController.forward(from: 0);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundColorAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _backgroundColorAnimation.value ??
                      _onboardingData[_currentPage].backgroundColor,
                  _onboardingData[_currentPage].secondaryColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Skip button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Page content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _onboardingData.length,
                      itemBuilder: (context, index) {
                        return OnboardingPage(
                          data: _onboardingData[index],
                          currentPage: _currentPage,
                          pageIndex: index,
                        );
                      },
                    ),
                  ),

                  // Bottom navigation
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Page indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _onboardingData.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: _currentPage == index ? 24 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Navigation buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _currentPage == 0
                                ? const SizedBox(width: 80)
                                : TextButton(
                                    onPressed: () {
                                      _pageController.previousPage(
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    child: Text(
                                      'Back',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                            ElevatedButton(
                              onPressed: () {
                                if (_currentPage ==
                                    _onboardingData.length - 1) {
                                  _completeOnboarding();
                                } else {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _onboardingData[_currentPage]
                                    .backgroundColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text(
                                _currentPage == _onboardingData.length - 1
                                    ? 'Get Started'
                                    : 'Next',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class OnboardingData {
  final String animationAsset;
  final String title;
  final String description;
  final Color backgroundColor;
  final Color secondaryColor;

  OnboardingData({
    required this.animationAsset,
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.secondaryColor,
  });
}

class OnboardingPage extends StatefulWidget {
  final OnboardingData data;
  final int currentPage;
  final int pageIndex;

  const OnboardingPage({
    super.key,
    required this.data,
    required this.currentPage,
    required this.pageIndex,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void didUpdateWidget(OnboardingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPage == widget.pageIndex) {
      _animationController.forward();
    } else {
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getIconForPage(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return Icons.account_balance_wallet;
      case 1:
        return Icons.notifications_active;
      case 2:
        return Icons.analytics;
      default:
        return Icons.payment;
    }
  }

  String _getSubtitleForPage(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return 'Manage Your Finances';
      case 1:
        return 'Smart Reminders';
      case 2:
        return 'Detailed Analytics';
      default:
        return 'PayTrack Features';
    }
  }

  List<String> _getFeaturePoints(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return ['Easy Payment Tracking', 'Secure & Private'];
      case 1:
        return ['Never Miss Deadlines', 'Custom Notifications'];
      case 2:
        return ['Visual Reports', 'Spending Insights'];
      default:
        return ['Feature Rich', 'User Friendly'];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Start animation if this is the current page
    if (widget.currentPage == widget.pageIndex &&
        !_animationController.isAnimating) {
      _animationController.forward();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    height: 320,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Display a beautiful gradient container with icon instead of image
                        Expanded(
                          flex: 3,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Animated icon container
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(
                                        milliseconds: 1000,
                                      ),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: 0.8 + (0.2 * value),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.white
                                                      .withOpacity(0.3),
                                                  blurRadius: 15,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              _getIconForPage(widget.pageIndex),
                                              size: 50,
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    // Feature highlights
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Text(
                                        _getSubtitleForPage(widget.pageIndex),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    // Feature points
                                    ...(_getFeaturePoints(widget.pageIndex).map(
                                      (point) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 12,
                                              color: Colors.white.withOpacity(
                                                0.8,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              point,
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.white.withOpacity(
                                                  0.8,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Display the Lottie animation as accent
                        Expanded(
                          flex: 1,
                          child: Lottie.asset(
                            widget.data.animationAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    widget.data.title,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.data.description,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

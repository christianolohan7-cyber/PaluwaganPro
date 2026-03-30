import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'login_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    const OnboardingPageData(
      title: 'Welcome to PaluwaganPro',
      subtitle:
          'Your trusted platform for rotating savings and credit associations. Save together, grow together.',
      icon: Icons.savings,
      iconColor: Color(0xFF2563EB),
      isFirstScreen: true,
    ),
    const OnboardingPageData(
      title: 'What is Paluwagan?',
      subtitle:
          'Paluwagan is an informal Filipino rotating savings and credit association (ROSCA) where members contribute a fixed amount regularly, and each receives the total pot in turn. Often based on trust among colleagues or friends, it serves as a community-based, interest-free method for accumulating savings or securing a lump sum.\n\n"PaluwaganPro brings this traditional Filipino practice into the digital age, making it easier to manage, track, and maintain trust within your savings groups."',
      icon: Icons.info_outline,
      iconColor: Color(0xFF2563EB),
      isFirstScreen: false,
    ),
    OnboardingPageData(
      title: 'Why Choose PaluwaganPro?',
      features: [
        FeatureItem(
          title: 'Community-Based',
          description:
              'Join paluwagan groups with trusted friends, family, or colleagues',
          icon: Icons.people_alt_outlined,
        ),
        FeatureItem(
          title: 'Transparent Tracking',
          description:
              'Monitor all contributions, payouts, and schedules in real-time',
          icon: Icons.track_changes_outlined,
        ),
        FeatureItem(
          title: 'Interest-Free',
          description:
              'No hidden fees or interest - traditional Filipino savings method',
          icon: Icons.money_off_outlined,
        ),
      ],
      icon: Icons.star_outline,
      iconColor: const Color(0xFF2563EB),
      isFirstScreen: false,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8FAFC),
              const Color(0xFFF1F5F9),
              const Color(0xFFE2E8F0).withOpacity(0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return OnboardingPage(
                          page: _pages[index],
                          availableHeight: constraints.maxHeight,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? colorScheme.primary
                                : colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _navigateToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 4,
                          shadowColor: colorScheme.primary.withOpacity(0.4),
                        ),
                        child: const Text(
                          'GET STARTED',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      '© 2026 PaluwaganPro. Building trust in Filipino communities.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final OnboardingPageData page;
  final double availableHeight;

  const OnboardingPage({
    super.key,
    required this.page,
    required this.availableHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isCompactHeight = availableHeight < 760;
    final topSpacing = page.isFirstScreen
        ? (isCompactHeight ? 24.0 : 40.0) // Reduced from 48/80
        : (isCompactHeight ? 24.0 : 32.0);
    final logoSize = page.isFirstScreen
        ? (isCompactHeight ? 180.0 : 220.0)
        : (isCompactHeight ? 120.0 : 140.0);
    final spacingAfterLogo = page.isFirstScreen
        ? (isCompactHeight ? 32.0 : 48.0) // Reduced from 40/56
        : 24.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: availableHeight * 0.75),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: topSpacing),
              // Logo Section with Vibrant Glow
              Container(
                height: logoSize,
                width: logoSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    // Outer vibrant glow
                    BoxShadow(
                      color: page.iconColor.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                    // Inner bloom
                    BoxShadow(
                      color: page.iconColor.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                    // Standard elevation shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white,
                    width: page.isFirstScreen ? 8 : 6,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white,
                        page.iconColor.withOpacity(0.05),
                      ],
                      stops: const [0.8, 1.0],
                    ),
                    border: Border.all(
                      color: page.iconColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white,
                          child: Icon(
                            page.icon,
                            size: logoSize * 0.45,
                            color: page.iconColor,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: spacingAfterLogo),
              if (page.title.isNotEmpty) ...[
                Text(
                  page.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              if (page.subtitle != null)
                Text(
                  page.subtitle!,
                  style: TextStyle(
                    fontSize: page.isFirstScreen ? 18 : 15,
                    color: const Color(0xFF475569),
                    height: 1.6,
                    fontWeight: page.isFirstScreen ? FontWeight.w500 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (page.features != null) ...[
                const SizedBox(height: 32),
                ...page.features!.map(
                  (feature) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFF1F5F9),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            feature.icon,
                            color: const Color(0xFF2563EB),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                feature.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                feature.description,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: page.isFirstScreen ? 40 : 24),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final List<FeatureItem>? features;
  final bool isFirstScreen;

  const OnboardingPageData({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    this.features,
    required this.isFirstScreen,
  });
}

class FeatureItem {
  final String title;
  final String description;
  final IconData icon;

  const FeatureItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}

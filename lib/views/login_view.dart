import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../utils/ui_utils.dart';
import 'home_view.dart';
import 'signup_view.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      UIUtils.showFloatingBanner(context, 'Please fill in all fields', isError: true);
      return;
    }

    final auth = context.read<AuthViewModel>();

    setState(() {
      _isLoading = true;
    });

    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!success) {
      UIUtils.showFloatingBanner(context, 'Invalid email or password', isError: true);
      return;
    }

    UIUtils.showFloatingBanner(context, 'Logged in successfully!');

    final notifVm = context.read<NotificationViewModel>();
    await notifVm.loadUserNotifications(auth.currentUser!.id);
    await notifVm.startNotificationsStream(auth.currentUser!.id);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(user: auth.currentUser!),
      ),
    );
  }

  // New method to clear fields when returning to login
  void _clearFields() {
    _emailController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8FAFC),
              const Color(0xFFF1F5F9),
              const Color(0xFFE2E8F0).withValues(alpha: 0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Top spacing
                          SizedBox(height: size.height * 0.06),

                          // Logo Section with Vibrant Glow
                          Center(
                            child: Container(
                              height: 140,
                              width: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  // Outer vibrant glow
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.2),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                  ),
                                  // Inner bloom
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                    blurRadius: 15,
                                    spreadRadius: 0,
                                  ),
                                  // Standard elevation shadow
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white,
                                  width: 6,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white,
                                      colorScheme.primary.withValues(alpha: 0.05),
                                    ],
                                    stops: const [0.8, 1.0],
                                  ),
                                  border: Border.all(
                                    color: colorScheme.primary.withValues(alpha: 0.1),
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
                                          Icons.savings_outlined,
                                          size: 70,
                                          color: colorScheme.primary,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Header
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sign in to continue your saving journey.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 28),

                          // Form Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Email Field
                                  _buildInputField(
                                    controller: _emailController,
                                    hint: 'Email Address',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                  ),

                                  const SizedBox(height: 12),

                                  // Password Field
                                  _buildInputField(
                                    controller: _passwordController,
                                    hint: 'Password',
                                    icon: Icons.lock_outlined,
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey.shade400,
                                        size: 18,
                                      ),
                                      onPressed: _togglePasswordVisibility,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        elevation: 3,
                                        shadowColor: colorScheme.primary.withValues(alpha: 0.3),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'LOG IN',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  _clearFields();
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SignUpScreen(),
                                    ),
                                  );
                                  _clearFields();
                                },
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }
}

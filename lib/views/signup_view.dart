import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../utils/ui_utils.dart';
import 'otp_verification_view.dart'; // Import the new OTP screen

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();
  final _gcashNameController = TextEditingController();
  final _gcashNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

  // File paths for ID images
  String? _idFrontPath;
  String? _idBackPath;
  String? _idFrontFilename;
  String? _idBackFilename;
  String? _urcodePath;
  String? _urcodeFilename;

  // UI State
  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _gcashNameController.dispose();
    _gcashNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String imageType) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          if (imageType == 'idFront') {
            _idFrontPath = image.path;
            _idFrontFilename = image.name;
          } else if (imageType == 'idBack') {
            _idBackPath = image.path;
            _idBackFilename = image.name;
          } else if (imageType == 'urcode') {
            _urcodePath = image.path;
            _urcodeFilename = image.name;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showFloatingBanner(context, 'Failed to pick image: $e', isError: true);
      }
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleRepeatPasswordVisibility() {
    setState(() {
      _obscureRepeatPassword = !_obscureRepeatPassword;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_idFrontPath == null || _idBackPath == null) {
      UIUtils.showFloatingBanner(context, 'Please upload both front and back of your ID', isError: true);
      return;
    }

    if (_urcodePath == null) {
      UIUtils.showFloatingBanner(context, 'Please upload your InstaPay QR Code', isError: true);
      return;
    }

    final authVm = context.read<AuthViewModel>();

    setState(() {
      _isLoading = true;
    });

    final user = User(
      id: '',
      fullName: _fullNameController.text.trim(),
      address: _addressController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      email: _emailController.text.trim().toLowerCase(),
      password: _passwordController.text,
      idFrontPath: _idFrontPath!,
      idBackPath: _idBackPath!,
      profilePicture: null,
      bio: null,
      phoneNumber: null,
      gcashName: _gcashNameController.text.trim(),
      gcashNumber: _gcashNumberController.text.trim(),
      urcodePath: _urcodePath,
      createdAt: DateTime.now(),
    );

    final success = await authVm.register(user);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!success) {
      UIUtils.showFloatingBanner(context, authVm.errorMessage ?? 'Registration failed', isError: true);
      return;
    }

    UIUtils.showFloatingBanner(context, 'Registration successful! Please verify your email.');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(email: _emailController.text.trim().toLowerCase()),
      ),
    );
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
              const Color(0xFFE2E8F0).withValues(alpha: 0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Top Bar with Back Button and Branding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: Color(0xFF2563EB),
                        ),
                        children: [
                          TextSpan(text: 'Paluwagan'),
                          TextSpan(
                            text: 'Pro',
                            style: TextStyle(color: Color(0xFFEF4444)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Logo Section (Smaller than Login)
                      Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            // Outer vibrant glow
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.15),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                            // Inner bloom
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                            // Standard elevation shadow
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
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
                                    Icons.person_add_outlined,
                                    size: 45,
                                    color: colorScheme.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Create Account',
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
                              'Join our community of savers today.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader('Personal Information'),
                              _buildCard([
                                _buildInputField(
                                  controller: _fullNameController,
                                  hint: 'Full Name',
                                  icon: Icons.person_outline,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your full name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildInputField(
                                  controller: _addressController,
                                  hint: 'Home Address',
                                  icon: Icons.location_on_outlined,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildInputField(
                                  controller: _ageController,
                                  hint: 'Age',
                                  icon: Icons.calendar_today_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your age';
                                    }
                                    final age = int.tryParse(value.trim());
                                    if (age == null || age <= 0) {
                                      return 'Please enter a valid age';
                                    }
                                    if (age < 18) {
                                      return 'You must be at least 18 years old';
                                    }
                                    return null;
                                  },
                                ),
                              ]),

                              const SizedBox(height: 20),
                              _buildSectionHeader('GCash Information'),
                              _buildCard([
                                _buildInputField(
                                  controller: _gcashNameController,
                                  hint: 'GCash Registered Name',
                                  icon: Icons.account_box_outlined,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your GCash name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildInputField(
                                  controller: _gcashNumberController,
                                  hint: 'GCash Number',
                                  icon: Icons.phone_android_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your GCash number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'InstaPay QR Code',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildUploadZone(
                                  onTap: () => _pickImage('urcode'),
                                  filename: _urcodeFilename,
                                  icon: Icons.qr_code_2_outlined,
                                ),
                              ]),

                              const SizedBox(height: 20),
                              _buildSectionHeader('Account Information'),
                              _buildCard([
                                _buildInputField(
                                  controller: _emailController,
                                  hint: 'Email Address',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                  },                                ),
                                const SizedBox(height: 12),
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
                                  validator: AuthViewModel.validateStrongPassword,
                                ),
                                const SizedBox(height: 12),
                                _buildInputField(
                                  controller: _repeatPasswordController,
                                  hint: 'Confirm Password',
                                  icon: Icons.lock_reset_outlined,
                                  obscureText: _obscureRepeatPassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureRepeatPassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey.shade400,
                                      size: 18,
                                    ),
                                    onPressed: _toggleRepeatPasswordVisibility,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                              ]),

                              const SizedBox(height: 20),
                              _buildSectionHeader('Identity Verification'),
                              _buildCard([
                                const Text(
                                  'Front of ID',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildUploadZone(
                                  onTap: () => _pickImage('idFront'),
                                  filename: _idFrontFilename,
                                  icon: Icons.badge_outlined,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Back of ID',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildUploadZone(
                                  onTap: () => _pickImage('idBack'),
                                  filename: _idBackFilename,
                                  icon: Icons.badge_outlined,
                                ),
                              ]),

                              const SizedBox(height: 32),

                              // Sign Up Button
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
                                          'CREATE ACCOUNT',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Login Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Text(
                                      'Log In',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: Color(0xFF1E293B),
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
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
    String? Function(String?)? validator,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildUploadZone({
    required VoidCallback onTap,
    required String? filename,
    required IconData icon,
  }) {
    final hasFile = filename != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: hasFile ? const Color(0xFFF0F9FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFile ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasFile ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasFile ? Icons.check_circle : icon,
                color: hasFile ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                    hasFile ? filename : 'Choose a file',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: hasFile ? const Color(0xFF0369A1) : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasFile ? filename : 'Tap to upload from gallery',
                    style: TextStyle(
                      fontSize: 11,
                      color: hasFile ? const Color(0xFF0EA5E9) : Colors.grey.shade500,
                      fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!hasFile)
              Icon(Icons.add_circle_outline, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}

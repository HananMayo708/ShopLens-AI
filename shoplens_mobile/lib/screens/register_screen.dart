import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final Map<String, bool> _focused = {
    'username': false,
    'email': false,
    'firstName': false,
    'lastName': false,
    'phone': false,
    'password': false,
    'confirm': false,
  };

  late AnimationController _bgAnimController;
  late Animation<double> _bgAnimation;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
    _bgAnimation =
        CurvedAnimation(parent: _bgAnimController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bgAnimController.dispose();
    super.dispose();
  }

  void _setFocus(String key, bool value) =>
      setState(() => _focused[key] = value);

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userData = {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'password': _passwordController.text,
        'password2': _confirmPasswordController.text,
        'phone': _phoneController.text.isNotEmpty
            ? _phoneController.text.trim()
            : null,
      };
      final success = await authProvider.register(userData);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Welcome ${authProvider.user?.firstName ?? ''}! Account created.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Widget buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required String focusKey,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
    bool optional = false,
  }) {
    final isFocused = _focused[focusKey] ?? false;
    return Focus(
      onFocusChange: (f) => _setFocus(focusKey, f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: isFocused ? Colors.white : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFocused ? AppTheme.primaryColor : Colors.grey.shade200,
            width: isFocused ? 1.8 : 1.0,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.10),
                      blurRadius: 16)
                ]
              : [],
        ),
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: optional ? '$label (optional)' : label,
            hintText: hint,
            labelStyle: GoogleFonts.poppins(
              color: isFocused ? AppTheme.primaryColor : Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(icon,
                  color:
                      isFocused ? AppTheme.primaryColor : Colors.grey.shade500,
                  size: 20),
            ),
            suffixIcon: suffix,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
          validator: validator,
        ),
      ),
    );
  }

  Widget buildSectionLabel(String index, String label) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              index,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: Colors.grey.shade200)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgAnimation,
            builder: (context, _) {
              return Stack(
                children: [
                  Positioned(
                    top: -40 + (_bgAnimation.value * 30),
                    right: -60,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          AppTheme.primaryColor.withOpacity(0.07),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 180 - (_bgAnimation.value * 30),
                    left: -80,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          AppTheme.accentColor.withOpacity(0.05),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  FadeInLeft(
                    duration: const Duration(milliseconds: 400),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.black87,
                              size: 18,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              AppTheme.primaryColor,
                              AppTheme.secondaryColor
                            ]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.shopping_bag_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeInUp(
                    duration: const Duration(milliseconds: 450),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Create ',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.black87,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'Account',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.secondaryColor
                                ]),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join us and start shopping smarter',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    duration: const Duration(milliseconds: 450),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          _StepChip(label: 'Account'),
                          Expanded(
                              child: Container(
                                  height: 1, color: Colors.grey.shade200)),
                          _StepChip(label: 'Personal'),
                          Expanded(
                              child: Container(
                                  height: 1, color: Colors.grey.shade200)),
                          _StepChip(label: 'Security'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 450),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildSectionLabel('1', 'Account Info'),
                          const SizedBox(height: 14),
                          buildField(
                            controller: _usernameController,
                            label: 'Username',
                            icon: Icons.alternate_email_rounded,
                            hint: 'your_username',
                            focusKey: 'username',
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Username is required';
                              if (v.length < 3) return 'At least 3 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          buildField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.mail_outline_rounded,
                            hint: 'you@example.com',
                            focusKey: 'email',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Email is required';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(v)) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          buildSectionLabel('2', 'Personal Info'),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: buildField(
                                  controller: _firstNameController,
                                  label: 'First Name',
                                  icon: Icons.person_outline_rounded,
                                  hint: 'First',
                                  focusKey: 'firstName',
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: buildField(
                                  controller: _lastNameController,
                                  label: 'Last Name',
                                  icon: Icons.person_outline_rounded,
                                  hint: 'Last',
                                  focusKey: 'lastName',
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          buildField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            icon: Icons.phone_outlined,
                            hint: '+1 (000) 000-0000',
                            focusKey: 'phone',
                            keyboardType: TextInputType.phone,
                            optional: true,
                          ),
                          const SizedBox(height: 28),
                          buildSectionLabel('3', 'Security'),
                          const SizedBox(height: 14),
                          buildField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline_rounded,
                            hint: 'Min. 6 characters',
                            focusKey: 'password',
                            obscureText: _obscurePassword,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: (_focused['password'] ?? false)
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade500,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Password is required';
                              if (v.length < 6) return 'At least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          buildField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            icon: Icons.lock_outline_rounded,
                            hint: 'Re-enter password',
                            focusKey: 'confirm',
                            obscureText: _obscureConfirm,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: (_focused['confirm'] ?? false)
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade500,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Please confirm password';
                              if (v != _passwordController.text)
                                return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _PasswordStrengthBar(controller: _passwordController),
                          const SizedBox(height: 24),
                          if (authProvider.error != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        AppTheme.accentColor.withOpacity(0.25)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: AppTheme.accentColor, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      authProvider.error!,
                                      style: GoogleFonts.poppins(
                                          color: AppTheme.accentColor,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: authProvider.isLoading
                                ? Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        AppTheme.primaryColor,
                                        AppTheme.secondaryColor
                                      ]),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5),
                                      ),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: _handleRegister,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          AppTheme.primaryColor,
                                          AppTheme.secondaryColor
                                        ]),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.28),
                                            blurRadius: 20,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Create Account',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Colors.white,
                                                size: 18),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'By creating an account, you agree to our\nTerms of Service and Privacy Policy',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                                height: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600, fontSize: 14),
                                children: [
                                  const TextSpan(
                                      text: 'Already have an account? '),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () => Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const LoginScreen()),
                                      ),
                                      child: Text(
                                        'Sign In',
                                        style: GoogleFonts.poppins(
                                          color: AppTheme.primaryColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
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
    );
  }
}

class _StepChip extends StatelessWidget {
  final String label;
  const _StepChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.20),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppTheme.primaryColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PasswordStrengthBar extends StatefulWidget {
  final TextEditingController controller;
  const _PasswordStrengthBar({required this.controller});

  @override
  State<_PasswordStrengthBar> createState() => _PasswordStrengthBarState();
}

class _PasswordStrengthBarState extends State<_PasswordStrengthBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  int get _strength {
    final p = widget.controller.text;
    if (p.isEmpty) return 0;
    int s = 0;
    if (p.length >= 6) s++;
    if (p.length >= 10) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(p)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final s = _strength;
    if (widget.controller.text.isEmpty) return const SizedBox.shrink();

    final labels = ['Weak', 'Fair', 'Good', 'Strong', 'Excellent'];
    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFFF97316),
      const Color(0xFFEAB308),
      const Color(0xFF22C55E),
      AppTheme.primaryColor,
    ];
    final idx = (s - 1).clamp(0, 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i < s ? colors[idx] : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              'Password strength: ',
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade500, fontSize: 11),
            ),
            Text(
              labels[idx],
              style: GoogleFonts.poppins(
                color: colors[idx],
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

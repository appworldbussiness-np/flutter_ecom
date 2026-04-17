import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/core/constants/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    //final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.08),

              // ── Brand mark ─────────────────────────────────────────
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(height: size.height * 0.03),

              // ── Title ──────────────────────────────────────────────
              Text(
                'Welcome Back',
                style: tt.headlineLarge?.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                'Login to continue shopping',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),

              SizedBox(height: size.height * 0.05),

              // ── Form ───────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: cs.onSurface.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: cs.secondary,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.error),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter email' : null,
                    ),
                    const SizedBox(height: 14),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: cs.onSurface.withOpacity(0.4),
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        filled: true,
                        fillColor: cs.onSurface.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: cs.secondary,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.error),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.length < 6 ? 'Min 6 chars' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Forgot password ────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    if (_emailController.text.isEmpty) return;
                    await auth.resetPassword(_emailController.text);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Reset email sent'),
                          backgroundColor: cs.secondary,
                        ),
                      );
                    }
                  },
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppConstants.forgotPasswordRoute,
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: cs.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Login button ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          try {
                            await auth.login(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(
                                context,
                                AppConstants.homeRoute,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: cs.error,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Divider ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Divider(color: cs.onSurface.withOpacity(0.15)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.4),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: cs.onSurface.withOpacity(0.15)),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Google button ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          try {
                            await auth.googleSignIn();

                            if (!context.mounted) return;

                            Navigator.pushReplacementNamed(
                              context,
                              AppConstants.homeRoute,
                            );
                          } catch (e) {
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Google sign-in failed"),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                            );
                          }
                        },
                  icon: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                  label: Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Register link ──────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, AppConstants.registerRoute),
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.5),
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Register',
                          style: TextStyle(
                            color: cs.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

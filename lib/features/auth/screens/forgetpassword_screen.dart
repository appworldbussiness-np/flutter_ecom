import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    await auth.resetPassword(_emailController.text.trim());

    if (mounted) {
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final size = MediaQuery.of(context).size;

    // Responsive width — centered card on large screens
    final double horizontalPad = size.width > 600
        ? (size.width - 480) / 2
        : size.width * 0.08;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPad),
          child: _emailSent
              ? _buildSuccessState(cs, tt, size)
              : _buildFormState(auth, cs, tt, size),
        ),
      ),
    );
  }

  // ── Form state (before sending) ─────────────────────────────────────────
  Widget _buildFormState(
    AuthProvider auth,
    ColorScheme cs,
    TextTheme tt,
    Size size,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: size.height * 0.04),

        // Icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: cs.secondary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.lock_reset_rounded, color: cs.secondary, size: 28),
        ),

        SizedBox(height: size.height * 0.03),

        // Title
        Text(
          'Forgot Password?',
          style: tt.headlineLarge?.copyWith(color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your registered email and we\'ll send you a link to reset your password.',
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.55),
            height: 1.5,
          ),
        ),

        SizedBox(height: size.height * 0.05),

        // Form
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: 'Enter your email',
              hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.4)),
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
                borderSide: BorderSide(color: cs.secondary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.error, width: 1.5),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your email';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
        ),

        const SizedBox(height: 24),

        // Send button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _sendReset,
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
                    'Send Reset Link',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // Back to login
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: RichText(
              text: TextSpan(
                text: 'Remember your password? ',
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.5),
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: 'Login',
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
    );
  }

  // ── Success state (after sending) ───────────────────────────────────────
  Widget _buildSuccessState(ColorScheme cs, TextTheme tt, Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: size.height * 0.1),

        // Success icon
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: Colors.green,
            size: 44,
          ),
        ),

        const SizedBox(height: 32),

        Text(
          'Check Your Email',
          style: tt.headlineLarge?.copyWith(color: cs.onSurface),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        Text(
          'We sent a password reset link to',
          style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.5)),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 6),

        // Email display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: cs.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _emailController.text.trim(),
            style: TextStyle(
              color: cs.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Check your spam folder if you don\'t see it in your inbox.',
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.4),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: size.height * 0.06),

        // Open email app button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text(
              'Back to Login',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.secondary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Resend
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => setState(() {
              _emailSent = false;
              _emailController.clear();
            }),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Try a different email',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

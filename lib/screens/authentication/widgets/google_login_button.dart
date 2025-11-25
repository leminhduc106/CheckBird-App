import 'package:flutter/material.dart';
import 'package:check_bird/services/authentication.dart';

class GoogleLoginButton extends StatefulWidget {
  const GoogleLoginButton({super.key});

  @override
  State<GoogleLoginButton> createState() => _GoogleLoginButtonState();
}

class _GoogleLoginButtonState extends State<GoogleLoginButton> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final result = await Authentication.signInWithGoogle();
      if (result != null && mounted) {
        // Navigation will be handled by StreamBuilder in WelcomeScreen
        setState(() => _isLoading = false);
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In was cancelled or failed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
        ),
        onPressed: _isLoading ? null : _signInWithGoogle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Image.asset(
                'assets/images/google-logo.png',
                height: 24,
                width: 24,
              ),
            SizedBox(width: width * 0.04),
            Text(
              _isLoading ? "Signing in..." : "Continue with Google",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

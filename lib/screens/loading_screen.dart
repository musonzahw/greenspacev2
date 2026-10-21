import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingScreen extends StatelessWidget {
  final String? logoPath;
  final String loadingText;
  final Color? backgroundColor;
  final Color? indicatorColor;
  final double logoSize;

  const LoadingScreen({
    super.key,
    this.logoPath,
    this.loadingText = 'Loading Greenspace...',
    this.backgroundColor,
    this.indicatorColor,
    this.logoSize = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1B5E20), const Color(0xFF388E3C)]
                : [Colors.white, const Color(0xFFA5D6A7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [const Color(0xFF2E7D32), const Color(0xFF81C784)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Lottie.asset(
                  'assets/multileaf.json',
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                  errorBuilder: (context, error, stackTrace) => _buildLogoPlaceholder(theme),
                ),
              ),
              const SizedBox(height: 30),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(indicatorColor ?? theme.primaryColor),
              ),
              const SizedBox(height: 20),
              Text(
                loadingText,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.green.shade900,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder(ThemeData theme) {
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.eco,
        size: logoSize * 0.6,
        color: theme.primaryColor,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/widgets/pill_button.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsightrColors.bgDark,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, 0.8),
              radius: 1.2,
              colors: [Color(0x38C9A84C), Colors.transparent],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Logo
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: InsightrColors.goldPrimary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(
                          color: InsightrColors.goldPrimary.withAlpha(128),
                          blurRadius: 20, offset: const Offset(0, 4),
                        )],
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Color(0xFF1A1200), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text('Insightr', style: GoogleFonts.inter(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: InsightrColors.textPrimary,
                    )),
                  ]),
                  const Spacer(),
                  // Floating tags + heading
                  _FloatingTag(icon: Icons.videocam_rounded, label: 'Short-form videos'),
                  const SizedBox(height: 20),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 56, fontWeight: FontWeight.w800,
                        letterSpacing: -1.5, height: 1.05,
                        color: InsightrColors.textPrimary,
                      ),
                      children: [
                        const TextSpan(text: 'Knowledge,\n'),
                        TextSpan(
                          text: 'Captured.',
                          style: GoogleFonts.inter(
                            fontSize: 56, fontWeight: FontWeight.w800,
                            letterSpacing: -1.5,
                            color: InsightrColors.goldPrimary,
                            shadows: [Shadow(
                              color: InsightrColors.goldPrimary.withAlpha(102),
                              blurRadius: 40,
                            )],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FloatingTag(icon: Icons.psychology_rounded, label: 'AI-powered recall'),
                  const SizedBox(height: 24),
                  Text(
                    'Turn every reel into structured, searchable\nknowledge — automatically.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16, color: InsightrColors.textSecondary, height: 1.6,
                    ),
                  ),
                  const Spacer(),
                  // CTA
                  SizedBox(
                    width: 280,
                    child: PrimaryButton(
                      label: 'Get Started',
                      icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF1A1200), size: 18),
                      onTap: widget.onComplete,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text.rich(TextSpan(
                    style: GoogleFonts.inter(fontSize: 14, color: InsightrColors.textSecondary),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(text: 'Sign in', style: GoogleFonts.inter(
                        fontSize: 14, color: InsightrColors.goldPrimary, fontWeight: FontWeight.w600,
                      )),
                    ],
                  )),
                  const SizedBox(height: 20),
                  // Dots
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _Dot(active: true), const SizedBox(width: 6),
                    _Dot(active: false), const SizedBox(width: 6),
                    _Dot(active: false),
                  ]),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FloatingTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: InsightrRadii.fullAll,
        border: Border.all(color: const Color(0x1EFFFFFF), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: InsightrColors.textPrimary),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: InsightrColors.textPrimary)),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 20 : 8, height: 8,
      decoration: BoxDecoration(
        color: active ? InsightrColors.goldPrimary : const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(4),
        boxShadow: active ? [BoxShadow(
          color: InsightrColors.goldPrimary.withAlpha(128), blurRadius: 8,
        )] : null,
      ),
    );
  }
}

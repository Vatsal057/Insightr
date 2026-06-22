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
              center: Alignment(0, 0.6),
              radius: 1.3,
              colors: [Color(0x38C9A84C), Colors.transparent],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Logo
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: InsightrColors.goldPrimary,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(
                        color: InsightrColors.goldPrimary.withAlpha(128),
                        blurRadius: 40, offset: const Offset(0, 8),
                      )],
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Color(0xFF1A1200), size: 36),
                  ),
                  const SizedBox(height: 24),
                  Text('Insightr', style: GoogleFonts.inter(
                    fontSize: 32, fontWeight: FontWeight.w800,
                    color: InsightrColors.textPrimary, letterSpacing: -0.5,
                  )),
                  const SizedBox(height: 48),
                  // Main heading
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 44, fontWeight: FontWeight.w800,
                        letterSpacing: -1.5, height: 1.1,
                        color: InsightrColors.textPrimary,
                      ),
                      children: [
                        const TextSpan(text: 'Save a reel.\nGet '),
                        TextSpan(
                          text: 'real notes.',
                          style: TextStyle(
                            color: InsightrColors.goldPrimary,
                            shadows: [Shadow(
                              color: InsightrColors.goldPrimary.withAlpha(80),
                              blurRadius: 30,
                            )],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Paste any Instagram, TikTok, or YouTube reel\nand get structured notes, action items,\nand key takeaways — instantly.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15, color: InsightrColors.textSecondary, height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // How it works — 3 quick steps
                  _StepRow(number: '1', text: 'Paste a reel link'),
                  const SizedBox(height: 12),
                  _StepRow(number: '2', text: 'AI extracts the knowledge'),
                  const SizedBox(height: 12),
                  _StepRow(number: '3', text: 'Get notes, actions & insights'),
                  const Spacer(flex: 3),
                  // CTA
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Get Started',
                      onTap: widget.onComplete,
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;
  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x1AC9A84C),
            border: Border.all(color: const Color(0x33C9A84C), width: 1),
          ),
          child: Center(child: Text(number, style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w700, color: InsightrColors.goldPrimary,
          ))),
        ),
        const SizedBox(width: 14),
        Text(text, style: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w500, color: InsightrColors.textPrimary,
        )),
      ],
    );
  }
}

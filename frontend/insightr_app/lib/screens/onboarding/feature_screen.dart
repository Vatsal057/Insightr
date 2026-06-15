import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/widgets/pill_button.dart';

class FeatureScreen extends StatelessWidget {
  final VoidCallback onContinue;
  const FeatureScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsightrColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 0.85),
            radius: 1.1,
            colors: [Color(0x29C9A84C), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 50),
                // Logo
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: InsightrColors.goldPrimary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Color(0xFF1A1200), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text('Insightr', style: GoogleFonts.inter(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: InsightrColors.textPrimary,
                  )),
                ]),
                const SizedBox(height: 16),
                // Big icon
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x0DFFFFFF),
                    border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
                  ),
                  child: const Icon(Icons.view_agenda_rounded, color: InsightrColors.textPrimary, size: 40),
                ),
                const SizedBox(height: 28),
                // Heading
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(children: [
                    TextSpan(text: 'Every Reel,\n', style: GoogleFonts.inter(
                      fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1,
                      height: 1.1, color: InsightrColors.textPrimary,
                    )),
                    TextSpan(text: 'Structured.', style: GoogleFonts.inter(
                      fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1,
                      height: 1.1, color: InsightrColors.goldPrimary,
                    )),
                  ]),
                ),
                const SizedBox(height: 16),
                Text(
                  'Our AI watches, listens, and organizes — so you never lose a good idea again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 15, color: InsightrColors.textSecondary, height: 1.6),
                ),
                const SizedBox(height: 28),
                // Feature card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0x0AFFFFFF),
                    borderRadius: InsightrRadii.xlAll,
                    border: Border.all(color: const Color(0x14FFFFFF), width: 1),
                  ),
                  child: Column(children: [
                    _FeatureRow(icon: Icons.list_alt_rounded, title: 'Key insights extracted',
                      subtitle: 'Bullet-point takeaways, instantly'),
                    const _Divider(),
                    _FeatureRow(icon: Icons.task_alt_rounded, title: 'Actionable to-dos',
                      subtitle: 'Turn ideas into immediate actions'),
                    const _Divider(),
                    _FeatureRow(icon: Icons.search_rounded, title: 'Instant search',
                      subtitle: 'Find anything you saved'),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, children: [
                      _SmallTag('3 key insights'),
                      _SmallTag('2m saved', grey: true),
                      _SmallTag('Finance', grey: true),
                    ]),
                  ]),
                ),
                const Spacer(),
                SizedBox(width: 240, child: PrimaryButton(label: 'Continue', onTap: onContinue)),
                const SizedBox(height: 16),
                // Dots
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _Dot(active: false), const SizedBox(width: 6),
                  _Dot(active: true), const SizedBox(width: 6),
                  _Dot(active: false),
                ]),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0x0FFFFFFF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: InsightrColors.textSecondary),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
            color: InsightrColors.textPrimary)),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: InsightrColors.textSecondary)),
        ])),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: Color(0x0DFFFFFF));
}

class _SmallTag extends StatelessWidget {
  final String label;
  final bool grey;
  const _SmallTag(this.label, {this.grey = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      decoration: BoxDecoration(
        color: grey ? const Color(0x0FFFFFFF) : const Color(0x1FC9A84C),
        borderRadius: InsightrRadii.fullAll,
        border: Border.all(
          color: grey ? const Color(0x14FFFFFF) : const Color(0x40C9A84C), width: 1,
        ),
      ),
      child: Text(label, style: GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w600,
        color: grey ? InsightrColors.textSecondary : InsightrColors.goldPrimary,
      )),
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
      ),
    );
  }
}

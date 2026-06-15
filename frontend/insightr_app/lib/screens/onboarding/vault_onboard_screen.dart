import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/widgets/pill_button.dart';

class VaultOnboardScreen extends StatelessWidget {
  final VoidCallback onComplete;
  const VaultOnboardScreen({super.key, required this.onComplete});

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.hasSeenOnboardingKey, true);
    onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsightrColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 0.85),
            radius: 1.1,
            colors: [Color(0x24C9A84C), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 50),
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
                  Text('Insightr', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 16),
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x0DFFFFFF),
                    border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: InsightrColors.textPrimary, size: 40),
                ),
                const SizedBox(height: 28),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(children: [
                    TextSpan(text: 'Your Personal\n', style: GoogleFonts.inter(
                      fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.05,
                      color: InsightrColors.textPrimary,
                    )),
                    TextSpan(text: 'Knowledge\nVault.', style: GoogleFonts.inter(
                      fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.05,
                      color: InsightrColors.goldPrimary,
                    )),
                  ]),
                ),
                const SizedBox(height: 16),
                Text(
                  'Everything you learned from a video, organized,\nsearchable, yours forever.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 15, color: InsightrColors.textSecondary, height: 1.6),
                ),
                const SizedBox(height: 28),
                // Vault preview
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0x0AFFFFFF),
                    borderRadius: InsightrRadii.xlAll,
                    border: Border.all(color: const Color(0x14FFFFFF), width: 1),
                  ),
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('My Vault', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                        Row(children: [
                          const Icon(Icons.inventory_2_rounded, size: 12, color: InsightrColors.goldPrimary),
                          const SizedBox(width: 4),
                          Text('24 insights', style: GoogleFonts.inter(
                            fontSize: 13, color: InsightrColors.goldPrimary, fontWeight: FontWeight.w600,
                          )),
                        ]),
                      ]),
                    ),
                    const _VaultRow(title: 'The Attention Economy', tag: 'Psychology', date: 'Today'),
                    const _VaultRow(title: 'How Interest Rates Work', tag: 'Finance', date: 'Yesterday'),
                    const _VaultRow(title: 'Habit Stacking Explained', tag: 'Self-growth', date: '2 days ago'),
                  ]),
                ),
                const SizedBox(height: 40),
                PrimaryButton(label: 'Start Building My Vault', onTap: _complete),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _complete,
                  child: Text('Maybe later', style: GoogleFonts.inter(
                    fontSize: 14, color: InsightrColors.textSecondary,
                  )),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _Dot(active: false), const SizedBox(width: 6),
                  _Dot(active: false), const SizedBox(width: 6),
                  _Dot(active: true),
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

class _VaultRow extends StatelessWidget {
  final String title;
  final String tag;
  final String date;
  const _VaultRow({required this.title, required this.tag, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x0DFFFFFF), width: 1)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.play_arrow_rounded, size: 16, color: InsightrColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(children: [
            _MiniTag(tag),
            const SizedBox(width: 8),
            Text(date, style: GoogleFonts.inter(fontSize: 12, color: InsightrColors.textSecondary)),
          ]),
        ])),
        const Icon(Icons.chevron_right_rounded, size: 14, color: InsightrColors.textMuted),
      ]),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  const _MiniTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0x1FC9A84C),
        borderRadius: InsightrRadii.fullAll,
        border: Border.all(color: const Color(0x40C9A84C), width: 1),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
        color: InsightrColors.goldPrimary)),
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

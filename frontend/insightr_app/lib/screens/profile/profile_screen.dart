import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../settings/settings_screen.dart';
import '../settings/export_screen.dart';
import '../actions/action_items_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsightrColors.bgDark,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Row(children: [
              const Expanded(child: SizedBox()),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                )),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x0AFFFFFF),
                    border: Border.all(color: const Color(0x14FFFFFF), width: 1),
                  ),
                  child: const Icon(Icons.settings_outlined, size: 18, color: InsightrColors.textSecondary),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ── Profile Card ────────────────────────────────────────────────
            Center(child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8A6A30), Color(0xFF5A4020)],
                  ),
                ),
                child: const Icon(Icons.person_rounded, size: 36, color: InsightrColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Text('Sarah', style: GoogleFonts.inter(
                fontSize: 24, fontWeight: FontWeight.w800,
              )),
              const SizedBox(height: 4),
              Text('sarah@example.com', style: GoogleFonts.inter(
                fontSize: 14, color: InsightrColors.textSecondary,
              )),
            ])),
            const SizedBox(height: 24),

            // ── Stats Row ───────────────────────────────────────────────────
            Row(children: [
              _ProfileStat(value: '24', label: 'Insights'),
              const SizedBox(width: 12),
              _ProfileStat(value: '8', label: 'Collections'),
              const SizedBox(width: 12),
              _ProfileStat(value: '47', label: 'Actions'),
            ]),
            const SizedBox(height: 24),

            // ── Quick Actions ────────────────────────────────────────────────
            _SectionLabel('QUICK ACTIONS'),
            _ProfileRow(
              icon: Icons.check_circle_outline_rounded,
              iconColor: InsightrColors.goldPrimary,
              label: 'My Action Items',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const ActionItemsScreen(),
              )),
            ),
            _ProfileRow(
              icon: Icons.upload_rounded,
              iconColor: const Color(0xFF78A8D8),
              label: 'Export My Vault',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const ExportScreen(),
              )),
            ),
            _ProfileRow(
              icon: Icons.share_rounded,
              iconColor: const Color(0xFF5CB870),
              label: 'Share Insightr',
              onTap: () {},
            ),

            const SizedBox(height: 8),

            // ── Account ──────────────────────────────────────────────────────
            _SectionLabel('ACCOUNT'),
            _ProfileRow(
              icon: Icons.settings_rounded,
              iconColor: InsightrColors.goldPrimary,
              label: 'Settings',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              )),
            ),
            _ProfileRow(
              icon: Icons.help_outline_rounded,
              iconColor: InsightrColors.textSecondary,
              label: 'Help & Support',
              onTap: () {},
            ),
            _ProfileRow(
              icon: Icons.privacy_tip_outlined,
              iconColor: InsightrColors.textSecondary,
              label: 'Privacy Policy',
              onTap: () {},
            ),

            const SizedBox(height: 32),
            Center(child: Text('Insightr v1.0.0', style: GoogleFonts.inter(
              fontSize: 12, color: InsightrColors.textMuted,
            ))),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: InsightrRadii.lgAll,
        border: Border.all(color: const Color(0x12FFFFFF), width: 1),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.inter(
          fontSize: 24, fontWeight: FontWeight.w800, color: InsightrColors.goldPrimary,
        )),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(
          fontSize: 11, color: InsightrColors.textSecondary,
        )),
      ]),
    ));
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
      child: Text(text, style: GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w700,
        letterSpacing: 2, color: InsightrColors.textMuted,
      )),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ProfileRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: InsightrRadii.lgAll,
          border: Border.all(color: const Color(0x12FFFFFF), width: 1),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w500,
          ))),
          const Icon(Icons.chevron_right_rounded, size: 16, color: InsightrColors.textMuted),
        ]),
      ),
    );
  }
}

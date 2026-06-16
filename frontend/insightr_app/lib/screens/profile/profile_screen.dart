import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../settings/settings_screen.dart';
import '../settings/export_screen.dart';
import '../actions/action_items_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  int _insightCount = 0;
  int _actionCount = 0;
  int _conceptCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.getFeed(),
        _api.getTodo(),
        _api.getConcepts(),
      ]);
      if (mounted) {
        setState(() {
          _insightCount = (results[0] as List).length;
          _actionCount = (results[1] as List).length;
          _conceptCount = (results[2] as List).length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsightrColors.bgDark,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // ── Header row ─────────────────────────────────────────────────
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

            // ── Avatar ─────────────────────────────────────────────────────
            Center(child: Column(children: [
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8A6A30), Color(0xFF5A4020)],
                  ),
                ),
                child: const Icon(Icons.person_rounded, size: 32, color: InsightrColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Text('My Vault', style: GoogleFonts.inter(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: InsightrColors.textPrimary,
              )),
            ])),
            const SizedBox(height: 20),

            // ── Live stats ────────────────────────────────────────────────
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(color: InsightrColors.goldPrimary, strokeWidth: 2),
              ))
            else
              Row(children: [
                _ProfileStat(value: '$_insightCount', label: 'Insights'),
                const SizedBox(width: 10),
                _ProfileStat(value: '$_actionCount', label: 'Actions'),
                const SizedBox(width: 10),
                _ProfileStat(value: '$_conceptCount', label: 'Concepts'),
              ]),
            const SizedBox(height: 24),

            // ── Quick actions ─────────────────────────────────────────────
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
              label: 'Export Vault as Markdown',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const ExportScreen(),
              )),
            ),

            const SizedBox(height: 8),

            // ── Account ───────────────────────────────────────────────────
            _SectionLabel('APP'),
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
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: InsightrRadii.lgAll,
        border: Border.all(color: const Color(0x12FFFFFF), width: 1),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w800, color: InsightrColors.goldPrimary,
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
      padding: const EdgeInsets.only(top: 20, bottom: 10, left: 4),
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: InsightrRadii.lgAll,
          border: Border.all(color: const Color(0x12FFFFFF), width: 1),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: InsightrColors.textPrimary,
          ))),
          const Icon(Icons.chevron_right_rounded, size: 16, color: InsightrColors.textMuted),
        ]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'export_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsightrColors.bgDark,
      appBar: AppBar(
        backgroundColor: InsightrColors.bgDark,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x12FFFFFF),
              border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 16),
          ),
        ),
        title: Text('Settings', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          Container(
            width: 36, height: 36, margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: InsightrColors.goldPrimary,
            ),
            child: const Icon(Icons.bolt_rounded, color: Color(0xFF1A1200), size: 18),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
        children: [

          // ── DATA ─────────────────────────────────────────────────────────
          _SectionLabel('DATA'),
          _SettingsGroup(children: [
            _SettingsRow(
              icon: Icons.upload_rounded,
              label: 'Export All Data',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const ExportScreen(),
              )),
              isLast: true,
            ),
          ]),

          // ── DANGER ZONE ───────────────────────────────────────────────────
          _SectionLabel('DANGER ZONE'),
          _SettingsGroup(children: [
            _SettingsRow(
              icon: Icons.delete_forever_rounded,
              label: 'Delete All Data',
              isDanger: true,
              isLast: true,
              onTap: () => _showConfirm(
                context,
                title: 'Delete All Data',
                message: 'This will permanently delete your entire vault, all insights, action items, and concepts. This cannot be undone.',
                confirmLabel: 'Delete Everything',
                isDanger: true,
                onConfirm: () {
                  // TODO: implement full data deletion
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data deleted.'), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ),
          ]),

          const SizedBox(height: 32),
          Center(child: Text('Insightr v3.0.0', style: GoogleFonts.inter(
            fontSize: 12, color: InsightrColors.textMuted,
          ))),
        ],
      ),
    );
  }


  void _showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required VoidCallback onConfirm,
    bool isDanger = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1A1A0A),
        shape: RoundedRectangleBorder(borderRadius: InsightrRadii.xlAll),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(message, style: GoogleFonts.inter(
              fontSize: 14, color: InsightrColors.textSecondary, height: 1.6,
            )),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0x0FFFFFFF),
                    borderRadius: InsightrRadii.fullAll,
                    border: Border.all(color: const Color(0x14FFFFFF), width: 1),
                  ),
                  child: Center(child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () { Navigator.pop(context); onConfirm(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDanger ? const Color(0x14E05C4A) : const Color(0x1FC9A84C),
                    borderRadius: InsightrRadii.fullAll,
                    border: Border.all(
                      color: isDanger ? InsightrColors.red : InsightrColors.goldPrimary, width: 1,
                    ),
                  ),
                  child: Center(child: Text(confirmLabel, style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: isDanger ? InsightrColors.red : InsightrColors.goldPrimary,
                  ))),
                ),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10, left: 4),
      child: Text(text, style: GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w700,
        letterSpacing: 2, color: InsightrColors.textMuted,
      )),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: InsightrRadii.lgAll,
        border: Border.all(color: const Color(0x14FFFFFF), width: 1),
      ),
      child: ClipRRect(
        borderRadius: InsightrRadii.lgAll,
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDanger;
  final bool isLast;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.isDanger = false,
    this.isLast = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Color(0x0DFFFFFF), width: 1)),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: isDanger ? InsightrColors.red : InsightrColors.goldPrimary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w500,
            color: isDanger ? InsightrColors.red : InsightrColors.textPrimary,
          ))),
          if (onTap != null)
            Icon(Icons.chevron_right_rounded, size: 16,
              color: isDanger ? InsightrColors.red.withAlpha(128) : InsightrColors.textMuted),
        ]),
      ),
    );
  }
}

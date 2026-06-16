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
  bool _autoProcess = true;

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


          // ── PROCESSING ───────────────────────────────────────────────────
          _SectionLabel('PROCESSING'),
          _SettingsGroup(children: [
            _SwitchRow(
              icon: Icons.auto_awesome_rounded,
              label: 'Auto-process on share',
              value: _autoProcess,
              onChanged: (v) => setState(() => _autoProcess = v),
            ),
          ]),

          // ── DATA ─────────────────────────────────────────────────────────
          _SectionLabel('DATA'),
          _SettingsGroup(children: [
            _SettingsRow(
              icon: Icons.storage_rounded,
              label: 'Storage Used',
              value: '2.4 MB',
              onTap: null,
            ),
            _SettingsRow(
              icon: Icons.upload_rounded,
              label: 'Export All Data',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const ExportScreen(),
              )),
            ),
            _SettingsRow(
              icon: Icons.delete_sweep_rounded,
              label: 'Clear Cache',
              onTap: () => _showConfirm(
                context,
                title: 'Clear Cache',
                message: 'This will clear all locally cached data. Your vault data will not be deleted.',
                confirmLabel: 'Clear',
                onConfirm: () {},
              ),
            ),
          ]),

          // ── DANGER ZONE ───────────────────────────────────────────────────
          _SectionLabel('DANGER ZONE'),
          _SettingsGroup(children: [
            _SettingsRow(
              icon: Icons.delete_forever_rounded,
              label: 'Delete All Data',
              isDanger: true,
              onTap: () => _showConfirm(
                context,
                title: 'Delete All Data',
                message: 'This will permanently delete your entire vault, all insights, action items, and concepts. This cannot be undone.',
                confirmLabel: 'Delete Everything',
                isDanger: true,
                onConfirm: () {},
              ),
            ),
          ]),

          const SizedBox(height: 32),
          Center(child: Text('Insightr v1.0.0', style: GoogleFonts.inter(
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
  final String? value;
  final bool isDanger;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.value,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF), width: 1)),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: isDanger ? InsightrColors.red : InsightrColors.goldPrimary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w500,
            color: isDanger ? InsightrColors.red : InsightrColors.textPrimary,
          ))),
          if (value != null) ...[
            Text(value!, style: GoogleFonts.inter(fontSize: 13, color: InsightrColors.textSecondary)),
            const SizedBox(width: 6),
          ],
          if (onTap != null)
            Icon(Icons.chevron_right_rounded, size: 16,
              color: isDanger ? InsightrColors.red.withAlpha(128) : InsightrColors.textMuted),
        ]),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF), width: 1)),
      ),
      child: Row(children: [
        Icon(icon, size: 20, color: InsightrColors.goldPrimary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w500,
        ))),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: InsightrColors.goldPrimary,
          inactiveThumbColor: InsightrColors.textMuted,
          inactiveTrackColor: const Color(0x14FFFFFF),
        ),
      ]),
    );
  }
}

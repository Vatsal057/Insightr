import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

/// Export screen — only exposes what the backend actually supports:
///   GET /api/export          → full vault as markdown
///   GET /api/export/{id}     → single entry markdown
///   GET /api/export/collection/{name} → collection markdown
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _api = ApiService();
  bool _exporting = false;

  Future<void> _exportVault() async {
    setState(() => _exporting = true);
    try {
      final md = await _api.exportVault();
      if (!mounted) return;
      if (md.isEmpty) {
        _showSnack('Nothing to export yet — add some insights first.');
        return;
      }
      // Copy to clipboard so user can paste into any editor
      await Clipboard.setData(ClipboardData(text: md));
      _showSnack('Vault copied to clipboard as Markdown ✓');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: const Color(0xFF1E1E10),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsightrColors.bgDark,
      appBar: AppBar(
        backgroundColor: InsightrColors.bgDark,
        elevation: 0,
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
        title: Text('Export', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Export your entire vault as structured Markdown — ready to paste into Obsidian, Notion, or any editor.',
            style: GoogleFonts.inter(fontSize: 14, color: InsightrColors.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 24),

          // ── Single export option: Markdown vault ──────────────────────────
          GestureDetector(
            onTap: _exporting ? null : _exportVault,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0x0AFFFFFF),
                borderRadius: InsightrRadii.lgAll,
                border: Border.all(color: const Color(0x14FFFFFF), width: 1),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0x14C9A84C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: InsightrColors.borderGold),
                  ),
                  child: const Icon(Icons.description_rounded, color: InsightrColors.goldPrimary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Full Vault — Markdown', style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700,
                  )),
                  const SizedBox(height: 2),
                  Text('Copies all insights to clipboard as .md', style: GoogleFonts.inter(
                    fontSize: 12, color: InsightrColors.textSecondary,
                  )),
                ])),
                const SizedBox(width: 8),
                if (_exporting)
                  const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: InsightrColors.goldPrimary))
                else
                  const Icon(Icons.copy_rounded, size: 16, color: InsightrColors.textMuted),
              ]),
            ),
          ),

          const SizedBox(height: 20),

          // ── Info box ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x0AC9A84C),
              borderRadius: InsightrRadii.lgAll,
              border: Border.all(color: InsightrColors.borderGold, width: 1),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: InsightrColors.goldMuted),
                const SizedBox(width: 8),
                Text('How it works', style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600, color: InsightrColors.goldMuted,
                )),
              ]),
              const SizedBox(height: 8),
              Text(
                'Each insight is exported as a structured Markdown document with all 12 insight features: summary, action items, implementation plan, claims, tools, and more.\n\nYou can also export a single insight from its detail screen using the share button.',
                style: GoogleFonts.inter(fontSize: 12, color: InsightrColors.textSecondary, height: 1.6),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

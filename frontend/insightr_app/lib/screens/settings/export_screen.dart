import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _api = ApiService();
  bool _exporting = false;
  String? _exportingFormat;

  Future<void> _doExport(String format) async {
    setState(() { _exporting = true; _exportingFormat = format; });
    try {
      await _api.export(format: format);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Exported as $format successfully'),
        backgroundColor: const Color(0xFF1E1E10),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Export failed: $e'),
        backgroundColor: const Color(0xFF1E1E10),
      ));
    } finally {
      setState(() { _exporting = false; _exportingFormat = null; });
    }
  }

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
        title: Text('Export Data', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Choose a format', style: GoogleFonts.inter(
            fontSize: 13, color: InsightrColors.textSecondary,
          )),
          const SizedBox(height: 20),
          _ExportOption(
            icon: Icons.description_rounded,
            iconColor: const Color(0xFF78A8D8),
            title: 'Markdown File',
            subtitle: 'All insights as structured .md files',
            format: 'markdown',
            loading: _exporting && _exportingFormat == 'markdown',
            onTap: () => _doExport('markdown'),
          ),
          _ExportOption(
            icon: Icons.web_rounded,
            iconColor: const Color(0xFFA870C8),
            title: 'Notion Workspace',
            subtitle: 'Export directly to your Notion pages',
            format: 'notion',
            loading: _exporting && _exportingFormat == 'notion',
            onTap: () => _doExport('notion'),
          ),
          _ExportOption(
            icon: Icons.data_object_rounded,
            iconColor: const Color(0xFFD47850),
            title: 'JSON Backup',
            subtitle: 'Full data export in machine-readable format',
            format: 'json',
            loading: _exporting && _exportingFormat == 'json',
            onTap: () => _doExport('json'),
          ),
          _ExportOption(
            icon: Icons.table_chart_rounded,
            iconColor: const Color(0xFF5CB870),
            title: 'CSV Spreadsheet',
            subtitle: 'Open in Excel, Google Sheets, or Numbers',
            format: 'csv',
            loading: _exporting && _exportingFormat == 'csv',
            onTap: () => _doExport('csv'),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x0AC9A84C),
              borderRadius: InsightrRadii.lgAll,
              border: Border.all(color: InsightrColors.borderGold, width: 1),
            ),
            child: Row(children: [
              const Icon(Icons.lock_outline_rounded, size: 16, color: InsightrColors.goldMuted),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Your data never leaves your device without your permission.',
                style: GoogleFonts.inter(fontSize: 12, color: InsightrColors.textSecondary, height: 1.5),
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String format;
  final bool loading;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.format,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: InsightrRadii.lgAll,
          border: Border.all(color: const Color(0x12FFFFFF), width: 1),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: InsightrColors.textSecondary)),
          ])),
          const SizedBox(width: 8),
          if (loading)
            const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: InsightrColors.goldPrimary))
          else
            const Icon(Icons.chevron_right_rounded, size: 16, color: InsightrColors.textMuted),
        ]),
      ),
    );
  }
}

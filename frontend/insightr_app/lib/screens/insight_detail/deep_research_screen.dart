import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class DeepResearchScreen extends StatefulWidget {
  final int entryId;
  const DeepResearchScreen({super.key, required this.entryId});

  @override
  State<DeepResearchScreen> createState() => _DeepResearchScreenState();
}

class _DeepResearchScreenState extends State<DeepResearchScreen> {
  final _api = ApiService();
  String _prompt = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prompt = await _api.getDeepResearchPrompt(widget.entryId);
      if (mounted) setState(() { _prompt = prompt; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _prompt));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Research prompt copied to clipboard!'),
      backgroundColor: Color(0xFF1E1E10),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsightrColors.bgDark,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x12FFFFFF),
                    border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
                  ),
                  child: const Icon(Icons.close_rounded, size: 18),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x1FC9A84C),
                  borderRadius: InsightrRadii.fullAll,
                ),
                child: Text('AI ASSISTANT', style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1.5, color: InsightrColors.goldPrimary,
                )),
              ),
            ]),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Deep Research\nPrompt', style: GoogleFonts.inter(
              fontSize: 32, fontWeight: FontWeight.w800, height: 1.1,
            )),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Copy this pre-engineered prompt into ChatGPT, Claude, or NotebookLM to instantly generate a comprehensive research brief.',
              style: GoogleFonts.inter(fontSize: 14, color: InsightrColors.textSecondary, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),

          // Prompt Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0x0AFFFFFF),
                borderRadius: InsightrRadii.xlAll,
                border: Border.all(color: const Color(0x14FFFFFF), width: 1),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: InsightrColors.goldPrimary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Text(_prompt, style: GoogleFonts.inter(
                        fontSize: 14, color: InsightrColors.textPrimary, height: 1.6,
                      )),
                    ),
            ),
          ),
          
          const SizedBox(height: 24),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(children: [
              GestureDetector(
                onTap: _loading ? null : _copyToClipboard,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [InsightrColors.goldLight, InsightrColors.goldPrimary]),
                    borderRadius: InsightrRadii.fullAll,
                    boxShadow: const [BoxShadow(color: Color(0x59C9A84C), blurRadius: 24, offset: Offset(0, 8))],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.copy_rounded, color: Color(0xFF1A1200), size: 18),
                    const SizedBox(width: 8),
                    Text('Copy Prompt', style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1A1200),
                    )),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

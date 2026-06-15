import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/tag_chip.dart';
import '../../models/concept.dart';
import '../../models/feed_card.dart';
import '../../services/api_service.dart';
import '../insight_detail/insight_detail_screen.dart';

class ConceptDetailScreen extends StatefulWidget {
  final Concept concept;
  const ConceptDetailScreen({super.key, required this.concept});

  @override
  State<ConceptDetailScreen> createState() => _ConceptDetailScreenState();
}

class _ConceptDetailScreenState extends State<ConceptDetailScreen> {
  final _api = ApiService();
  List<FeedCard> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await _api.getConceptEntries(widget.concept.id);
      setState(() { _entries = entries; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.concept;
    return Scaffold(
      backgroundColor: InsightrColors.bgDark,
      appBar: AppBar(
        backgroundColor: InsightrColors.bgDark,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: const Color(0x12FFFFFF),
              border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 16),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
        children: [
          ConceptTagChip(conceptType: c.conceptType),
          const SizedBox(height: 12),
          Text(c.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GoldGlassCard(leftBorderOnly: true, child:
            Text(c.summary, style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: InsightrColors.textPrimary)),
          ),
          const SizedBox(height: 24),
          Text('APPEARS IN', style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: InsightrColors.goldMuted,
          )),
          const SizedBox(height: 10),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: InsightrColors.goldPrimary))
          else
            ..._entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => InsightDetailScreen(entryId: e.id),
                )),
                child: GlassCard(padding: const EdgeInsets.all(14), child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(e.hook, style: GoogleFonts.inter(
                      fontSize: 12, color: InsightrColors.textSecondary,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  const Icon(Icons.chevron_right_rounded, color: InsightrColors.textMuted, size: 16),
                ])),
              ),
            )),
        ],
      ),
    );
  }
}

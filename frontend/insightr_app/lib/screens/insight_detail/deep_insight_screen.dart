import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/tag_chip.dart';
import '../../models/entry.dart';
import 'deep_research_screen.dart';
import 'insight_detail_screen.dart';

class DeepInsightScreen extends StatefulWidget {
  final Entry entry;
  const DeepInsightScreen({super.key, required this.entry});

  @override
  State<DeepInsightScreen> createState() => _DeepInsightScreenState();
}

class _DeepInsightScreenState extends State<DeepInsightScreen> {
  @override
  Widget build(BuildContext context) {
    final deep = widget.entry.zoneDeep;

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
        title: Text('Deep Analysis', style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w600,
        )),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
        children: [

          // ── Stats row ─────────────────────────────────────────────────────
          Row(children: [
            Expanded(child: _MiniStat(label: 'CONCEPTS', value: '${deep.knowledgeCards.length}')),
            const SizedBox(width: 8),
            Expanded(child: _MiniStat(label: 'ARTIFACTS', value: '${deep.referencedArtifacts.length}')),
            const SizedBox(width: 8),
            Expanded(child: _MiniStat(label: 'CONNECTIONS', value: '${deep.connections.length}')),
          ]),
          const SizedBox(height: 16),

          // ── Deep Research Prompt ──────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => DeepResearchScreen(entryId: widget.entry.id),
            )),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x1AC9A84C),
                borderRadius: InsightrRadii.lgAll,
                border: Border.all(color: InsightrColors.borderGold, width: 1),
              ),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: InsightrColors.goldDim,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.search_rounded, color: InsightrColors.goldPrimary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Deep Research Prompt', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: InsightrColors.textPrimary,
                  )),
                  Text('Generate a comprehensive research brief', style: GoogleFonts.inter(
                    fontSize: 12, color: InsightrColors.textSecondary,
                  )),
                ])),
                const Icon(Icons.chevron_right_rounded, color: InsightrColors.goldPrimary, size: 20),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // ── FEATURE 8: Knowledge Cards ────────────────────────────────────
          if (deep.knowledgeCards.isNotEmpty) ...[
            _SectionTitle('KNOWLEDGE CARDS'),
            const SizedBox(height: 10),
            ...deep.knowledgeCards.map((k) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    ConceptTagChip(conceptType: k.conceptType),
                    const SizedBox(width: 8),
                    Expanded(child: Text(k.name, style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: InsightrColors.textPrimary,
                    ))),
                  ]),
                  const SizedBox(height: 8),
                  Text(k.summary, style: GoogleFonts.inter(
                    fontSize: 12, color: InsightrColors.textSecondary, height: 1.5,
                  )),
                ]),
              ),
            )),
            const SizedBox(height: 8),
          ],

          // ── FEATURE 9 (expanded): Referenced Artifacts ────────────────────
          if (deep.referencedArtifacts.isNotEmpty) ...[
            _SectionTitle('REFERENCED ARTIFACTS'),
            const SizedBox(height: 10),
            ...deep.referencedArtifacts.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildArtifactCatalog(r),
            )),
            const SizedBox(height: 8),
          ],

          // ── Related Insights ──────────────────────────────────────────────
          if (deep.connections.isNotEmpty) ...[
            _SectionTitle('RELATED INSIGHTS'),
            const SizedBox(height: 10),
            ...deep.connections.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => InsightDetailScreen(entryId: c.entryId),
                )),
                child: GlassCard(padding: const EdgeInsets.all(14), child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.title, style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700, color: InsightrColors.textPrimary,
                    )),
                    const SizedBox(height: 3),
                    Text(c.reason, style: GoogleFonts.inter(
                      fontSize: 11, color: InsightrColors.textSecondary, height: 1.4,
                    )),
                  ])),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: InsightrColors.goldMuted, size: 16),
                ])),
              ),
            )),
          ],
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.inter(
      fontSize: 10, fontWeight: FontWeight.w700,
      letterSpacing: 1.5, color: InsightrColors.goldMuted,
    ));
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(children: [
        Text(value, style: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w800, color: InsightrColors.goldPrimary,
        )),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w700,
          letterSpacing: 1.0, color: InsightrColors.textSecondary,
        )),
      ]),
    );
  }
}

// ── Artifact Helpers ─────────────────────────────────────────────────────────

IconData _getArtifactIcon(String type) {
  switch (type.toLowerCase()) {
    case 'book':
    case 'guide':
    case 'tutorial':
      return Icons.book_rounded;
    case 'research_paper':
    case 'document':
      return Icons.description_rounded;
    case 'course':
    case 'lecture':
      return Icons.school_rounded;
    case 'movie':
    case 'tv_show':
    case 'video':
      return Icons.movie_rounded;
    case 'podcast':
    case 'interview':
      return Icons.mic_rounded;
    case 'song':
    case 'album':
      return Icons.music_note_rounded;
    case 'presentation':
      return Icons.co_present_rounded;
    case 'framework':
    case 'template':
      return Icons.grid_view_rounded;
    case 'dataset':
      return Icons.storage_rounded;
    case 'tool':
      return Icons.build_rounded;
    case 'link':
      return Icons.link_rounded;
    default:
      return Icons.bookmark_outline_rounded;
  }
}

String _capitalize(String s) {
  if (s.isEmpty) return '';
  return s.split('_').map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
}

Widget _buildArtifactCatalog(ReferencedArtifact r) {
  final valStyle = GoogleFonts.inter(
    fontSize: 12, height: 1.4, color: InsightrColors.textPrimary,
  );

  final properties = <MapEntry<String, Widget>>[
    MapEntry(
      'Type',
      Text(_capitalize(r.type), style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600, color: InsightrColors.goldPrimary,
      )),
    ),
    if (r.description.isNotEmpty)
      MapEntry('Overview', Text(r.description, style: valStyle)),
    if (r.url != null && r.url!.isNotEmpty)
      MapEntry(
        'Source',
        Text(r.url!, style: GoogleFonts.inter(
          fontSize: 11, color: InsightrColors.goldLight, decoration: TextDecoration.underline,
        ), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    if (r.snippet != null && r.snippet!.isNotEmpty)
      MapEntry(
        'Quote',
        Text('"${r.snippet!}"', style: GoogleFonts.inter(
          fontSize: 12, color: InsightrColors.textSecondary, fontStyle: FontStyle.italic,
        )),
      ),
  ];

  return GoldGlassCard(
    leftBorderOnly: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_getArtifactIcon(r.type), color: InsightrColors.goldPrimary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(r.name, style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w800, color: InsightrColors.textPrimary,
              )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(color: InsightrColors.borderGold, height: 1, thickness: 0.5),
        ...properties.asMap().entries.map((e) {
          final prop = e.value;
          final isLast = e.key == properties.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(prop.key, style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: InsightrColors.textSecondary,
                      )),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: prop.value),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(color: InsightrColors.borderGold, height: 1, thickness: 0.5),
            ],
          );
        }),
      ],
    ),
  );
}

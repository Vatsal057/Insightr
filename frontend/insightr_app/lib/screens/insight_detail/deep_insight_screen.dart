import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/tag_chip.dart';
import '../../models/entry.dart';
import 'deep_research_screen.dart';
import 'insight_detail_screen.dart';
import 'topic_map_screen.dart';

class DeepInsightScreen extends StatefulWidget {
  final Entry entry;
  const DeepInsightScreen({super.key, required this.entry});

  @override
  State<DeepInsightScreen> createState() => _DeepInsightScreenState();
}

class _DeepInsightScreenState extends State<DeepInsightScreen> {
  final Set<String> _expanded = {};

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
            Expanded(child: _MiniStat(label: 'CLAIMS', value: '${deep.claims.length}')),
            const SizedBox(width: 8),
            Expanded(child: _MiniStat(label: 'GAPS', value: '${deep.missingContext.length}')),
            const SizedBox(width: 8),
            Expanded(child: _MiniStat(label: 'CONCEPTS', value: '${deep.knowledgeCards.length}')),
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

          // ── FEATURE 11: Effort Estimation (full detail) ───────────────────
          if (deep.effortEstimation != null) ...[
            _SectionTitle('TIME & EFFORT'),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: _EffortBox(
                    icon: Icons.school_rounded,
                    label: 'To Learn',
                    value: deep.effortEstimation!.timeToLearn,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _EffortBox(
                    icon: Icons.build_rounded,
                    label: 'To Implement',
                    value: deep.effortEstimation!.timeToImplement,
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _EffortMeter(
                    label: 'Difficulty',
                    value: deep.effortEstimation!.difficulty,
                    color: _difficultyColor(deep.effortEstimation!.difficulty),
                    valueLabel: _difficultyLabel(deep.effortEstimation!.difficulty),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _EffortMeter(
                    label: 'Effort',
                    value: deep.effortEstimation!.effort,
                    color: InsightrColors.goldPrimary,
                    valueLabel: _effortLabel(deep.effortEstimation!.effort),
                  )),
                ]),
                if (deep.effortEstimation!.difficultyRationale != null &&
                    deep.effortEstimation!.difficultyRationale!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Color(0x0FFFFFFF), height: 1),
                  const SizedBox(height: 10),
                  Text(deep.effortEstimation!.difficultyRationale!, style: GoogleFonts.inter(
                    fontSize: 12, color: InsightrColors.textSecondary, height: 1.5,
                    fontStyle: FontStyle.italic,
                  )),
                ],
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // ── FEATURE 12: What the Creator Did Not Mention ──────────────────
          if (deep.missingContext.isNotEmpty) ...[
            _SectionTitle("WHAT'S MISSING"),
            const SizedBox(height: 10),
            ...deep.missingContext.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(padding: const EdgeInsets.all(14), child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MissingBadge(category: m.category),
                  const SizedBox(width: 10),
                  Expanded(child: Text(m.text, style: GoogleFonts.inter(
                    fontSize: 13, height: 1.5, color: InsightrColors.textPrimary,
                  ))),
                ],
              )),
            )),
            const SizedBox(height: 8),
          ],

          // ── FEATURE 4: Claims Made ────────────────────────────────────────
          if (deep.claims.isNotEmpty) ...[
            _SectionTitle('CLAIMS MADE'),
            const SizedBox(height: 10),
            ...deep.claims.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(padding: const EdgeInsets.all(14), child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClaimBadge(verifiability: c.verifiability),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.claim, style: GoogleFonts.inter(
                      fontSize: 13, height: 1.5, color: InsightrColors.textPrimary,
                    )),
                    if (c.note != null && c.note!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(c.note!, style: GoogleFonts.inter(
                        fontSize: 11, height: 1.4, color: InsightrColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      )),
                    ],
                  ])),
                ],
              )),
            )),
            const SizedBox(height: 8),
          ],

          // ── FEATURE 6: Rabbit Hole ────────────────────────────────────────
          if (deep.rabbitHole != null) ...[
            _SectionTitle('RABBIT HOLE'),
            const SizedBox(height: 10),

            // Topic Map Button
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => TopicMapScreen(
                  centralTopic: deep.topicMap?.mainTopic ?? widget.entry.title,
                  subtopics: deep.topicMap?.subtopics ?? [],
                  adjacentTopics: deep.rabbitHole?.adjacentTopics ?? [],
                ),
              )),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0x0AFFFFFF),
                  borderRadius: InsightrRadii.lgAll,
                  border: Border.all(color: const Color(0x14FFFFFF), width: 1),
                ),
                child: Row(children: [
                  const Icon(Icons.hub_rounded, size: 18, color: InsightrColors.goldPrimary),
                  const SizedBox(width: 12),
                  Expanded(child: Text('View Topic Map', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600,
                  ))),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: InsightrColors.textMuted),
                ]),
              ),
            ),

            _AccordionSection(
              title: 'Follow-Up Questions',
              icon: Icons.help_outline_rounded,
              items: deep.rabbitHole!.followUpQuestions,
              expanded: _expanded.contains('fq'),
              onToggle: () => setState(() => _expanded.contains('fq') ? _expanded.remove('fq') : _expanded.add('fq')),
            ),
            const SizedBox(height: 8),
            _AccordionSection(
              title: 'Knowledge Gaps',
              icon: Icons.warning_amber_rounded,
              items: deep.rabbitHole!.knowledgeGaps,
              expanded: _expanded.contains('kg'),
              onToggle: () => setState(() => _expanded.contains('kg') ? _expanded.remove('kg') : _expanded.add('kg')),
            ),
            const SizedBox(height: 8),
            _AccordionSection(
              title: 'Adjacent Topics',
              icon: Icons.category_rounded,
              items: deep.rabbitHole!.adjacentTopics,
              expanded: _expanded.contains('at'),
              onToggle: () => setState(() => _expanded.contains('at') ? _expanded.remove('at') : _expanded.add('at')),
            ),
            const SizedBox(height: 8),
            _AccordionSection(
              title: 'Advanced Concepts',
              icon: Icons.science_rounded,
              items: deep.rabbitHole!.advancedConcepts,
              expanded: _expanded.contains('ac'),
              onToggle: () => setState(() => _expanded.contains('ac') ? _expanded.remove('ac') : _expanded.add('ac')),
            ),
            const SizedBox(height: 20),
          ],

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
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(padding: const EdgeInsets.all(14), child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConceptTagChip(conceptType: r.type),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.name, style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700, color: InsightrColors.textPrimary,
                    )),
                    const SizedBox(height: 2),
                    if (r.description.isNotEmpty)
                      Text(r.description, style: GoogleFonts.inter(
                        fontSize: 12, color: InsightrColors.textSecondary, height: 1.4,
                      )),
                    if (r.url != null && r.url!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(r.url!, style: GoogleFonts.inter(
                        fontSize: 11, color: InsightrColors.goldMuted,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    if (r.snippet != null && r.snippet!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0x08FFFFFF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('"${r.snippet!}"', style: GoogleFonts.inter(
                          fontSize: 11, color: InsightrColors.textMuted,
                          fontStyle: FontStyle.italic, height: 1.4,
                        )),
                      ),
                    ],
                  ])),
                ],
              )),
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

  static Color _difficultyColor(int d) {
    if (d <= 2) return InsightrColors.green;
    if (d == 3) return InsightrColors.goldPrimary;
    return InsightrColors.red;
  }

  static String _difficultyLabel(int d) => switch (d) {
    1 => 'Trivial',
    2 => 'Easy',
    3 => 'Moderate',
    4 => 'Challenging',
    _ => 'Expert',
  };

  static String _effortLabel(int e) => switch (e) {
    1 => 'Minimal',
    2 => 'Light',
    3 => 'Moderate',
    4 => 'High',
    _ => 'Intense',
  };
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

class _EffortBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _EffortBox({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: InsightrRadii.mdAll,
        border: Border.all(color: const Color(0x0DFFFFFF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 12, color: InsightrColors.goldMuted),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(
            fontSize: 9, fontWeight: FontWeight.w700,
            letterSpacing: 1.0, color: InsightrColors.textMuted,
          )),
        ]),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w700, color: InsightrColors.textPrimary,
        )),
      ]),
    );
  }
}

class _EffortMeter extends StatelessWidget {
  final String label;
  final int value; // 1-5
  final Color color;
  final String valueLabel;
  const _EffortMeter({
    required this.label, required this.value,
    required this.color, required this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: InsightrRadii.mdAll,
        border: Border.all(color: const Color(0x0DFFFFFF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: GoogleFonts.inter(
            fontSize: 9, fontWeight: FontWeight.w700,
            letterSpacing: 1.0, color: InsightrColors.textMuted,
          )),
          Text(valueLabel, style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w700, color: color,
          )),
        ]),
        const SizedBox(height: 8),
        Row(children: List.generate(5, (i) => Expanded(child: Container(
          height: 4,
          margin: EdgeInsets.only(right: i < 4 ? 3 : 0),
          decoration: BoxDecoration(
            color: i < value ? color : const Color(0x12FFFFFF),
            borderRadius: BorderRadius.circular(2),
          ),
        )))),
      ]),
    );
  }
}

class _AccordionSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final bool expanded;
  final VoidCallback onToggle;

  const _AccordionSection({
    required this.title, required this.icon, required this.items,
    required this.expanded, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(icon, size: 16, color: InsightrColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600,
              ))),
              Text('${items.length}', style: GoogleFonts.inter(
                fontSize: 11, color: InsightrColors.textMuted,
              )),
              const SizedBox(width: 6),
              Icon(expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: InsightrColors.textSecondary, size: 18),
            ]),
          ),
        ),
        if (expanded && items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(children: items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(top: 6, right: 8),
                  child: Container(width: 4, height: 4, decoration: const BoxDecoration(
                    color: InsightrColors.goldMuted, shape: BoxShape.circle,
                  ))),
                Expanded(child: Text(item, style: GoogleFonts.inter(
                  fontSize: 13, color: InsightrColors.textSecondary, height: 1.5,
                ))),
              ]),
            )).toList()),
          ),
      ]),
    );
  }
}

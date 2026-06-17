import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/note_block_renderer.dart';
import '../../core/widgets/tag_chip.dart';
import '../../models/action_item.dart';
import '../../models/entry.dart';
import '../../services/api_service.dart';
import 'deep_insight_screen.dart';
import 'topic_map_screen.dart';

class InsightDetailScreen extends StatefulWidget {
  final int entryId;
  const InsightDetailScreen({super.key, required this.entryId});

  @override
  State<InsightDetailScreen> createState() => _InsightDetailScreenState();
}

class _InsightDetailScreenState extends State<InsightDetailScreen> {
  final _api = ApiService();
  Entry? _entry;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entry = await _api.getEntry(widget.entryId);
      setState(() { _entry = entry; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InsightrColors.bgDark,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: InsightrColors.goldPrimary))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final e = _entry!;
    final grab = e.zoneGrab;
    final substance = e.zoneSubstance;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: InsightrColors.bgDark,
          pinned: true,
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
          title: Text('Your Insights', style: GoogleFonts.inter(
            fontSize: 14, color: InsightrColors.textSecondary,
          )),
          actions: [
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: e.sourceUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied!'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                width: 40, height: 40, margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x12FFFFFF),
                  border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
                ),
                child: const Icon(Icons.share_rounded, size: 16, color: InsightrColors.textSecondary),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 8),

              // ── Tags ─────────────────────────────────────────────────────
              Wrap(spacing: 8, runSpacing: 6, children: [
                if (e.field.isNotEmpty) TagChip(label: e.field),
                ...e.tags.take(3).map((t) => TagChip(label: t, variant: TagVariant.grey)),
              ]),
              const SizedBox(height: 16),

              // ── Title ────────────────────────────────────────────────────
              Text(e.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.2)),
              const SizedBox(height: 14),

              // ── Effort pills ─────────────────────────────────────────────
              if (grab.effortPill != null)
                Row(children: [
                  Text('Effort', style: GoogleFonts.inter(
                    fontSize: 13, color: InsightrColors.textSecondary,
                  )),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x1AC9A84C),
                      borderRadius: InsightrRadii.fullAll,
                      border: Border.all(color: InsightrColors.borderGold, width: 1),
                    ),
                    child: Text(
                      grab.effortPill!.label.split('·').last.trim(),
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                        color: InsightrColors.goldPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (grab.effortPill!.timeToLearn.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0x0DFFFFFF),
                        borderRadius: InsightrRadii.fullAll,
                        border: Border.all(color: const Color(0x14FFFFFF), width: 1),
                      ),
                      child: Text(grab.effortPill!.timeToLearn,
                        style: GoogleFonts.inter(fontSize: 12, color: InsightrColors.textSecondary)),
                    ),
                ]),
              const SizedBox(height: 16),

              // ── ZONE 1: DO THIS NOW ───────────────────────────────────────
              if (grab.topAction != null)
                GoldGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: InsightrColors.goldPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF1A1200)),
                    ),
                    const SizedBox(width: 8),
                    Text('DO THIS NOW', style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 1.5, color: InsightrColors.goldPrimary,
                    )),
                  ]),
                  const SizedBox(height: 10),
                  Text(grab.topAction!.text, style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600, height: 1.5,
                    color: InsightrColors.textPrimary,
                  )),
                  if (grab.nextStep.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    RichText(text: TextSpan(children: [
                      TextSpan(text: 'Next step: ', style: GoogleFonts.inter(
                        fontSize: 12, color: InsightrColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      )),
                      TextSpan(text: grab.nextStep, style: GoogleFonts.inter(
                        fontSize: 12, color: InsightrColors.textSecondary,
                      )),
                    ])),
                  ],
                ])),
              const SizedBox(height: 16),

              // ── Core Takeaway ─────────────────────────────────────────────
              if (substance.coreTakeaway != null)
                GoldGlassCard(leftBorderOnly: true, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CORE TAKEAWAY', style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      letterSpacing: 1.5, color: InsightrColors.goldMuted,
                    )),
                    const SizedBox(height: 8),
                    Text(substance.coreTakeaway!.body, style: GoogleFonts.inter(
                      fontSize: 14, height: 1.6, color: InsightrColors.textPrimary,
                    )),
                  ],
                )),
              const SizedBox(height: 16),

              // ── Stats row ─────────────────────────────────────────────────
              if (substance.actionItems.isNotEmpty || substance.implementationPlan.isNotEmpty || substance.toolsResources.isNotEmpty)
                Row(children: [
                  if (substance.actionItems.isNotEmpty) ...[
                    Expanded(child: _StatBox(
                      value: '${substance.actionItems.length}',
                      label: 'Actions',
                    )),
                    const SizedBox(width: 10),
                  ],
                  if (substance.implementationPlan.isNotEmpty) ...[
                    Expanded(child: _StatBox(
                      value: '${substance.implementationPlan.length}',
                      label: 'Steps',
                    )),
                    const SizedBox(width: 10),
                  ],
                  if (substance.toolsResources.isNotEmpty)
                    Expanded(child: _StatBox(
                      value: '${substance.toolsResources.length}',
                      label: 'Tools',
                    )),
                ]),
              if (substance.actionItems.isNotEmpty || substance.implementationPlan.isNotEmpty || substance.toolsResources.isNotEmpty)
                const SizedBox(height: 20),

              // ── Adaptive NoteBlocks ───────────────────────────────────────
              ...substance.noteBlocks.map((b) => NoteBlockRenderer(block: b)),

              // ── Action Items ──────────────────────────────────────────────
              if (substance.actionItems.isNotEmpty) ...[
                const SizedBox(height: 4),
                _ActionItemsSection(items: substance.actionItems),
                const SizedBox(height: 16),
              ],

              // ── Implementation Plan ───────────────────────────────────────
              if (substance.implementationPlan.isNotEmpty &&
                  !substance.noteBlocks.any((b) => b.blockType == 'steps'))
                _ImplementationPlanSection(steps: substance.implementationPlan),

              // ── Key Points (if not covered by note_blocks) ────────────────
              if (substance.keyPoints.isNotEmpty &&
                  !substance.noteBlocks.any((b) =>
                      b.blockType == 'bullets' || b.blockType == 'steps'))
                _KeyPointsSection(keyPoints: substance.keyPoints),

              // ── Tools & Resources ─────────────────────────────────────────
              if (substance.toolsResources.isNotEmpty) ...[
                const SizedBox(height: 4),
                _ToolsSection(tools: substance.toolsResources),
                const SizedBox(height: 16),
              ],

              // ── Topic Map section ─────────────────────────────────────────
              Text('TOPIC MAP', style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1.5, color: InsightrColors.goldMuted,
              )),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TopicMapScreen(
                    centralTopic: _entry!.zoneDeep.topicMap?.mainTopic ?? _entry!.title,
                    subtopics: _entry!.zoneDeep.topicMap?.subtopics ?? _entry!.tags,
                    adjacentTopics: _entry!.zoneDeep.rabbitHole?.adjacentTopics ?? [],
                  ),
                )),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0x0AFFFFFF),
                    borderRadius: InsightrRadii.xlAll,
                    border: Border.all(color: const Color(0x14FFFFFF), width: 1),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0x1AC9A84C),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: InsightrColors.borderGold),
                        ),
                        child: const Icon(Icons.hub_rounded, color: InsightrColors.goldPrimary, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_entry!.zoneDeep.topicMap?.mainTopic ?? _entry!.title,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
                            color: InsightrColors.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${(_entry!.zoneDeep.topicMap?.subtopics.length ?? 0)} subtopics',
                          style: GoogleFonts.inter(fontSize: 12, color: InsightrColors.textSecondary),
                        ),
                      ])),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: InsightrColors.goldMuted),
                    ]),
                    if ((_entry!.zoneDeep.topicMap?.subtopics ?? []).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(spacing: 6, runSpacing: 6, children: (_entry!.zoneDeep.topicMap!.subtopics).take(4).map((s) =>
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0x08FFFFFF),
                            borderRadius: InsightrRadii.fullAll,
                            border: Border.all(color: const Color(0x10FFFFFF)),
                          ),
                          child: Text(s, style: GoogleFonts.inter(fontSize: 10, color: InsightrColors.textMuted)),
                        )
                      ).toList()),
                    ],
                  ]),
                ),
              ),

              // ── FEATURE 12 TEASER: What's missing ────────────────────────
              if (_entry!.zoneDeep.missingContext.isNotEmpty) ...[
                _MissingContextTeaser(
                  items: _entry!.zoneDeep.missingContext.take(2).toList(),
                  total: _entry!.zoneDeep.missingContext.length,
                  onSeeAll: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => DeepInsightScreen(entry: _entry!),
                  )),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 12),

              // ── GO DEEPER ─────────────────────────────────────────────────
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DeepInsightScreen(entry: _entry!),
                )),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 40),
                  decoration: BoxDecoration(
                    borderRadius: InsightrRadii.fullAll,
                    gradient: const LinearGradient(
                      colors: [InsightrColors.goldLight, InsightrColors.goldPrimary],
                    ),
                    boxShadow: [BoxShadow(
                      color: InsightrColors.goldPrimary.withAlpha(89),
                      blurRadius: 32, offset: const Offset(0, 8),
                    )],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.bolt_rounded, color: Color(0xFF1A1200), size: 18),
                    const SizedBox(width: 8),
                    Text('Go Deeper', style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1A1200),
                    )),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
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
      ),
      body: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline_rounded, color: InsightrColors.red, size: 48),
          const SizedBox(height: 16),
          Text('Failed to load insight', style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: InsightrColors.textPrimary,
          )),
          const SizedBox(height: 8),
          Text(_error!, style: GoogleFonts.inter(color: InsightrColors.red, fontSize: 13),
            textAlign: TextAlign.center),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () { setState(() { _loading = true; _error = null; }); _load(); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0x1FC9A84C),
                borderRadius: InsightrRadii.fullAll,
                border: Border.all(color: InsightrColors.borderGold),
              ),
              child: Text('Retry', style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600, color: InsightrColors.goldPrimary,
              )),
            ),
          ),
        ]),
      )),
    );
  }
}

// ─── Action Items Section ────────────────────────────────────────────────────

class _ActionItemsSection extends StatefulWidget {
  final List<ActionItem> items;
  const _ActionItemsSection({required this.items});

  @override
  State<_ActionItemsSection> createState() => _ActionItemsSectionState();
}

class _ActionItemsSectionState extends State<_ActionItemsSection> {
  late final List<bool> _checked;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _checked = widget.items.map((a) => a.done).toList();
  }

  Future<void> _toggle(int i) async {
    final newDone = !_checked[i];
    setState(() => _checked[i] = newDone);
    try {
      await _api.toggleTodo(widget.items[i].id, done: newDone);
    } catch (_) {
      // Revert on failure
      if (mounted) setState(() => _checked[i] = !newDone);
    }
  }

  static const _priorityColors = {
    'now': InsightrColors.goldPrimary,
    'soon': Color(0xFF6A9AD4),
    'someday': InsightrColors.textSecondary,
  };

  static const _priorityLabels = {
    'now': 'NOW',
    'soon': 'SOON',
    'someday': 'LATER',
  };

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: const Color(0x1AC9A84C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: InsightrColors.borderGold),
            ),
            child: const Icon(Icons.checklist_rounded, size: 14, color: InsightrColors.goldPrimary),
          ),
          const SizedBox(width: 10),
          Text('ACTION ITEMS', style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w700,
            letterSpacing: 1.5, color: InsightrColors.goldMuted,
          )),
          const Spacer(),
          Text('${_checked.where((c) => c).length}/${widget.items.length}',
            style: GoogleFonts.inter(fontSize: 12, color: InsightrColors.textMuted)),
        ]),
        const SizedBox(height: 12),
        ...List.generate(widget.items.length, (i) {
          final item = widget.items[i];
          final done = _checked[i];
          final pColor = _priorityColors[item.priority] ?? InsightrColors.textSecondary;
          final pLabel = _priorityLabels[item.priority] ?? item.priority.toUpperCase();
          return GestureDetector(
            onTap: () => _toggle(i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20, height: 20, margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? pColor.withAlpha(50) : const Color(0x0DFFFFFF),
                    border: Border.all(
                      color: done ? pColor : const Color(0x33FFFFFF),
                      width: 1.5,
                    ),
                  ),
                  child: done
                      ? Icon(Icons.check_rounded, size: 11, color: pColor)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.text,
                    style: GoogleFonts.inter(
                      fontSize: 13, height: 1.5,
                      color: done ? InsightrColors.textMuted : InsightrColors.textPrimary,
                      decoration: done ? TextDecoration.lineThrough : null,
                    )),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 7),
                      decoration: BoxDecoration(
                        color: pColor.withAlpha(30),
                        borderRadius: InsightrRadii.fullAll,
                        border: Border.all(color: pColor.withAlpha(80)),
                      ),
                      child: Text(pLabel, style: GoogleFonts.inter(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: pColor, letterSpacing: 0.5,
                      )),
                    ),
                    if (item.timeEstimate != null) ...[
                      const SizedBox(width: 6),
                      Text('· ${item.timeEstimate}', style: GoogleFonts.inter(
                        fontSize: 11, color: InsightrColors.textMuted,
                      )),
                    ],
                  ]),
                ])),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

// ─── Implementation Plan ─────────────────────────────────────────────────────

class _ImplementationPlanSection extends StatelessWidget {
  final List<ImplementationStep> steps;
  const _ImplementationPlanSection({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('IMPLEMENTATION PLAN', style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w700,
            letterSpacing: 1.5, color: InsightrColors.goldMuted,
          )),
          const SizedBox(height: 10),
          ...steps.map((step) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x1FC9A84C),
                  border: Border.all(color: const Color(0x40C9A84C), width: 1),
                ),
                child: Center(child: Text('${step.stepNumber}', style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700, color: InsightrColors.goldPrimary,
                ))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(step.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
                  color: InsightrColors.textPrimary)),
                const SizedBox(height: 2),
                Text(step.description, style: GoogleFonts.inter(
                  fontSize: 12, color: InsightrColors.textSecondary, height: 1.4,
                )),
                if (step.timeEstimate != null) ...[
                  const SizedBox(height: 4),
                  Text(step.timeEstimate!, style: GoogleFonts.inter(
                    fontSize: 11, color: InsightrColors.goldMuted, fontWeight: FontWeight.w600,
                  )),
                ],
              ])),
            ]),
          )),
        ]),
      ),
      const SizedBox(height: 16),
    ]);
  }
}

// ─── Key Points Fallback ─────────────────────────────────────────────────────

class _KeyPointsSection extends StatelessWidget {
  final String keyPoints;
  const _KeyPointsSection({required this.keyPoints});

  @override
  Widget build(BuildContext context) {
    final lines = keyPoints.split('\n').where((l) => l.trim().isNotEmpty).toList();
    // Strip leading markdown bullets if present
    final cleaned = lines.map((l) {
      final t = l.trim();
      if (t.startsWith('- ') || t.startsWith('• ')) return t.substring(2);
      if (t.startsWith('* ')) return t.substring(2);
      return t;
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('KEY POINTS', style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w700,
            letterSpacing: 1.5, color: InsightrColors.goldMuted,
          )),
          const SizedBox(height: 10),
          ...cleaned.map((line) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 10),
                child: Container(
                  width: 4, height: 4,
                  decoration: const BoxDecoration(
                    color: InsightrColors.goldPrimary, shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(child: _RichLine(text: line)),
            ]),
          )),
        ]),
      ),
      const SizedBox(height: 16),
    ]);
  }
}

class _RichLine extends StatelessWidget {
  final String text;
  const _RichLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.inter(
      fontSize: 13, height: 1.5, color: InsightrColors.textSecondary,
    );
    final boldStyle = base.copyWith(
      fontWeight: FontWeight.w700, color: InsightrColors.textPrimary,
    );
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > last) spans.add(TextSpan(text: text.substring(last, match.start), style: base));
      spans.add(TextSpan(text: match.group(1), style: boldStyle));
      last = match.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last), style: base));
    return RichText(text: TextSpan(children: spans.isEmpty ? [TextSpan(text: text, style: base)] : spans));
  }
}

// ─── Tools Section ───────────────────────────────────────────────────────────

class _ToolsSection extends StatelessWidget {
  final List<ToolResource> tools;
  const _ToolsSection({required this.tools});

  static const _typeIcons = {
    'tool': Icons.build_rounded,
    'website': Icons.language_rounded,
    'course': Icons.school_rounded,
    'platform': Icons.apps_rounded,
    'software': Icons.computer_rounded,
    'service': Icons.miscellaneous_services_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TOOLS & RESOURCES', style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w700,
          letterSpacing: 1.5, color: InsightrColors.goldMuted,
        )),
        const SizedBox(height: 10),
        ...tools.map((t) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0x14C9A84C),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x28C9A84C)),
              ),
              child: Icon(
                _typeIcons[t.type] ?? Icons.link_rounded,
                size: 15, color: InsightrColors.goldPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name, style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: InsightrColors.textPrimary,
              )),
              if (t.description.isNotEmpty)
                Text(t.description, style: GoogleFonts.inter(
                  fontSize: 12, color: InsightrColors.textSecondary, height: 1.4,
                )),
              if (t.url != null)
                Text(t.url!, style: GoogleFonts.inter(
                  fontSize: 11, color: InsightrColors.goldMuted,
                ), overflow: TextOverflow.ellipsis, maxLines: 1),
            ])),
          ]),
        )),
      ]),
    );
  }
}

// ─── Stat Box ─────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(children: [
        Text(value, style: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w800, color: InsightrColors.goldPrimary,
        )),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(
          fontSize: 11, color: InsightrColors.textSecondary,
        )),
      ]),
    );
  }
}

// ─── Feature 12 Teaser ───────────────────────────────────────────────────────

class _MissingContextTeaser extends StatelessWidget {
  final List<MissingContext> items;
  final int total;
  final VoidCallback onSeeAll;

  const _MissingContextTeaser({
    required this.items,
    required this.total,
    required this.onSeeAll,
  });

  static const _catColors = <String, Color>{
    'risk':               Color(0xFFE05C4A),
    'limitation':         Color(0xFFD07840),
    'trade_off':          Color(0xFFB8A030),
    'assumption':         Color(0xFF6A9AD4),
    'alternative':        Color(0xFF5C9A6A),
    'additional_context': Color(0xFF8A8AAA),
  };

  static const _catLabels = <String, String>{
    'risk':               'RISK',
    'limitation':         'LIMIT',
    'trade_off':          'TRADE-OFF',
    'assumption':         'ASSUMPTION',
    'alternative':        'ALTERNATIVE',
    'additional_context': 'INFO',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSeeAll,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: InsightrRadii.lgAll,
          border: Border.all(color: const Color(0x14FFFFFF), width: 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.lightbulb_outline_rounded, size: 13, color: InsightrColors.goldMuted),
            const SizedBox(width: 6),
            Text("WHAT'S MISSING", style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.w700,
              letterSpacing: 1.5, color: InsightrColors.goldMuted,
            )),
            const Spacer(),
            if (total > items.length)
              Text('See all $total →', style: GoogleFonts.inter(
                fontSize: 10, color: InsightrColors.goldMuted, fontWeight: FontWeight.w600,
              )),
          ]),
          const SizedBox(height: 10),
          ...items.map((m) {
            final color = _catColors[m.category] ?? InsightrColors.textSecondary;
            final label = _catLabels[m.category] ?? m.category.toUpperCase();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: InsightrRadii.fullAll,
                    border: Border.all(color: color.withAlpha(80)),
                  ),
                  child: Text(label, style: GoogleFonts.inter(
                    fontSize: 8, fontWeight: FontWeight.w800,
                    color: color, letterSpacing: 0.5,
                  )),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(m.text,
                  style: GoogleFonts.inter(
                    fontSize: 12, color: InsightrColors.textSecondary, height: 1.4,
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                )),
              ]),
            );
          }),
        ]),
      ),
    );
  }
}

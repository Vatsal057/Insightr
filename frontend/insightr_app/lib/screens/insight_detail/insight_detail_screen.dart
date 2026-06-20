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
              onTap: () async {
                try {
                  final newFav = !e.isFavorite;
                  final success = await _api.toggleFavorite(e.id, newFav);
                  if (!mounted) return;
                  setState(() {
                    _entry = Entry(
                      id: e.id,
                      title: e.title,
                      sourceUrl: e.sourceUrl,
                      field: e.field,
                      tags: e.tags,
                      contentType: e.contentType,
                      isFavorite: success,
                      isImplementing: e.isImplementing,
                      createdAt: e.createdAt,
                      zoneGrab: e.zoneGrab,
                      zoneSubstance: e.zoneSubstance,
                      zoneDeep: e.zoneDeep,
                    );
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Added to Second Brain favorites!' : 'Removed from favorites'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (err) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update favorite: $err')),
                  );
                }
              },
              child: Container(
                width: 40, height: 40, margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: e.isFavorite ? const Color(0x24C9A84C) : const Color(0x12FFFFFF),
                  border: Border.all(
                    color: e.isFavorite ? InsightrColors.borderGold : const Color(0x1AFFFFFF),
                    width: 1,
                  ),
                ),
                child: Icon(
                  e.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 18,
                  color: e.isFavorite ? InsightrColors.goldPrimary : InsightrColors.textSecondary,
                ),
              ),
            ),
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

              // ── Stats row ─────────────────────────────────────────────────
              if (substance.actionItems.isNotEmpty)
                Row(children: [
                  Expanded(child: _StatBox(
                    value: '${substance.actionItems.length}',
                    label: 'Actions',
                  )),
                ]),
              if (substance.actionItems.isNotEmpty)
                const SizedBox(height: 20),

              // ── Adaptive NoteBlocks ───────────────────────────────────────
              ...substance.noteBlocks.map((b) => NoteBlockRenderer(block: b)),

              // ── Action Items ──────────────────────────────────────────────
              if (substance.actionItems.isNotEmpty) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () async {
                    try {
                      final newImpl = !e.isImplementing;
                      final success = await _api.toggleImplementing(e.id, newImpl);
                      if (!mounted) return;
                      setState(() {
                        _entry = Entry(
                          id: e.id,
                          title: e.title,
                          sourceUrl: e.sourceUrl,
                          field: e.field,
                          tags: e.tags,
                          contentType: e.contentType,
                          isFavorite: e.isFavorite,
                          isImplementing: success,
                          createdAt: e.createdAt,
                          zoneGrab: e.zoneGrab,
                          zoneSubstance: e.zoneSubstance,
                          zoneDeep: e.zoneDeep,
                        );
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Added to your global Actions list!'
                              : 'Removed from global Actions list'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (err) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update: $err')),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: e.isImplementing
                          ? const Color(0x1F4CAF50)
                          : const Color(0x12FFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: e.isImplementing
                            ? const Color(0x8081C784)
                            : const Color(0x1AFFFFFF),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          e.isImplementing ? Icons.task_alt_rounded : Icons.add_task_rounded,
                          size: 18,
                          color: e.isImplementing ? const Color(0xFF81C784) : InsightrColors.goldPrimary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e.isImplementing
                                ? 'Implementing Action Plan'
                                : 'Start Implementing',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: e.isImplementing ? const Color(0xFFE8F5E9) : Colors.white,
                            ),
                          ),
                        ),
                        if (e.isImplementing)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: Color(0xFF81C784),
                          )
                        else
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: Colors.white30,
                          ),
                      ],
                    ),
                  ),
                ),
                _ActionItemsSection(items: substance.actionItems),
                const SizedBox(height: 16),
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

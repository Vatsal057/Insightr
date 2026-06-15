import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/note_block_renderer.dart';
import '../../core/widgets/tag_chip.dart';
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
              onTap: () {},
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
              // Tags
              Wrap(spacing: 8, runSpacing: 6, children: [
                if (e.field.isNotEmpty) TagChip(label: e.field),
                ...e.tags.take(3).map((t) => TagChip(label: t, variant: TagVariant.grey)),
              ]),
              const SizedBox(height: 16),
              // Title
              Text(e.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.2)),
              const SizedBox(height: 14),
              // Effort row
              if (grab.effortPill != null)
                Row(children: [
                  Text('Effort', style: GoogleFonts.inter(fontSize: 13, color: InsightrColors.textSecondary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x1AC9A84C),
                      borderRadius: InsightrRadii.fullAll,
                      border: Border.all(color: InsightrColors.borderGold, width: 1),
                    ),
                    child: Text(
                      grab.effortPill!.label.split('·').first.trim(),
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: InsightrColors.goldPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x0DFFFFFF),
                      borderRadius: InsightrRadii.fullAll,
                      border: Border.all(color: const Color(0x14FFFFFF), width: 1),
                    ),
                    child: Text(
                      grab.effortPill!.timeToLearn,
                      style: GoogleFonts.inter(fontSize: 12, color: InsightrColors.textSecondary),
                    ),
                  ),
                ]),
              const SizedBox(height: 16),

              // ── ZONE 1: DO THIS NOW card ──────────────────────────────────
              if (grab.topAction != null)
                GoldGlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: InsightrColors.goldPrimary, borderRadius: BorderRadius.circular(8)),
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

              // ── ZONE 2: Core Takeaway ─────────────────────────────────────
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

              // Effort stats row
              if (substance.implementationPlan.isNotEmpty)
                Row(children: [
                  Expanded(child: _StatBox(
                    value: '${substance.actionItems.length}',
                    label: 'Actions',
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _StatBox(
                    value: '${substance.implementationPlan.length}',
                    label: 'Steps',
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _StatBox(
                    value: '${substance.toolsResources.length}',
                    label: 'Tools',
                  )),
                ]),
              if (substance.implementationPlan.isNotEmpty) const SizedBox(height: 16),

              // ── Adaptive NoteBlocks ───────────────────────────────────────
              ...substance.noteBlocks.map((b) => NoteBlockRenderer(block: b)),

              // ── Implementation steps (if no steps block) ─────────────────
              if (substance.implementationPlan.isNotEmpty &&
                  !substance.noteBlocks.any((b) => b.blockType == 'steps'))
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('IMPLEMENTATION PLAN', style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      letterSpacing: 1.5, color: InsightrColors.goldMuted,
                    )),
                    const SizedBox(height: 10),
                    ...substance.implementationPlan.map((step) => Padding(
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
                          Text(step.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
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
              if (substance.implementationPlan.isNotEmpty) const SizedBox(height: 16),

              // ── Tools row ─────────────────────────────────────────────────
              if (substance.toolsResources.isNotEmpty) ...[
                Text('TOOLS & RESOURCES', style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1.5, color: InsightrColors.goldMuted,
                )),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: substance.toolsResources
                    .map((t) => ConceptTagChip(conceptType: t.type))
                    .toList()),
                const SizedBox(height: 16),
              ],

              // ── GO DEEPER button ──────────────────────────────────────────
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
    return Center(child: Text('Failed to load: $_error',
      style: GoogleFonts.inter(color: InsightrColors.red)));
  }
}

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

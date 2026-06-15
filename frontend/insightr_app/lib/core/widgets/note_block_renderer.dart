import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/entry.dart';
import '../theme.dart';
import 'glass_card.dart';

/// Adaptive renderer for zone_substance.note_blocks.
/// Switches on block_type and renders the appropriate widget.
class NoteBlockRenderer extends StatelessWidget {
  final NoteBlock block;

  const NoteBlockRenderer({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: switch (block.blockType) {
        'key_insight' => _KeyInsightBlock(block: block),
        'checklist' => _ChecklistBlock(block: block),
        'steps' => _StepsBlock(block: block),
        'bullets' => _BulletsBlock(block: block),
        'stat_row' => _StatRowBlock(block: block),
        'comparison' => _ComparisonBlock(block: block),
        'label_values' => _LabelValuesBlock(block: block),
        'timeline' => _TimelineBlock(block: block),
        'quote' => _QuoteBlock(block: block),
        'code_snippet' => _CodeBlock(block: block),
        _ => _TextBlock(block: block),
      },
    );
  }
}

// ─── Section Title Helper ────────────────────────────────────────────────────

Widget _sectionTitle(String? title) {
  if (title == null || title.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w700,
        letterSpacing: 1.5, color: InsightrColors.goldMuted,
      ),
    ),
  );
}

List<String> _lines(String content) =>
    content.split('\n').where((l) => l.trim().isNotEmpty).toList();

// ─── Block Renderers ─────────────────────────────────────────────────────────

class _KeyInsightBlock extends StatelessWidget {
  final NoteBlock block;
  const _KeyInsightBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    return GoldGlassCard(leftBorderOnly: true, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(block.title ?? 'CORE TAKEAWAY'),
        Text(block.content, style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: InsightrColors.textPrimary, height: 1.6,
        )),
      ],
    ));
  }
}

class _ChecklistBlock extends StatelessWidget {
  final NoteBlock block;
  const _ChecklistBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final items = _lines(block.content);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(block.title ?? 'QUICK WINS'),
          ...items.map((item) => _CheckRow(text: item)),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String text;
  const _CheckRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x265C9A6A),
              border: Border.all(color: const Color(0x665C9A6A), width: 1.5),
            ),
            child: const Icon(Icons.check_rounded, size: 10, color: InsightrColors.green),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _StepsBlock extends StatelessWidget {
  final NoteBlock block;
  const _StepsBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final items = _lines(block.content);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(block.title ?? 'STEPS'),
          ...items.asMap().entries.map((e) => _StepRow(number: e.key + 1, text: e.value)),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;
  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x1FC9A84C),
              border: Border.all(color: const Color(0x40C9A84C), width: 1),
            ),
            child: Center(child: Text('$number', style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w700, color: InsightrColors.goldPrimary,
            ))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _BulletsBlock extends StatelessWidget {
  final NoteBlock block;
  const _BulletsBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final items = _lines(block.content);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(block.title),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 5, right: 8),
                child: Container(width: 4, height: 4, decoration: const BoxDecoration(
                  color: InsightrColors.goldMuted, shape: BoxShape.circle,
                ))),
              Expanded(child: Text(item, style: Theme.of(context).textTheme.bodySmall)),
            ]),
          )),
        ],
      ),
    );
  }
}

class _StatRowBlock extends StatelessWidget {
  final NoteBlock block;
  const _StatRowBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final items = _lines(block.content);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (block.title != null) _sectionTitle(block.title),
      Row(
        children: items.map((item) {
          final parts = item.split('|');
          final value = parts.isNotEmpty ? parts[0].trim() : '';
          final label = parts.length > 1 ? parts[1].trim() : '';
          return Expanded(child: _StatBox(value: value, label: label));
        }).toList(),
      ),
    ]);
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
        ), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _ComparisonBlock extends StatelessWidget {
  final NoteBlock block;
  const _ComparisonBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final lines = _lines(block.content);
    if (lines.isEmpty) return const SizedBox.shrink();
    final headers = lines.first.split('|');
    final rows = lines.skip(1).toList();
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle(block.title),
        Row(children: headers.map((h) => Expanded(child: Text(h.trim(),
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
            color: InsightrColors.goldPrimary)))).toList()),
        const SizedBox(height: 8),
        ...rows.map((row) {
          final cells = row.split('|');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: cells.map((c) => Expanded(child: Text(c.trim(),
              style: Theme.of(context).textTheme.bodySmall))).toList()),
          );
        }),
      ]),
    );
  }
}

class _LabelValuesBlock extends StatelessWidget {
  final NoteBlock block;
  const _LabelValuesBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final items = _lines(block.content);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle(block.title),
        ...items.map((item) {
          final idx = item.indexOf(':');
          final lbl = idx >= 0 ? item.substring(0, idx).trim() : item;
          final val = idx >= 0 ? item.substring(idx + 1).trim() : '';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Text('$lbl: ', style: GoogleFonts.inter(fontSize: 13,
                fontWeight: FontWeight.w600, color: InsightrColors.textSecondary)),
              Expanded(child: Text(val, style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: InsightrColors.textPrimary))),
            ]),
          );
        }),
      ]),
    );
  }
}

class _TimelineBlock extends StatelessWidget {
  final NoteBlock block;
  const _TimelineBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final items = _lines(block.content);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle(block.title),
        ...items.asMap().entries.map((e) {
          final idx = e.value.indexOf(':');
          final lbl = idx >= 0 ? e.value.substring(0, idx).trim() : e.value;
          final desc = idx >= 0 ? e.value.substring(idx + 1).trim() : '';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                Container(width: 10, height: 10, decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: InsightrColors.goldPrimary,
                )),
                if (e.key < items.length - 1)
                  Container(width: 1, height: 32, color: InsightrColors.goldDim),
              ]),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lbl, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                if (desc.isNotEmpty) Text(desc, style: Theme.of(context).textTheme.bodySmall),
              ])),
            ]),
          );
        }),
      ]),
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  final NoteBlock block;
  const _QuoteBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    return GoldGlassCard(leftBorderOnly: true, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(block.title),
        Text('"${block.content}"',
          style: GoogleFonts.inter(fontSize: 14, fontStyle: FontStyle.italic,
            color: InsightrColors.textPrimary, height: 1.6)),
      ],
    ));
  }
}

class _CodeBlock extends StatelessWidget {
  final NoteBlock block;
  const _CodeBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle(block.title ?? 'CODE'),
        Text(block.content, style: GoogleFonts.jetBrainsMono(
          fontSize: 12, color: const Color(0xFFC8C8A0), height: 1.7,
        )),
      ]),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final NoteBlock block;
  const _TextBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(block.title),
      Text(block.content, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

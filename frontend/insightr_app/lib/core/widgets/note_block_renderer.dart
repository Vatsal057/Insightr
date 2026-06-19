import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        'checklist'   => _ChecklistBlock(block: block),
        'steps'       => _StepsBlock(block: block),
        'bullets'     => _BulletsBlock(block: block),
        'stat_row'    => _StatRowBlock(block: block),
        'comparison'  => _ComparisonBlock(block: block),
        'label_values'=> _LabelValuesBlock(block: block),
        'timeline'    => _TimelineBlock(block: block),
        'quote'       => _QuoteBlock(block: block),
        'code_snippet'=> _CodeBlock(block: block),
        _             => _TextBlock(block: block),
      },
    );
  }
}

// ─── Inline Bold Parser ──────────────────────────────────────────────────────
// Parses **bold** markers and renders them as bold spans inline.

TextSpan _parseBold(String text, TextStyle base) {
  final boldStyle = base.copyWith(
    fontWeight: FontWeight.w800,
    color: InsightrColors.white,
  );

  final spans = <InlineSpan>[];
  final regex = RegExp(r'\*\*(.+?)\*\*');
  int last = 0;

  for (final match in regex.allMatches(text)) {
    if (match.start > last) {
      spans.add(TextSpan(text: text.substring(last, match.start), style: base));
    }
    spans.add(TextSpan(text: match.group(1), style: boldStyle));
    last = match.end;
  }

  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: base));
  }

  return TextSpan(children: spans.isEmpty ? [TextSpan(text: text, style: base)] : spans);
}

Widget _richText(String text, TextStyle base) {
  return RichText(text: _parseBold(text, base));
}

// ─── Section Title Helper ────────────────────────────────────────────────────

Widget _sectionTitle(String? title) {
  if (title == null || title.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: _richText(
      title,
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: InsightrColors.goldPrimary,
      ),
    ),
  );
}

List<String> _lines(String content, {String? blockType}) {
  // Graceful fallback for legacy LLM outputs that combined items onto one line separated by '|'
  if (!content.contains('\n') && content.contains('|')) {
    final parts = content.split('|');
    // For stat_row, a single 'value|label' on one line is valid and should not be split into separate items here.
    // If it's a stat_row, we only split if there are multiple stats (e.g. 'val|lbl|val|lbl' -> implies error).
    if (blockType != 'stat_row' || parts.length > 2) {
      return parts.where((l) => l.trim().isNotEmpty).toList();
    }
  }
  return content.split('\n').where((l) => l.trim().isNotEmpty).toList();
}

// ─── Block Renderers ─────────────────────────────────────────────────────────

class _KeyInsightBlock extends StatelessWidget {
  final NoteBlock block;
  const _KeyInsightBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final bodyStyle = GoogleFonts.inter(
      fontSize: 14, height: 1.6, color: InsightrColors.textPrimary,
    );
    return GoldGlassCard(
      leftBorderOnly: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle(block.title),
        _richText(block.content, bodyStyle),
      ]),
    );
  }
}

// ─── Checklist — stateful so checkboxes actually toggle ──────────────────────

class _ChecklistBlock extends StatefulWidget {
  final NoteBlock block;
  const _ChecklistBlock({required this.block});

  @override
  State<_ChecklistBlock> createState() => _ChecklistBlockState();
}

class _ChecklistBlockState extends State<_ChecklistBlock> {
  late final List<bool> _checked;
  late final List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = _lines(widget.block.content, blockType: widget.block.blockType);
    _checked = List.filled(_items.length, false);
  }

  @override
  Widget build(BuildContext context) {
    final itemStyle = GoogleFonts.inter(
      fontSize: 13, height: 1.5, color: InsightrColors.textSecondary,
    );
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle((widget.block.title ?? '').isNotEmpty ? widget.block.title : 'CHECKLIST'),
        ...List.generate(_items.length, (i) {
          final done = _checked[i];
          return GestureDetector(
            onTap: () => setState(() => _checked[i] = !_checked[i]),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? InsightrColors.green.withAlpha(60)
                        : const Color(0x0DFFFFFF),
                    border: Border.all(
                      color: done
                          ? InsightrColors.green
                          : const Color(0x33FFFFFF),
                      width: 1.5,
                    ),
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded, size: 11, color: InsightrColors.green)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: _richText(
                  _items[i],
                  done
                      ? itemStyle.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: InsightrColors.textMuted,
                        )
                      : itemStyle,
                )),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}

// ─── Steps ────────────────────────────────────────────────────────────────────

class _StepsBlock extends StatelessWidget {
  final NoteBlock block;
  const _StepsBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final items = _lines(block.content, blockType: block.blockType);
    final stepStyle = GoogleFonts.inter(
      fontSize: 13, height: 1.5, color: InsightrColors.textSecondary,
    );
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle((block.title ?? '').isNotEmpty ? block.title : null),
        ...items.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x1FC9A84C),
                border: Border.all(color: const Color(0x40C9A84C), width: 1),
              ),
              child: Center(child: Text('${e.key + 1}', style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700, color: InsightrColors.goldPrimary,
              ))),
            ),
            const SizedBox(width: 12),
            Expanded(child: _richText(e.value, stepStyle)),
          ]),
        )),
      ]),
    );
  }
}

// ─── Bullets ─────────────────────────────────────────────────────────────────

class _BulletsBlock extends StatelessWidget {
  final NoteBlock block;
  const _BulletsBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final items = _lines(block.content, blockType: block.blockType);
    final itemStyle = GoogleFonts.inter(
      fontSize: 13, height: 1.5, color: InsightrColors.textSecondary,
    );
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle((block.title ?? '').isNotEmpty ? block.title : null),
        ...items.map((item) => Padding(
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
            Expanded(child: _richText(item, itemStyle)),
          ]),
        )),
      ]),
    );
  }
}

// ─── Stat Row — wraps to 2-column grid when 3+ items to avoid overflow ────────

class _StatRowBlock extends StatelessWidget {
  final NoteBlock block;
  const _StatRowBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final items = _lines(block.content, blockType: block.blockType);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if ((block.title ?? '').isNotEmpty) _sectionTitle(block.title),
      if (items.length <= 2)
        Row(
          children: items.map((item) {
            final parts = item.split('|');
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _StatBox(
                value: parts.isNotEmpty ? parts[0].trim() : '',
                label: parts.length > 1 ? parts[1].trim() : '',
              ),
            ));
          }).toList(),
        )
      else
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: items.map((item) {
            final parts = item.split('|');
            return _StatBox(
              value: parts.isNotEmpty ? parts[0].trim() : '',
              label: parts.length > 1 ? parts[1].trim() : '',
            );
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
    return GoldGlassCard(
      leftBorderOnly: false,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(children: [
        Text(value, style: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w800, color: InsightrColors.goldPrimary,
        ), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, maxLines: 2),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(
          fontSize: 11, color: InsightrColors.textSecondary,
        ), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ─── Comparison ────────────────────────────────────────────────────────────────

class _ComparisonBlock extends StatelessWidget {
  final NoteBlock block;
  const _ComparisonBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final lines = _lines(block.content, blockType: block.blockType);
    if (lines.isEmpty) return const SizedBox.shrink();
    final headers = lines.first.split('|');
    final rows = lines.skip(1).toList();
    final cellStyle = GoogleFonts.inter(
      fontSize: 12, height: 1.4, color: InsightrColors.textSecondary,
    );
    return GoldGlassCard(
      leftBorderOnly: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle((block.title ?? '').isNotEmpty ? block.title : 'COMPARISON'),
        Row(children: headers.map((h) => Expanded(child: Text(h.trim(),
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
            color: InsightrColors.goldPrimary)))).toList()),
        const SizedBox(height: 8),
        const Divider(color: InsightrColors.borderGold, height: 1, thickness: 0.5),
        const SizedBox(height: 8),
        ...rows.asMap().entries.map((e) {
          final cells = e.value.split('|');
          final isLast = e.key == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ...cells.map((c) => Expanded(child: _richText(c.trim(), cellStyle))),
                ]),
              ),
              if (!isLast)
                const Divider(color: InsightrColors.borderGold, height: 1, thickness: 0.5),
            ],
          );
        }),
      ]),
    );
  }
}

// ─── Label Values ─────────────────────────────────────────────────────────────

class _LabelValuesBlock extends StatelessWidget {
  final NoteBlock block;
  const _LabelValuesBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final items = _lines(block.content, blockType: block.blockType);
    final valStyle = GoogleFonts.inter(
      fontSize: 13, height: 1.4, color: InsightrColors.textPrimary,
    );
    return GoldGlassCard(
      leftBorderOnly: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle((block.title ?? '').isNotEmpty ? block.title : 'QUICK FACTS'),
        ...items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          final idx = item.indexOf(':');
          final lbl = idx >= 0 ? item.substring(0, idx).trim() : item;
          final val = idx >= 0 ? item.substring(idx + 1).trim() : '';
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: 100,
                    child: Text(lbl, style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: InsightrColors.goldPrimary, height: 1.4,
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _richText(val, valStyle)),
                ]),
              ),
              if (!isLast)
                const Divider(color: InsightrColors.borderGold, height: 1, thickness: 0.5),
            ],
          );
        }),
      ]),
    );
  }
}

// ─── Timeline ─────────────────────────────────────────────────────────────────

class _TimelineBlock extends StatelessWidget {
  final NoteBlock block;
  const _TimelineBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final items = _lines(block.content, blockType: block.blockType);
    final descStyle = GoogleFonts.inter(
      fontSize: 12, height: 1.4, color: InsightrColors.textSecondary,
    );
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle((block.title ?? '').isNotEmpty ? block.title : null),
        ...items.asMap().entries.map((e) {
          final idx = e.value.indexOf(':');
          final lbl = idx >= 0 ? e.value.substring(0, idx).trim() : e.value;
          final desc = idx >= 0 ? e.value.substring(idx + 1).trim() : '';
          final isLast = e.key == items.length - 1;
          return IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Column(children: [
                Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: InsightrColors.goldPrimary,
                  ),
                ),
                if (!isLast) Expanded(child: Container(
                  width: 1, color: InsightrColors.goldDim,
                )),
                if (isLast) const SizedBox(height: 0),
              ]),
              const SizedBox(width: 12),
              Expanded(child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(lbl, style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: InsightrColors.goldPrimary,
                  )),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    _richText(desc, descStyle),
                  ],
                ]),
              )),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─── Quote ────────────────────────────────────────────────────────────────────

class _QuoteBlock extends StatelessWidget {
  final NoteBlock block;
  const _QuoteBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    return GoldGlassCard(
      leftBorderOnly: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.format_quote_rounded, color: InsightrColors.goldMuted, size: 20),
        const SizedBox(height: 6),
        Text(block.content, style: GoogleFonts.inter(
          fontSize: 15, fontStyle: FontStyle.italic,
          color: InsightrColors.textPrimary, height: 1.7,
          fontWeight: FontWeight.w500,
        )),
      ]),
    );
  }
}

// ─── Code / Snippet — with copy button ───────────────────────────────────────

class _CodeBlock extends StatefulWidget {
  final NoteBlock block;
  const _CodeBlock({required this.block});

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.block.content));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return GoldGlassCard(
      leftBorderOnly: true,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _sectionTitle(
            (widget.block.title ?? '').isNotEmpty ? widget.block.title : 'CODE / TEMPLATE',
          )),
          GestureDetector(
            onTap: _copy,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              decoration: BoxDecoration(
                color: _copied
                    ? InsightrColors.green.withAlpha(40)
                    : const Color(0x0DFFFFFF),
                borderRadius: InsightrRadii.fullAll,
                border: Border.all(
                  color: _copied
                      ? InsightrColors.green.withAlpha(100)
                      : const Color(0x20FFFFFF),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  _copied ? Icons.check_rounded : Icons.copy_rounded,
                  size: 11,
                  color: _copied ? InsightrColors.green : InsightrColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(_copied ? 'Copied!' : 'Copy',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _copied ? InsightrColors.green : InsightrColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  )),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x18000000),
            borderRadius: InsightrRadii.mdAll,
            border: Border.all(color: const Color(0x0AFFFFFF)),
          ),
          child: Text(widget.block.content, style: GoogleFonts.jetBrainsMono(
            fontSize: 12, color: const Color(0xFFC8C8A0), height: 1.7,
          )),
        ),
      ]),
    );
  }
}

// ─── Text ─────────────────────────────────────────────────────────────────────

class _TextBlock extends StatelessWidget {
  final NoteBlock block;
  const _TextBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final bodyStyle = GoogleFonts.inter(
      fontSize: 13, height: 1.65, color: InsightrColors.textSecondary,
    );
    if ((block.title ?? '').isEmpty) {
      return _richText(block.content, bodyStyle);
    }
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle(block.title),
        _richText(block.content, bodyStyle),
      ]),
    );
  }
}

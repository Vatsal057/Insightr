// PHASE 0 PROTOTYPE — Concept Page surface. Not production code.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'mock_data.dart';
import 'proto_common.dart';
import 'proto_entry_detail.dart';

class ProtoConceptPage extends StatelessWidget {
  final int conceptId;
  const ProtoConceptPage({super.key, required this.conceptId});

  @override
  Widget build(BuildContext context) {
    final c = MockGraph.concept(conceptId);
    final related = MockGraph.relatedConcepts(c);
    final entries = MockGraph.entriesFor(c);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Concept')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: InsightrColors.glassGold,
                borderRadius: BorderRadius.circular(InsightrRadii.md),
                border: Border.all(color: InsightrColors.borderGold, width: 0.8),
              ),
              child: Icon(conceptIcon(c.type),
                  color: InsightrColors.goldLight, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: t.titleLarge),
                  Text(c.type, style: t.labelMedium),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),

          ProtoSectionLabel('Definition'),
          ProtoCard(child: Text(c.summary, style: t.bodyMedium)),
          const SizedBox(height: 20),

          // Lightweight scoped neighborhood graph (Task 13.2 stand-in)
          ProtoSectionLabel('Relationship Neighborhood'),
          ProtoCard(
            child: SizedBox(
              height: 130,
              child: _Neighborhood(
                center: c.name,
                neighbors: [for (final r in related) r.name],
              ),
            ),
          ),
          const SizedBox(height: 20),

          ProtoSectionLabel('Related Concepts'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in related)
                ProtoChip(
                  r.name,
                  icon: conceptIcon(r.type),
                  gold: true,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProtoConceptPage(conceptId: r.id))),
                ),
            ],
          ),
          const SizedBox(height: 20),

          ProtoSectionLabel('Related Entries'),
          for (final e in entries) ...[
            ProtoCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProtoEntryDetail(entryId: e.id))),
              child: Row(children: [
                Expanded(child: Text(e.title, style: t.bodyLarge)),
                const Icon(Icons.chevron_right_rounded,
                    color: InsightrColors.textMuted),
              ]),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Renders center node + neighbors as a simple radial sketch (no force-sim).
class _Neighborhood extends StatelessWidget {
  final String center;
  final List<String> neighbors;
  const _Neighborhood({required this.center, required this.neighbors});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final cx = box.maxWidth / 2;
      final cy = box.maxHeight / 2;
      final rx = box.maxWidth * 0.34;
      final ry = box.maxHeight * 0.36;
      final widgets = <Widget>[
        Positioned.fill(
          child: CustomPaint(painter: _EdgePainter(neighbors.length, cx, cy, rx, ry)),
        ),
        Positioned(left: cx - 40, top: cy - 16, child: _node(context, center, gold: true)),
      ];
      for (var i = 0; i < neighbors.length; i++) {
        final angle = (i / neighbors.length) * 2 * math.pi;
        final dx = cx + rx * math.cos(angle) - 32;
        final dy = cy + ry * math.sin(angle) - 14;
        widgets.add(Positioned(left: dx, top: dy, child: _node(context, neighbors[i])));
      }
      return Stack(children: widgets);
    });
  }

  Widget _node(BuildContext context, String label, {bool gold = false}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: gold ? InsightrColors.glassGold : InsightrColors.glassBg2,
        borderRadius: BorderRadius.circular(InsightrRadii.full),
        border: Border.all(
            color: gold ? InsightrColors.borderGold : InsightrColors.glassBorder,
            width: 0.8),
      ),
      child: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: gold ? InsightrColors.goldLight : InsightrColors.textSecondary)),
    );
  }
}

class _EdgePainter extends CustomPainter {
  final int count;
  final double cx, cy, rx, ry;
  _EdgePainter(this.count, this.cx, this.cy, this.rx, this.ry);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = InsightrColors.borderGold
      ..strokeWidth = 1;
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      final dx = cx + rx * math.cos(angle);
      final dy = cy + ry * math.sin(angle);
      canvas.drawLine(Offset(cx, cy), Offset(dx, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter old) => false;
}

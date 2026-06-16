import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/entry.dart';

class TopicMapScreen extends StatefulWidget {
  final String centralTopic;
  final List<String> subtopics;
  final List<String> adjacentTopics; // from rabbit hole

  const TopicMapScreen({
    super.key,
    required this.centralTopic,
    required this.subtopics,
    this.adjacentTopics = const [],
  });

  @override
  State<TopicMapScreen> createState() => _TopicMapScreenState();
}

class _TopicMapScreenState extends State<TopicMapScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  int? _hoveredIndex; // -1 = center, 0+ = satellite

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Combine subtopics + adjacent (deduplicated, capped at 8)
    final allNodes = <String>{...widget.subtopics, ...widget.adjacentTopics}
        .toList()
        .take(8)
        .toList();

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
            child: const Icon(Icons.close_rounded, size: 16),
          ),
        ),
        title: Text('Topic Map', style: GoogleFonts.inter(
          fontSize: 17, fontWeight: FontWeight.w700,
        )),
      ),
      body: Stack(children: [
        // ── Network graph ─────────────────────────────────────────────────
        InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(120),
          minScale: 0.4,
          maxScale: 2.5,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              return LayoutBuilder(builder: (ctx, constraints) {
                return GestureDetector(
                  onTapDown: (details) => _handleTap(details.localPosition, constraints, allNodes),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _TopicMapPainter(
                      centralTopic: widget.centralTopic,
                      nodes: allNodes,
                      progress: Curves.easeOutCubic.transform(_anim.value),
                      hoveredIndex: _hoveredIndex,
                    ),
                  ),
                );
              });
            },
          ),
        ),

        // ── Subtopics list ────────────────────────────────────────────────
        if (allNodes.isNotEmpty)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [InsightrColors.bgDark, Colors.transparent],
                  stops: [0.6, 1.0],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 36),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SUBTOPICS', style: GoogleFonts.inter(
                  fontSize: 9, fontWeight: FontWeight.w700,
                  letterSpacing: 1.5, color: InsightrColors.goldMuted,
                )),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6, children: allNodes.map((t) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x0AFFFFFF),
                    borderRadius: InsightrRadii.fullAll,
                    border: Border.all(color: const Color(0x14FFFFFF), width: 1),
                  ),
                  child: Text(t, style: GoogleFonts.inter(
                    fontSize: 11, color: InsightrColors.textSecondary,
                  )),
                )).toList()),
              ]),
            ),
          ),

        // ── Hint ─────────────────────────────────────────────────────────
        Positioned(
          top: 12, right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x08FFFFFF),
              borderRadius: InsightrRadii.fullAll,
              border: Border.all(color: const Color(0x0CFFFFFF), width: 1),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.pinch_rounded, size: 12, color: InsightrColors.textMuted),
              const SizedBox(width: 5),
              Text('Pinch to zoom', style: GoogleFonts.inter(
                fontSize: 10, color: InsightrColors.textMuted,
              )),
            ]),
          ),
        ),
      ]),
    );
  }

  void _handleTap(Offset pos, BoxConstraints constraints, List<String> nodes) {
    final center = Offset(constraints.maxWidth / 2, constraints.maxHeight * 0.42);
    final radius = min(constraints.maxWidth, constraints.maxHeight) * 0.28;

    // Check center node
    if ((pos - center).distance < 52) {
      setState(() => _hoveredIndex = _hoveredIndex == -1 ? null : -1);
      return;
    }

    // Check satellite nodes
    for (int i = 0; i < nodes.length; i++) {
      final angle = (i * 2 * pi) / nodes.length - pi / 2;
      final r = radius + (i % 3 == 0 ? 24 : i % 3 == 1 ? 0 : -20).toDouble();
      final nodePos = Offset(
        center.dx + r * cos(angle),
        center.dy + r * sin(angle),
      );
      if ((pos - nodePos).distance < 44) {
        setState(() => _hoveredIndex = _hoveredIndex == i ? null : i);
        return;
      }
    }
    setState(() => _hoveredIndex = null);
  }
}

class _TopicMapPainter extends CustomPainter {
  final String centralTopic;
  final List<String> nodes;
  final double progress;
  final int? hoveredIndex;

  _TopicMapPainter({
    required this.centralTopic,
    required this.nodes,
    required this.progress,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) {
      // Draw just the central node
      _drawCenterNode(canvas, Offset(size.width / 2, size.height / 2));
      return;
    }

    final center = Offset(size.width / 2, size.height * 0.42);
    final radius = min(size.width, size.height) * 0.28;

    // Satellite positions
    final positions = List.generate(nodes.length, (i) {
      final angle = (i * 2 * pi) / nodes.length - pi / 2;
      final r = radius + (i % 3 == 0 ? 24 : i % 3 == 1 ? 0 : -20).toDouble();
      return Offset(
        center.dx + r * cos(angle) * progress,
        center.dy + r * sin(angle) * progress,
      );
    });

    // Draw connection lines first (behind nodes)
    for (int i = 0; i < nodes.length; i++) {
      final isHovered = hoveredIndex == i;
      final linePaint = Paint()
        ..color = isHovered
            ? InsightrColors.goldPrimary.withAlpha(120)
            : const Color(0x1AFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 1.5 : 1;

      // Animated: line grows from center outward
      final end = Offset(
        center.dx + (positions[i].dx - center.dx) * progress,
        center.dy + (positions[i].dy - center.dy) * progress,
      );
      canvas.drawLine(center, end, linePaint);
    }

    // Draw satellite nodes
    for (int i = 0; i < nodes.length; i++) {
      final isHovered = hoveredIndex == i;
      final pos = positions[i];
      const nodeRadius = 38.0;

      // Outer glow when hovered
      if (isHovered) {
        final glowPaint = Paint()
          ..color = InsightrColors.goldPrimary.withAlpha(20)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, nodeRadius + 10, glowPaint);
      }

      // Node fill
      final fillPaint = Paint()
        ..color = isHovered
            ? const Color(0x1EC9A84C)
            : const Color(0x0DFFFFFF)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, nodeRadius, fillPaint);

      // Node border
      final borderPaint = Paint()
        ..color = isHovered
            ? InsightrColors.goldPrimary.withAlpha(100)
            : const Color(0x1AFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 1.5 : 1;
      canvas.drawCircle(pos, nodeRadius, borderPaint);

      // Text — wrapped to fit inside circle
      _drawWrappedText(
        canvas,
        nodes[i],
        pos,
        nodeRadius - 6,
        fontSize: 10,
        color: isHovered
            ? InsightrColors.textPrimary
            : const Color(0xFFBBB090),
        bold: isHovered,
      );
    }

    // Draw central node on top
    _drawCenterNode(canvas, center);
  }

  void _drawCenterNode(Canvas canvas, Offset center) {
    const nodeRadius = 50.0;
    final isHovered = hoveredIndex == -1;

    // Glow
    final glowPaint = Paint()
      ..color = InsightrColors.goldPrimary.withAlpha(isHovered ? 60 : 30)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, nodeRadius + 8, glowPaint);

    // Fill
    final fillPaint = Paint()
      ..color = isHovered
          ? InsightrColors.goldLight
          : InsightrColors.goldPrimary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, nodeRadius, fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = InsightrColors.goldLight.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, nodeRadius, borderPaint);

    // Text
    _drawWrappedText(
      canvas,
      centralTopic,
      center,
      nodeRadius - 8,
      fontSize: 11,
      color: const Color(0xFF1A1200),
      bold: true,
    );
  }

  /// Draws text wrapped to fit within a circle of given maxWidth.
  /// Splits into lines that are no wider than maxWidth * 2 (diameter).
  void _drawWrappedText(
    Canvas canvas,
    String text,
    Offset center,
    double maxHalfWidth, {
    required double fontSize,
    required Color color,
    bool bold = false,
  }) {
    final maxWidth = maxHalfWidth * 1.8;
    final words = text.split(' ');
    final lines = <String>[];
    var current = '';

    for (final word in words) {
      final test = current.isEmpty ? word : '$current $word';
      final tp = _measureText(test, fontSize, color, bold);
      if (tp.width > maxWidth && current.isNotEmpty) {
        lines.add(current);
        current = word;
      } else {
        current = test;
      }
    }
    if (current.isNotEmpty) lines.add(current);

    // Cap at 3 lines, add ellipsis if truncated
    if (lines.length > 3) {
      lines.removeRange(3, lines.length);
      lines[2] = '${lines[2]}…';
    }

    final lineHeight = fontSize * 1.3;
    final totalHeight = lines.length * lineHeight;
    var y = center.dy - totalHeight / 2 + lineHeight * 0.1;

    for (final line in lines) {
      final tp = TextPainter(
        text: TextSpan(
          text: line,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: maxWidth + 4);

      tp.paint(canvas, Offset(center.dx - tp.width / 2, y));
      y += lineHeight;
    }
  }

  TextPainter _measureText(String text, double fontSize, Color color, bool bold) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  @override
  bool shouldRepaint(_TopicMapPainter old) =>
      old.progress != progress ||
      old.hoveredIndex != hoveredIndex ||
      old.centralTopic != centralTopic;
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class TopicMapScreen extends StatelessWidget {
  final String centralTopic;
  final List<String> relatedTopics;

  const TopicMapScreen({
    super.key,
    required this.centralTopic,
    required this.relatedTopics,
  });

  @override
  Widget build(BuildContext context) {
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
        title: Text('Topic Map', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: Stack(children: [
        // The interactive network graph
        InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(100),
          minScale: 0.5,
          maxScale: 2.0,
          child: SizedBox.expand(
            child: CustomPaint(
              painter: _NetworkPainter(centralTopic: centralTopic, relatedTopics: relatedTopics),
            ),
          ),
        ),
        
        // Overlay hint
        Positioned(
          bottom: 40, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x0AFFFFFF),
                borderRadius: InsightrRadii.fullAll,
                border: Border.all(color: const Color(0x14FFFFFF), width: 1),
              ),
              child: Text(
                'Pinch to zoom, drag to pan',
                style: GoogleFonts.inter(fontSize: 12, color: InsightrColors.textSecondary),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _NetworkPainter extends CustomPainter {
  final String centralTopic;
  final List<String> relatedTopics;

  _NetworkPainter({required this.centralTopic, required this.relatedTopics});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.35;
    
    final linePaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final centerNodePaint = Paint()
      ..color = const Color(0xE6C9A84C) // 90% gold
      ..style = PaintingStyle.fill;
      
    final centerNodeBorder = Paint()
      ..color = const Color(0x4DC9A84C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final satelliteNodePaint = Paint()
      ..color = const Color(0x0DFFFFFF)
      ..style = PaintingStyle.fill;

    final satelliteNodeBorder = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw lines and satellite nodes
    for (int i = 0; i < relatedTopics.length; i++) {
      final angle = (i * 2 * pi) / relatedTopics.length;
      // Add some slight randomness to radius for an organic look
      final r = radius + (i % 2 == 0 ? 20 : -20); 
      final dx = center.dx + r * cos(angle);
      final dy = center.dy + r * sin(angle);
      final satCenter = Offset(dx, dy);

      // Draw dashed line (simulated by drawing a solid line with low opacity for now)
      canvas.drawLine(center, satCenter, linePaint);

      // Draw satellite node
      canvas.drawCircle(satCenter, 36, satelliteNodePaint);
      canvas.drawCircle(satCenter, 36, satelliteNodeBorder);

      // Draw satellite text
      _drawText(canvas, relatedTopics[i], satCenter, 10, const Color(0xFFF0EAD6));
    }

    // Draw central node
    canvas.drawCircle(center, 48, centerNodePaint);
    canvas.drawCircle(center, 48, centerNodeBorder);
    _drawText(canvas, centralTopic, center, 12, const Color(0xFF1A1500), bold: true);
  }

  void _drawText(Canvas canvas, String text, Offset center, double fontSize, Color color, {bool bold = false}) {
    // Split text into words to wrap
    final words = text.split(' ');
    String line1 = '';
    String line2 = '';
    
    if (words.length > 1) {
      line1 = words.take((words.length / 2).ceil()).join(' ');
      line2 = words.skip((words.length / 2).ceil()).join(' ');
    } else {
      line1 = text;
    }

    final tp1 = TextPainter(
      text: TextSpan(
        text: line1,
        style: GoogleFonts.inter(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    if (line2.isNotEmpty) {
      final tp2 = TextPainter(
        text: TextSpan(
          text: line2,
          style: GoogleFonts.inter(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      tp1.paint(canvas, Offset(center.dx - tp1.width / 2, center.dy - tp1.height));
      tp2.paint(canvas, Offset(center.dx - tp2.width / 2, center.dy));
    } else {
      tp1.paint(canvas, Offset(center.dx - tp1.width / 2, center.dy - tp1.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

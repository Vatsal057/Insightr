import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

enum TagVariant { gold, grey, green, purple, blue }
enum ConceptTagType { framework, book, person, tool, methodology, general }

/// Matches the .tag CSS class — a small rounded pill badge
class TagChip extends StatelessWidget {
  final String label;
  final TagVariant variant;
  final bool small;

  const TagChip({
    super.key,
    required this.label,
    this.variant = TagVariant.gold,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = _colors();
    final vPad = small ? 3.0 : 4.0;
    final hPad = small ? 8.0 : 10.0;
    final fontSize = small ? 10.0 : 11.0;

    return Container(
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: InsightrRadii.fullAll,
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0,
        ),
      ),
    );
  }

  (Color, Color, Color) _colors() {
    return switch (variant) {
      TagVariant.gold => (
          const Color(0x1FC9A84C),
          InsightrColors.goldPrimary,
          const Color(0x40C9A84C),
        ),
      TagVariant.grey => (
          const Color(0x0FFFFFFF),
          InsightrColors.textSecondary,
          const Color(0x14FFFFFF),
        ),
      TagVariant.green => (
          const Color(0x1F5C9A6A),
          InsightrColors.green,
          const Color(0x405C9A6A),
        ),
      TagVariant.purple => (
          const Color(0x1F9A6AD4),
          InsightrColors.tagPurple,
          const Color(0x409A6AD4),
        ),
      TagVariant.blue => (
          const Color(0x1F6A9AD4),
          InsightrColors.tagBlue,
          const Color(0x406A9AD4),
        ),
    };
  }
}

/// Concept type tags from the HTML — maps concept_type strings to colors
class ConceptTagChip extends StatelessWidget {
  final String conceptType;

  const ConceptTagChip({super.key, required this.conceptType});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = _conceptColors();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: InsightrRadii.fullAll,
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        conceptType,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  (Color, Color, Color) _conceptColors() {
    return switch (conceptType.toLowerCase()) {
      'framework' => (
          const Color(0x26B48C3C),
          const Color(0xFFD4A840),
          const Color(0x4DB48C3C),
        ),
      'book' => (
          const Color(0x1F64B482),
          const Color(0xFF5CB870),
          const Color(0x406AB482),
        ),
      'person' => (
          const Color(0x1F7896DC),
          const Color(0xFF7898D8),
          const Color(0x407896DC),
        ),
      'tool' => (
          const Color(0x1FC87850),
          const Color(0xFFD47850),
          const Color(0x40C87850),
        ),
      'methodology' => (
          const Color(0x1FA06EC8),
          const Color(0xFFA870C8),
          const Color(0x40A06EC8),
        ),
      _ => (
          const Color(0x0FFFFFFF),
          InsightrColors.textSecondary,
          const Color(0x14FFFFFF),
        ),
    };
  }
}

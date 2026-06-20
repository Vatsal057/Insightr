// PHASE 0 PROTOTYPE — shared throwaway widgets. Not production code.
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Glass-ish card for the prototype. Intentionally simple.
class ProtoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  const ProtoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(InsightrRadii.lg),
        border: Border.all(
          color: borderColor ?? InsightrColors.glassBorder,
          width: 0.8,
        ),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card);
  }
}

/// A pill chip used for concepts, tags, types.
class ProtoChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool gold;
  final VoidCallback? onTap;
  const ProtoChip(this.label, {super.key, this.icon, this.gold = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = gold ? InsightrColors.goldLight : InsightrColors.textSecondary;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: gold ? InsightrColors.glassGold : InsightrColors.glassBg2,
        borderRadius: BorderRadius.circular(InsightrRadii.full),
        border: Border.all(
          color: gold ? InsightrColors.borderGold : InsightrColors.glassBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: chip);
  }
}

/// Small uppercase section label.
class ProtoSectionLabel extends StatelessWidget {
  final String text;
  const ProtoSectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

IconData conceptIcon(String type) {
  switch (type) {
    case 'framework':
      return Icons.account_tree_rounded;
    case 'tool':
      return Icons.build_rounded;
    case 'methodology':
      return Icons.route_rounded;
    case 'book':
      return Icons.menu_book_rounded;
    case 'person':
      return Icons.person_rounded;
    case 'website':
      return Icons.language_rounded;
    default:
      return Icons.bubble_chart_rounded;
  }
}

IconData artifactIcon(String type) {
  switch (type) {
    case 'book':
      return Icons.menu_book_rounded;
    case 'research_paper':
      return Icons.description_rounded;
    case 'tool':
      return Icons.build_rounded;
    case 'framework':
      return Icons.account_tree_rounded;
    default:
      return Icons.bookmark_rounded;
  }
}

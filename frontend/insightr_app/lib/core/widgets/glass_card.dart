import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

/// Reusable glass-morphic card matching the .card CSS class from the HTML.
/// background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.10);
/// border-radius: 20px; backdrop-filter: blur(12px)
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final double blurStrength;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor,
    this.blurStrength = 12,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? InsightrRadii.xlAll;
    final bg = backgroundColor ?? InsightrColors.glassBg;
    final bc = borderColor ?? InsightrColors.glassBorder;

    Widget card = ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: br,
            border: Border.all(color: bc, width: 1),
          ),
          padding: padding ?? const EdgeInsets.all(18),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }
}

/// Gold-bordered variant — matches .do-now-card and .key-insight-card
class GoldGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool leftBorderOnly;
  final double blurStrength;

  const GoldGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.leftBorderOnly = false,
    this.blurStrength = 12,
  });

  @override
  Widget build(BuildContext context) {
    final radius = leftBorderOnly
        ? const BorderRadius.only(
            topRight: Radius.circular(InsightrRadii.lg),
            bottomRight: Radius.circular(InsightrRadii.lg),
          )
        : InsightrRadii.lgAll;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
        child: Container(
          decoration: BoxDecoration(
            color: InsightrColors.glassGold,
            borderRadius: radius,
            border: leftBorderOnly
                ? const Border(
                    left: BorderSide(color: InsightrColors.goldPrimary, width: 3),
                  )
                : Border.all(color: InsightrColors.borderGold, width: 1),
          ),
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

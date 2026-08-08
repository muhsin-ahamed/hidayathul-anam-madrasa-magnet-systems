import 'package:flutter/material.dart';

class PortalCard extends StatefulWidget {
  const PortalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.isHoverable = true,
    this.color,
    this.border,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool isHoverable;
  final Color? color;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  @override
  State<PortalCard> createState() => _PortalCardState();
}

class _PortalCardState extends State<PortalCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isHover = widget.isHoverable && _isHovered;
    final scale = isHover ? 1.015 : 1.0;
    final isDark = theme.brightness == Brightness.dark;
    final borderAlpha = isHover ? 0.2 : (isDark ? 0.08 : 0.04);
    final borderColor = isHover
        ? colorScheme.primary
        : (isDark ? Colors.white : Colors.black);
    final shadowAlpha = isHover
        ? (isDark ? 0.12 : 0.06)
        : (isDark ? 0.08 : 0.03);
    final shadowBlur = isHover ? 28.0 : 20.0;
    final shadowOffsetY = isHover ? 12.0 : 8.0;

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      transform: Matrix4.diagonal3Values(scale, scale, 1.0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.color ?? theme.cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            widget.border ??
            Border.all(
              color: borderColor.withValues(alpha: borderAlpha),
              width: isHover ? 1.5 : 1.0,
            ),
        boxShadow:
            widget.boxShadow ??
            [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: shadowAlpha),
                blurRadius: shadowBlur,
                offset: Offset(0, shadowOffsetY),
              ),
            ],
      ),
      child: Padding(padding: widget.padding, child: widget.child),
    );

    if (widget.onTap != null) {
      card = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: widget.onTap, child: card),
      );
    } else if (widget.isHoverable) {
      card = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: card,
      );
    }

    return card;
  }
}

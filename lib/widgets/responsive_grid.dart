import 'package:flutter/material.dart';

import 'responsive.dart';

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.desktopColumns = 4,
    this.tabletColumns = 2,
    this.mainAxisExtent = 166,
    this.spacing = 16,
  });

  final List<Widget> children;
  final int desktopColumns;
  final int tabletColumns;
  final double mainAxisExtent;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= AppBreakpoints.desktop
            ? desktopColumns
            : width >= AppBreakpoints.tablet
            ? tabletColumns
            : 1;

        final effectiveExtent = columns == 1
            ? (mainAxisExtent < 172 ? 172.0 : mainAxisExtent)
            : mainAxisExtent;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: effectiveExtent,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

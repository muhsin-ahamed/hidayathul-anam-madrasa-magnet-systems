import 'package:flutter/material.dart';

import 'responsive.dart';

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pagePadding(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(padding, padding, padding, padding + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final titleWidget = Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              );

              if (trailing == null) return titleWidget;

              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 12),
                    trailing!,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleWidget),
                  trailing!,
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

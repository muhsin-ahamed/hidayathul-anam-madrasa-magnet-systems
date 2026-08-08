// widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student_portal/widgets/portal_card.dart';
import 'package:student_portal/widgets/metric_card.dart';
import 'package:student_portal/widgets/status_badge.dart';
import 'package:student_portal/models/models.dart';

void main() {
  testWidgets('PortalCard renders children correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PortalCard(child: Text('Card Content'))),
      ),
    );

    expect(find.text('Card Content'), findsOneWidget);
  });

  testWidgets('MetricCard renders title and value correctly', (tester) async {
    final metric = SummaryMetric(
      title: 'Total Students',
      value: '125',
      icon: Icons.people,
      color: Colors.blue,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MetricCard(metric: metric, subtitle: 'Updated today'),
        ),
      ),
    );

    expect(find.text('Total Students'), findsOneWidget);
    expect(find.text('125'), findsOneWidget);
    expect(find.text('Updated today'), findsOneWidget);
  });

  testWidgets('StatusBadge renders label correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(label: 'Pass', color: Colors.green),
        ),
      ),
    );

    expect(find.text('Pass'), findsOneWidget);
  });
}

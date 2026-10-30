import 'package:brotrachka/widgets/job_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Job card shows listing details and opens on tap',
      (tester) async {
    var opened = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: JobCard(
          title: 'Event assistant',
          description: 'Help prepare a venue for an event.',
          payment: 2500,
          requirements: 'Available on Saturday',
          jobType: 'Temporary',
          postedAt: DateTime(2024, 10, 8),
          onTap: () => opened = true,
        ),
      ),
    ));

    expect(find.text('Event assistant'), findsOneWidget);
    expect(find.text('₽2500'), findsOneWidget);
    expect(find.textContaining('Available on Saturday'), findsOneWidget);
    await tester.tap(find.text('Event assistant'));
    expect(opened, isTrue);
  });
}

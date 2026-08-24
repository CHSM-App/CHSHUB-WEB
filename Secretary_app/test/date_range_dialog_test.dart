import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:secretary_app/widgets/date_range_dialog.dart';

/// Opens the dialog over a bare page and hands back the range it returns.
Future<DateTimeRange?> _open(
  WidgetTester tester, {
  required DateTimeRange initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  DateTimeRange? result;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showDateRangeDialog(
                  context: context,
                  initial: initial,
                  firstDate: firstDate,
                  lastDate: lastDate,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

/// Taps a day in the month grid. The header carries dates too, so the search
/// is narrowed to the tappable cells.
Future<void> _tapDay(WidgetTester tester, String day) async {
  await tester.tap(
    find.descendant(of: find.byType(InkWell), matching: find.text(day)).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  final march = DateTimeRange(
    start: DateTime(2026, 3, 10),
    end: DateTime(2026, 3, 20),
  );

  testWidgets('opens on the month the range starts in', (tester) async {
    await _open(tester, initial: march);
    expect(find.text('March 2026'), findsOneWidget);
  });

  testWidgets('shows the range it was given', (tester) async {
    await _open(tester, initial: march);
    expect(find.text('10 Mar 2026  —  20 Mar 2026'), findsOneWidget);
  });

  testWidgets('the first tap on a complete range starts a new one', (
    tester,
  ) async {
    await _open(tester, initial: march);
    await _tapDay(tester, '5');

    // Half a range: the prompt asks for the end, and Apply cannot commit yet.
    expect(find.text('Pick the end date'), findsOneWidget);
    expect(find.text('5 Mar 2026'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton).last).onPressed,
      isNull,
    );
  });

  testWidgets('a second tap closes the range and Apply returns it', (
    tester,
  ) async {
    // The helper returns before the dialog closes, so the range is read off
    // the same variable the button assigns — hence the explicit holder here.
    DateTimeRange? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  picked = await showDateRangeDialog(
                    context: context,
                    initial: march,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await _tapDay(tester, '5');
    await _tapDay(tester, '18');

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.start, DateTime(2026, 3, 5));
    expect(picked!.end, DateTime(2026, 3, 18));
  });

  testWidgets('tapping backwards swaps the ends rather than refusing', (
    tester,
  ) async {
    await _open(tester, initial: march);

    // Start at the 20th, then pick a day before it.
    await _tapDay(tester, '20');
    await _tapDay(tester, '8');

    expect(find.text('8 Mar 2026  —  20 Mar 2026'), findsOneWidget);
  });

  testWidgets('cancelling returns null so the caller keeps its range', (
    tester,
  ) async {
    final result = await _open(tester, initial: march);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  group('single date', () {
    Future<DateTime?> openSingle(
      WidgetTester tester, {
      DateTime? initial,
      DateTime? firstDate,
      DateTime? lastDate,
    }) async {
      DateTime? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    picked = await showSingleDateDialog(
                      context: context,
                      initial: initial,
                      firstDate: firstDate,
                      lastDate: lastDate,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return picked;
    }

    testWidgets('shows one date, not a span', (tester) async {
      await openSingle(tester, initial: DateTime(2026, 3, 12));

      expect(find.text('Selected date'), findsOneWidget);
      expect(find.text('12 Mar 2026'), findsOneWidget);
      expect(find.textContaining('—'), findsNothing);
    });

    testWidgets('Apply is live straight away — one tap is a whole answer', (
      tester,
    ) async {
      await openSingle(tester, initial: DateTime(2026, 3, 12));
      expect(
        tester
            .widget<ElevatedButton>(find.byType(ElevatedButton).last)
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('every tap moves the selection rather than opening a range', (
      tester,
    ) async {
      await openSingle(tester, initial: DateTime(2026, 3, 12));

      await _tapDay(tester, '4');
      expect(find.text('4 Mar 2026'), findsOneWidget);

      // A second tap replaces it; in range mode this would have closed a span.
      await _tapDay(tester, '19');
      expect(find.text('19 Mar 2026'), findsOneWidget);
      expect(find.textContaining('—'), findsNothing);
    });

    testWidgets('Apply returns the day itself', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    picked = await showSingleDateDialog(
                      context: context,
                      initial: DateTime(2026, 3, 12),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await _tapDay(tester, '7');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(picked, DateTime(2026, 3, 7));
    });

    testWidgets('an unset field opens on today', (tester) async {
      await openSingle(tester);
      final now = DateTime.now();
      expect(find.text(DateFormat('MMMM yyyy').format(now)), findsOneWidget);
    });

    testWidgets('opens inside the allowed span when today falls outside it', (
      tester,
    ) async {
      // What a notice's "show until" does: nothing chosen yet, and the past
      // is not on offer. Opening on today would land before firstDate.
      await openSingle(
        tester,
        firstDate: DateTime(2030, 6, 15),
        lastDate: DateTime(2030, 12, 31),
      );

      expect(find.text('June 2030'), findsOneWidget);
      expect(find.text('15 Jun 2030'), findsOneWidget);
    });
  });

  group('drill-down', () {
    testWidgets('tapping the title opens the months of that year', (
      tester,
    ) async {
      await _open(tester, initial: march);

      await tester.tap(find.text('March 2026'));
      await tester.pumpAndSettle();

      // The title now names the year, and the twelve months are on offer.
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Dec'), findsOneWidget);
      // The weekday letters belong to the day grid only.
      expect(find.text('Mar'), findsOneWidget);
    });

    testWidgets('tapping the title twice opens the years', (tester) async {
      await _open(tester, initial: march);

      await tester.tap(find.text('March 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();

      // 2026 sits in the 2016—2027 block.
      expect(find.text('2016 — 2027'), findsOneWidget);
      expect(find.text('2016'), findsOneWidget);
      expect(find.text('2027'), findsOneWidget);
    });

    testWidgets('year then month then day — the whole way down', (
      tester,
    ) async {
      await _open(
        tester,
        initial: DateTimeRange(
          start: DateTime(2020, 5, 4),
          end: DateTime(2020, 5, 9),
        ),
      );

      // Up to the year grid.
      await tester.tap(find.text('May 2020'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2020'));
      await tester.pumpAndSettle();

      // Pick 2026, which drops back to the months of 2026.
      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();
      expect(find.text('2026'), findsOneWidget);

      // Pick August, which drops back to its days.
      await tester.tap(find.text('Aug'));
      await tester.pumpAndSettle();
      expect(find.text('August 2026'), findsOneWidget);

      // And the days are now tappable as usual.
      await _tapDay(tester, '14');
      expect(find.text('14 Aug 2026'), findsOneWidget);
    });

    testWidgets('picking a year keeps the month it was showing', (
      tester,
    ) async {
      await _open(tester, initial: march);

      await tester.tap(find.text('March 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2024'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mar'));
      await tester.pumpAndSettle();

      expect(find.text('March 2024'), findsOneWidget);
    });

    testWidgets('the arrows page the year while the months are showing', (
      tester,
    ) async {
      await _open(tester, initial: march);

      await tester.tap(find.text('March 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();

      expect(find.text('2027'), findsOneWidget);
    });

    testWidgets('months outside the allowed span are not offered', (
      tester,
    ) async {
      await _open(
        tester,
        initial: DateTimeRange(
          start: DateTime(2026, 6, 10),
          end: DateTime(2026, 6, 20),
        ),
        firstDate: DateTime(2026, 5, 1),
        lastDate: DateTime(2026, 8, 31),
      );

      await tester.tap(find.text('June 2026'));
      await tester.pumpAndSettle();

      // April is before the first date, so its cell is inert.
      final april = tester.widget<InkWell>(
        find
            .ancestor(of: find.text('Apr'), matching: find.byType(InkWell))
            .first,
      );
      expect(april.onTap, isNull);

      // June is inside it, so it still works.
      final june = tester.widget<InkWell>(
        find
            .ancestor(of: find.text('Jun'), matching: find.byType(InkWell))
            .first,
      );
      expect(june.onTap, isNotNull);
    });
  });

  testWidgets('will not page past the first and last month allowed', (
    tester,
  ) async {
    await _open(
      tester,
      initial: DateTimeRange(
        start: DateTime(2026, 3, 10),
        end: DateTime(2026, 3, 20),
      ),
      firstDate: DateTime(2026, 3, 1),
      lastDate: DateTime(2026, 3, 31),
    );

    // Both arrows are inert when the allowed span is a single month.
    for (final icon in [
      Icons.chevron_left_rounded,
      Icons.chevron_right_rounded,
    ]) {
      final arrow = tester.widget<InkWell>(
        find
            .ancestor(of: find.byIcon(icon), matching: find.byType(InkWell))
            .first,
      );
      expect(arrow.onTap, isNull, reason: '$icon should be disabled');
    }
  });
}

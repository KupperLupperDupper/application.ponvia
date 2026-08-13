import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ponvia/core/ui/skeleton.dart';

/// Drives a [SkeletonGate] with a controllable [AsyncValue] so the timing rule
/// (show-delay 200ms → skeleton → min-visible 400ms → fade) can be exercised
/// against the fake clock.
class _Harness extends StatefulWidget {
  const _Harness(this.initial, {super.key});
  final AsyncValue<int> initial;
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late AsyncValue<int> _v = widget.initial;
  void setValue(AsyncValue<int> v) => setState(() => _v = v);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SkeletonGate<int>(
          value: _v,
          semanticsLabel: 'Loading',
          skeleton: (_) => const SizedBox(key: Key('skel'), width: 10, height: 10),
          data: (_, v) => Text('v=$v', key: const Key('content')),
        ),
      ),
    );
  }
}

const _skel = Key('skel');
const _content = Key('content');

void main() {
  testWidgets('fast resolution never builds the skeleton (happy path)',
      (tester) async {
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_Harness(const AsyncLoading<int>(), key: key));

    // Blank body during the show-delay: neither skeleton nor content.
    expect(find.byKey(_skel), findsNothing);
    expect(find.byKey(_content), findsNothing);

    // Data arrives before 200ms → straight to content, no skeleton, no fade.
    await tester.pump(const Duration(milliseconds: 100));
    key.currentState!.setValue(const AsyncData(42));
    await tester.pump();

    expect(find.byKey(_skel), findsNothing);
    expect(find.byKey(_content), findsOneWidget);
  });

  testWidgets('slow resolution shows the skeleton and holds the 400ms floor',
      (tester) async {
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_Harness(const AsyncLoading<int>(), key: key));

    // Still loading at the show-delay → skeleton appears.
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(_skel), findsOneWidget);
    expect(find.byKey(_content), findsNothing);

    // Data arrives right after the skeleton shows; the floor must keep it up.
    key.currentState!.setValue(const AsyncData(7));
    await tester.pump(const Duration(milliseconds: 100)); // 100ms into the floor
    expect(find.byKey(_skel), findsOneWidget);
    expect(find.byKey(_content), findsNothing);

    // Advance past the 400ms floor + the 200ms fade in several frames so the
    // floor timer fires, the fade runs, and whenComplete flips to resolved.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(_content), findsOneWidget);
    expect(find.byKey(_skel), findsNothing);
  });

  testWidgets('value already resolved renders content immediately',
      (tester) async {
    await tester.pumpWidget(_Harness(const AsyncData(5)));
    await tester.pump();
    expect(find.byKey(_content), findsOneWidget);
    expect(find.byKey(_skel), findsNothing);
  });
}

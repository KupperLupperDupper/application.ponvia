import 'package:intl/intl.dart';

/// Formats entry timestamps for display. Relative labels ("Today"/"Yesterday")
/// are localized by the UI layer; this returns absolute formats and the
/// day-difference used to pick a relative label.
class PonviaDateFormatter {
  PonviaDateFormatter({String? locale})
      : _medium = DateFormat.yMMMd(locale),
        _monthDay = DateFormat.MMMd(locale),
        _time = DateFormat.Hm(locale);

  final DateFormat _medium;
  final DateFormat _monthDay;
  final DateFormat _time;

  String date(DateTime dt) => _medium.format(dt);

  /// A compact day+month label without the year (e.g. "12 Oct" / "12. okt"),
  /// used for near-term estimates like the goal ETA.
  String monthDay(DateTime dt) => _monthDay.format(dt);

  /// [monthDay] when [dt] is in [reference]'s year, else the full [date] with
  /// the year — so a projection landing next year stays unambiguous.
  String etaLabel(DateTime dt, DateTime reference) =>
      dt.year == reference.year ? monthDay(dt) : date(dt);

  String time(DateTime dt) => _time.format(dt);

  String dateTime(DateTime dt) => '${_medium.format(dt)} · ${_time.format(dt)}';

  /// Whole-day difference between [dt] and [now] (0 = today, 1 = yesterday).
  static int daysAgo(DateTime dt, DateTime now) {
    final a = DateTime(dt.year, dt.month, dt.day);
    final b = DateTime(now.year, now.month, now.day);
    return b.difference(a).inDays;
  }
}

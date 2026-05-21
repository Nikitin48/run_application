import 'package:intl/intl.dart';

String formatDurationMmSs(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final m = (s ~/ 60).toString().padLeft(2, '0');
  final ss = (s % 60).toString().padLeft(2, '0');
  return '$m:$ss';
}

String formatMeters(double meters) {
  if (meters >= 1000) {
    final km = meters / 1000.0;
    final f = NumberFormat.decimalPattern('ru_RU')..maximumFractionDigits = 2;
    return '${f.format(km)} км';
  }
  final f = NumberFormat.decimalPattern('ru_RU')..maximumFractionDigits = 0;
  return '${f.format(meters)} м';
}

String formatAreaM2(double areaM2) {
  if (areaM2 >= 1e6) {
    final km2 = areaM2 / 1e6;
    final f = NumberFormat.decimalPattern('ru_RU')..maximumFractionDigits = 2;
    return '${f.format(km2)} км²';
  }
  final f = NumberFormat.decimalPattern('ru_RU')..maximumFractionDigits = 0;
  return '${f.format(areaM2)} м²';
}

String formatPace({required double distanceM, required int movingS}) {
  if (distanceM <= 0 || movingS <= 0) return '—';
  final paceSecPerKm = movingS / (distanceM / 1000.0);
  final m = (paceSecPerKm ~/ 60).toInt().toString();
  final s = (paceSecPerKm.round() % 60).toInt().toString().padLeft(2, '0');
  return '$m:$s /км';
}

String formatSpeedKmh({required double distanceM, required int seconds}) {
  if (distanceM <= 0 || seconds <= 0) return '—';
  final kmh = (distanceM / 1000.0) / (seconds / 3600.0);
  final formatter = NumberFormat.decimalPattern('ru_RU')
    ..minimumFractionDigits = 1
    ..maximumFractionDigits = 1;
  return '${formatter.format(kmh)} км/ч';
}

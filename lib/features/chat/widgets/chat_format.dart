// Formatting shared by chat widgets. All inputs are already LOCAL times.

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String _two(int n) => n.toString().padLeft(2, '0');

/// 09:32
String formatClock(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// List row time: `09:32` today · `Yesterday` · `Mon` this week · `12 Sep` · `12 Sep 2025`.
String formatListTime(DateTime t, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return formatClock(t);
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return _weekdays[t.weekday - 1];
  final label = '${t.day} ${_months[t.month - 1]}';
  return t.year == n.year ? label : '$label ${t.year}';
}

/// Date separator: `Today` · `Yesterday` · `12 Sep` · `12 Sep 2025`.
String formatDateLabel(DateTime t, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final diff = today.difference(DateTime(t.year, t.month, t.day)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  final label = '${t.day} ${_months[t.month - 1]}';
  return t.year == n.year ? label : '$label ${t.year}';
}

/// Indian grouping: 540000 → ₹5,40,000.
String formatInr(num value) {
  final s = value.round().abs().toString();
  String grouped;
  if (s.length <= 3) {
    grouped = s;
  } else {
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  return '${value < 0 ? '-' : ''}₹$grouped';
}

/// 0:24 · 3:00
String formatDuration(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  return '${s ~/ 60}:${_two(s % 60)}';
}

String firstName(String name) {
  final t = name.trim();
  if (t.isEmpty) return 'them';
  return t.split(RegExp(r'\s+')).first;
}

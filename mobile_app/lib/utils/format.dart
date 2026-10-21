// Utilidades de formato y cálculo (conversión sacos/libras, monedas, fechas, reputación).
import 'dart:math';


const kgPerSack = 70;
const lbPerKg = 2.20462;
// Una carga = 125 kg de pergamino seco ≈ 94,3 kg de café verde (factor 92,8 kg pergamino → 70 kg verde)
const lbGreenPerCarga = ((125 * 70) / 92.8) * lbPerKg;
// Tasa fija SOLO para la demo
const copPerUsd = 3900;

String otherRole(String role) => role == 'farmer' ? 'buyer' : 'farmer';
String langOf(String role) => role == 'farmer' ? 'es' : 'en';

final _rnd = Random();
const _chars = '0123456789abcdefghijklmnopqrstuvwxyz';

String uid([String prefix = 'id']) {
  final b = StringBuffer(prefix);
  for (var i = 0; i < 6; i++) {
    b.write(_chars[_rnd.nextInt(_chars.length)]);
  }
  final t = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  b.write(t.substring(max(0, t.length - 4)));
  return b.toString();
}

int nowMs() => DateTime.now().millisecondsSinceEpoch;

double sacksToLb(num sacks) => sacks * kgPerSack * lbPerKg;

double quoteTotal(double priceLb, int sacks) => priceLb * sacksToLb(sacks);

double copCargaToUsdLb(num cop) => cop / copPerUsd / lbGreenPerCarga;

/// Número con separadores: en → 1,234.56 · es → 1.234,56
String fmtNum(num n, [String lang = 'en', int decimals = 0]) {
  final neg = n < 0;
  final fixed = n.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final thousands = lang == 'es' ? '.' : ',';
  final decSep = lang == 'es' ? ',' : '.';
  final b = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) b.write(thousands);
    b.write(intPart[i]);
  }
  var s = b.toString();
  if (decimals > 0) s = '$s$decSep${parts[1]}';
  return neg ? '-$s' : s;
}

String fmtUSD(num n, [String lang = 'en', int decimals = 2]) => 'US\$ ${fmtNum(n, lang, decimals)}';

String fmtCOP(num n) => '\$ ${fmtNum(n, 'es', 0)}';

/// SCA: 87.5 → "87.5" · 88 → "88"
String fmtSca(double sca) => sca % 1 == 0 ? sca.toStringAsFixed(0) : sca.toStringAsFixed(1);

const _monthsEs = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'];
const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _daysEs = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _clock(DateTime d, String lang) {
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final mm = d.minute.toString().padLeft(2, '0');
  final pm = d.hour >= 12;
  return lang == 'es' ? '$h12:$mm ${pm ? 'p. m.' : 'a. m.'}' : '$h12:$mm ${pm ? 'PM' : 'AM'}';
}

/// Hora si es hoy, día de la semana si es esta semana, si no día y mes.
String fmtTime(int ts, [String lang = 'en']) {
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  final now = DateTime.now();
  final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
  if (sameDay) return _clock(d, lang);
  final diffDays = now.difference(d).inDays;
  if (diffDays < 7) return lang == 'es' ? _daysEs[d.weekday - 1] : _daysEn[d.weekday - 1];
  return lang == 'es' ? '${d.day} ${_monthsEs[d.month - 1]}' : '${_monthsEn[d.month - 1]} ${d.day}';
}

String fmtDate(int ts, [String lang = 'en']) {
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  return lang == 'es' ? '${d.day} ${_monthsEs[d.month - 1]} ${d.year}' : '${_monthsEn[d.month - 1]} ${d.day}, ${d.year}';
}

String fmtDuration(num sec) {
  final s = max(0, sec.round());
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

String firstName(String full) => full.split(' ').first;

double round2(double v) => (v * 100).roundToDouble() / 100;

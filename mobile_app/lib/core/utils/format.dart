// Utilidades de formato y cálculo (conversión sacos/libras, monedas y fechas).

const kgPerSack = 70;
const lbPerKg = 2.20462;

/// Una carga = 125 kg de café pergamino seco. Con el factor de rendimiento base de la FNC (94:
/// 94 kg de pergamino → 70 kg de café verde) equivale a ≈ 93,1 kg ≈ 205,2 lb de café verde.
const yieldFactor = 94;
const lbGreenPerCarga = ((125 * 70) / yieldFactor) * lbPerKg;

/// Tasa de respaldo SOLO para cuando no se pudo consultar la TRM del día (la app usa la TRM real
/// que entrega el servidor; ver MarketProvider.copPerUsd).
const fallbackCopPerUsd = 3900.0;

int nowMs() => DateTime.now().millisecondsSinceEpoch;

double sacksToLb(num sacks) => sacks * kgPerSack * lbPerKg;

double quoteTotal(double priceLb, int sacks) => priceLb * sacksToLb(sacks);

/// Precio por carga (COP) → US$ por libra de café verde, con la TRM indicada.
double copCargaToUsdLb(num cop, [double copPerUsd = fallbackCopPerUsd]) => cop / copPerUsd / lbGreenPerCarga;

/// US$ por libra de café verde → precio por carga (COP), con la TRM indicada.
double usdLbToCopCarga(double usdLb, [double copPerUsd = fallbackCopPerUsd]) => usdLb * lbGreenPerCarga * copPerUsd;

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


String firstName(String full) => full.split(' ').first;

double round2(double v) => (v * 100).roundToDouble() / 100;

/// Tiempo que falta para `endsAtMs`: "2 días", "5 h 12 min", "3 min 20 s".
String fmtRemaining(int endsAtMs, [String lang = 'en']) {
  final d = endsAtMs - nowMs();
  final es = lang == 'es';
  if (d <= 0) return es ? 'Terminó' : 'Ended';
  final h = d ~/ 3600000;
  final m = (d % 3600000) ~/ 60000;
  final s = (d % 60000) ~/ 1000;
  if (h >= 48) return es ? '${h ~/ 24} días' : '${h ~/ 24} days';
  if (h > 0) return '$h h $m min';
  if (m > 0) return '$m min $s s';
  return '$s s';
}

/// "hace 5 min", "hace 2 h", "ayer"…
String fmtAgo(int ts, [String lang = 'en']) {
  final d = nowMs() - ts;
  final es = lang == 'es';
  if (d < 60000) return es ? 'ahora' : 'now';
  if (d < 3600000) return es ? 'hace ${d ~/ 60000} min' : '${d ~/ 60000} min ago';
  if (d < 86400000) return es ? 'hace ${d ~/ 3600000} h' : '${d ~/ 3600000} h ago';
  if (d < 2 * 86400000) return es ? 'ayer' : 'yesterday';
  return fmtDate(ts, lang);
}

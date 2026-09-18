import 'dart:math' as math;

/// A discrete-time signal: value v[i] lives at time index (n0 + i).
/// Direct port of the `{n0, v}` object used throughout the original JS.
class Signal {
  final int n0;
  final List<double> v;
  const Signal(this.n0, this.v);

  int get end => n0 + v.length - 1;

  static Signal zero() => const Signal(0, [0]);
}

double sigAt(Signal s, int n) {
  final i = n - s.n0;
  if (i >= 0 && i < s.v.length) return s.v[i];
  return 0;
}

int sigEnd(Signal s) => s.n0 + s.v.length - 1;

Signal sigFromFn(double Function(int n) fn, int a, int b) {
  final v = <double>[];
  for (var n = a; n <= b; n++) {
    final y = fn(n);
    v.add(y.isFinite ? y : double.nan);
  }
  return Signal(a, v);
}

Signal sigPad(Signal s, int a, int b) => sigFromFn((n) => sigAt(s, n), a, b);

List<int> range(int a, int b) {
  final o = <int>[];
  for (var i = a; i <= b; i++) {
    o.add(i);
  }
  return o;
}

/// Parses text like "1, 2, [3], 2, 1" (bracket marks the n = 0 sample)
/// or plain "1 2 3 4" starting at [startIdx]. Mirrors `parseSequence`.
Signal parseSequence(String text, String startIdx) {
  final raw = text.replaceAll(RegExp(r'[;\n\t]'), ',').trim();
  if (raw.isEmpty) throw const FormatException('Enter at least one sample value.');
  final toks = raw.split(RegExp(r'[,\s]+')).where((t) => t.isNotEmpty).toList();
  var zero = -1;
  final v = <double>[];
  for (var i = 0; i < toks.length; i++) {
    var t = toks[i];
    if (RegExp(r'^\[.*\]$').hasMatch(t) || RegExp(r'^[*^]').hasMatch(t)) {
      zero = i;
      t = t.replaceAll(RegExp(r'^\[|\]$'), '').replaceAll(RegExp(r'^[*^]'), '');
    }
    final num = double.tryParse(t.replaceAll('−', '-'));
    if (num == null) throw FormatException('"$t" is not a number.');
    v.add(num);
  }
  if (v.length > 512) throw const FormatException('Keep sequences to 512 samples or fewer.');
  final start = int.tryParse(startIdx) ?? 0;
  return Signal(zero >= 0 ? -zero : start, v);
}

String fmt(double? v, [int d = 3]) {
  if (v == null || v.isNaN) return '—';
  if (!v.isFinite) return v > 0 ? '∞' : '−∞';
  if (v.abs() < 1e-10) return '0';
  final a = v.abs();
  String s;
  if (a >= 1e5 || a < 1e-3) {
    s = v.toStringAsExponential(2);
  } else {
    s = _trimZeros(v.toStringAsFixed(d));
  }
  return s.replaceAll('-', '−');
}

String _trimZeros(String s) {
  if (!s.contains('.')) return s;
  s = s.replaceAll(RegExp(r'0+$'), '');
  s = s.replaceAll(RegExp(r'\.$'), '');
  return s;
}

double gaussRand(math.Random rng) {
  double u = 0, v = 0;
  while (u == 0) {
    u = rng.nextDouble();
  }
  while (v == 0) {
    v = rng.nextDouble();
  }
  return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
}

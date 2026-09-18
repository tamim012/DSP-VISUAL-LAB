import 'dart:math' as math;
import 'signal.dart';

class ComplexSeq {
  final List<double> re;
  final List<double> im;
  ComplexSeq(this.re, this.im);
}

bool isPow2(int n) => n > 0 && (n & (n - 1)) == 0;

/// In-place radix-2 FFT (Cooley-Tukey). Direct port of fftInPlace().
void fftInPlace(List<double> re, List<double> im, bool inverse) {
  final n = re.length;
  for (int i = 1, j = 0; i < n; i++) {
    int bit = n >> 1;
    for (; (j & bit) != 0; bit >>= 1) {
      j ^= bit;
    }
    j ^= bit;
    if (i < j) {
      final tr = re[i];
      re[i] = re[j];
      re[j] = tr;
      final ti = im[i];
      im[i] = im[j];
      im[j] = ti;
    }
  }
  for (int len = 2; len <= n; len <<= 1) {
    final ang = 2 * math.pi / len * (inverse ? 1 : -1);
    final wr = math.cos(ang), wi = math.sin(ang);
    for (int i = 0; i < n; i += len) {
      double cr = 1, ci = 0;
      for (int k = 0; k < len ~/ 2; k++) {
        final ar = re[i + k], ai = im[i + k];
        final br = re[i + k + len ~/ 2], bi = im[i + k + len ~/ 2];
        final tr = br * cr - bi * ci, ti = br * ci + bi * cr;
        re[i + k] = ar + tr;
        im[i + k] = ai + ti;
        re[i + k + len ~/ 2] = ar - tr;
        im[i + k + len ~/ 2] = ai - ti;
        final ncr = cr * wr - ci * wi;
        ci = cr * wi + ci * wr;
        cr = ncr;
      }
    }
  }
  if (inverse) {
    for (int i = 0; i < n; i++) {
      re[i] /= n;
      im[i] /= n;
    }
  }
}

/// X[k] = Σ x[n]·e^{-j2πkn/N}; falls back to an O(N²) DFT for non
/// power-of-two lengths, exactly like the original `dft()`.
ComplexSeq dft(List<double> reIn, List<double>? imIn, {bool inverse = false}) {
  final n = reIn.length;
  final re = reIn.map((value) => value.toDouble()).toList();
  final im = imIn == null ? List<double>.filled(n, 0.0) : imIn.map((value) => value.toDouble()).toList();
  if (isPow2(n)) {
    fftInPlace(re, im, inverse);
    return ComplexSeq(re, im);
  }
  final oR = List<double>.filled(n, 0), oI = List<double>.filled(n, 0);
  final sg = inverse ? 1 : -1;
  for (int k = 0; k < n; k++) {
    double sr = 0, si = 0;
    for (int m = 0; m < n; m++) {
      final a = sg * 2 * math.pi * k * m / n;
      final c = math.cos(a), s = math.sin(a);
      sr += re[m] * c - im[m] * s;
      si += re[m] * s + im[m] * c;
    }
    oR[k] = inverse ? sr / n : sr;
    oI[k] = inverse ? si / n : si;
  }
  return ComplexSeq(oR, oI);
}

/// Direct-summation DTFT at arbitrary (continuous) frequencies.
ComplexSeq dtft(Signal sig, List<double> omegas) {
  final re = List<double>.filled(omegas.length, 0);
  final im = List<double>.filled(omegas.length, 0);
  for (int i = 0; i < omegas.length; i++) {
    final w = omegas[i];
    double sr = 0, si = 0;
    for (int j = 0; j < sig.v.length; j++) {
      final x = sig.v[j];
      final n = sig.n0 + j;
      sr += x * math.cos(w * n);
      si -= x * math.sin(w * n);
    }
    re[i] = sr;
    im[i] = si;
  }
  return ComplexSeq(re, im);
}

List<double> linspace(double a, double b, int n) {
  final o = List<double>.filled(n, 0);
  for (int i = 0; i < n; i++) {
    o[i] = a + (b - a) * i / (n - 1);
  }
  return o;
}

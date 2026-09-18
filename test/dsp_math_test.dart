import 'package:flutter_test/flutter_test.dart';
import 'package:dsp_visual_lab/dsp/signal.dart';
import 'package:dsp_visual_lab/dsp/fourier.dart';

void main() {
  test('sequence parser honours n=0 marker', () {
    final s = parseSequence('1, 2, [3], 2, 1', '0');
    expect(s.n0, -2);
    expect(s.v[2], 3);
  });

  test('FFT/IFFT round trip', () {
    final x = [1.0, 2.0, -1.0, 0.5, 0.0, 3.0, 2.0, -2.0];
    final X = dft(x, null);
    final y = dft(X.re, X.im, inverse: true);
    for (var i = 0; i < x.length; i++) {
      expect(y.re[i], closeTo(x[i], 1e-9));
      expect(y.im[i], closeTo(0, 1e-9));
    }
  });

  test('DTFT at zero equals sum', () {
    const s = Signal(0, [1, 2, 3]);
    final X = dtft(s, [0]);
    expect(X.re[0], closeTo(6, 1e-9));
    expect(X.im[0], closeTo(0, 1e-9));
  });
}

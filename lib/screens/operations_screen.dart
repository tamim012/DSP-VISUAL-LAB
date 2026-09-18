import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../dsp/signal.dart';
import '../widgets/stem_plot.dart';
import '../widgets/signal_input.dart';
import '../widgets/ui_kit.dart';

enum _Op { shift, reverse, tscale, amp, arith }

final _presetsX = [
  SignalPreset('Ramp pulse {0,1,2,3,4}', () => const Signal(0, [0, 1, 2, 3, 4])),
  SignalPreset('Textbook {1, [2], 3, 4, 5}', () => const Signal(-1, [1, 2, 3, 4, 5])),
  SignalPreset('Uneven staircase {[3], 2, 2, 1}', () => const Signal(0, [3, 2, 2, 1])),
  SignalPreset('Decaying 0.8ⁿ, 10 samples', () => sigFromFn((n) => _pow(0.8, n), 0, 9)),
  SignalPreset('Pulse u[n+2]-u[n-3]', () => sigFromFn((n) => (n >= -2 && n < 3) ? 1.0 : 0.0, -2, 2)),
  SignalPreset('Alternating {1,-1,2,-2,[3],-3}', () => const Signal(-4, [1, -1, 2, -2, 3, -3])),
];
final _presetsH = [
  SignalPreset('Pulse {[1],1,1,1}', () => const Signal(0, [1, 1, 1, 1])),
  SignalPreset('Step-down {[2],1,0,-1}', () => const Signal(0, [2, 1, 0, -1])),
  SignalPreset('Unit step window u[n]', () => sigFromFn((n) => n >= 0 ? 1.0 : 0.0, 0, 8)),
  SignalPreset('Alternating (-1)ⁿ', () => sigFromFn((n) => n % 2 != 0 ? -1.0 : 1.0, -3, 8)),
];
double _pow(double a, int n) {
  double r = 1;
  for (int i = 0; i < n; i++) {
    r *= a;
  }
  return r;
}

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});
  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  _Op op = _Op.shift;
  Signal x = const Signal(0, [0, 1, 2, 3, 4]);
  Signal x2 = const Signal(0, [1, 1, 1, 1]);
  bool showGhost = true;
  bool showLabels = false;

  // per-operation params
  int shiftK = 2;
  double ampA = 1, ampC = 0;
  String tscaleMode = 'down'; // down = compress x[Mn], up = expand x[n/L]
  int tscaleM = 2, tscaleL = 2;
  String arithOp = 'add';

  Signal _computeY() {
    switch (op) {
      case _Op.shift:
        return sigFromFn((n) => sigAt(x, n - shiftK), sigEnd(x) < x.n0 ? x.n0 : x.n0 + shiftK - 2, sigEnd(x) + shiftK + 2);
      case _Op.reverse:
        return sigFromFn((n) => sigAt(x, -n), -sigEnd(x) - 2, -x.n0 + 2);
      case _Op.tscale:
        if (tscaleMode == 'up') {
          final a = x.n0 * tscaleL, b = sigEnd(x) * tscaleL;
          return sigFromFn((n) => (n % tscaleL == 0) ? sigAt(x, n ~/ tscaleL) : 0, a, b);
        } else {
          final a = (x.n0 / tscaleM).ceil(), b = (sigEnd(x) / tscaleM).floor();
          return sigFromFn((n) => sigAt(x, tscaleM * n), a, b);
        }
      case _Op.amp:
        return sigFromFn((n) => ampA * sigAt(x, n) + ampC, x.n0, sigEnd(x));
      case _Op.arith:
        final a = [x.n0, x2.n0].reduce((v, e) => v < e ? v : e);
        final b = [sigEnd(x), sigEnd(x2)].reduce((v, e) => v > e ? v : e);
        return sigFromFn((n) {
          final u = sigAt(x, n), v = sigAt(x2, n);
          switch (arithOp) {
            case 'add':
              return u + v;
            case 'sub':
              return u - v;
            default:
              return u * v;
          }
        }, a, b);
    }
  }

  String _eq() {
    switch (op) {
      case _Op.shift:
        return shiftK == 0 ? 'y[n] = x[n]' : 'y[n] = x[n ${shiftK > 0 ? '−' : '+'} ${shiftK.abs()}]';
      case _Op.reverse:
        return 'y[n] = x[−n]';
      case _Op.tscale:
        return tscaleMode == 'up' ? 'y[n] = x[n / $tscaleL]  (when n/$tscaleL is an integer)' : 'y[n] = x[${tscaleM}n]';
      case _Op.amp:
        return 'y[n] = ${fmt(ampA)}·x[n]${ampC != 0 ? (ampC > 0 ? ' + ${fmt(ampC)}' : ' − ${fmt(ampC.abs())}') : ''}';
      case _Op.arith:
        return 'y[n] = x₁[n] ${{'add': '+', 'sub': '−', 'mul': '·'}[arithOp]} x₂[n]';
    }
  }

  String _desc() {
    switch (op) {
      case _Op.shift:
        if (shiftK == 0) return 'No shift: y[n] equals x[n].';
        return shiftK > 0
            ? 'Delay by $shiftK: every sample moves $shiftK step(s) to the right (later).'
            : 'Advance by ${-shiftK}: every sample moves ${-shiftK} step(s) to the left (earlier).';
      case _Op.reverse:
        return 'Folding about n = 0: the sample at n = m moves to n = −m. n = 0 stays put.';
      case _Op.tscale:
        return tscaleMode == 'up'
            ? 'Expansion (up-sampling) by $tscaleL: samples spread $tscaleL× further apart; in-between positions are filled with zeros here.'
            : 'Compression (down-sampling) by $tscaleM: keep every ${tscaleM}th sample and discard the rest. Not reversible.';
      case _Op.amp:
        return 'Every sample is multiplied by ${fmt(ampA)}${ampC != 0 ? ' and then ${fmt(ampC)} is added' : ''}. The time axis is unchanged.';
      case _Op.arith:
        return arithOp == 'mul'
            ? 'Sample-by-sample product: nonzero only where both signals are nonzero.'
            : 'Sample-by-sample ${arithOp == 'add' ? 'sum' : 'difference'}, aligned on the shared n axis. Missing samples count as 0.';
    }
  }

  String _mistake() {
    switch (op) {
      case _Op.shift:
        return 'A common slip: x[n − k] with k > 0 moves the signal right (later), not left.';
      case _Op.reverse:
        return 'Reversal flips around n = 0, not the centre of the signal.';
      case _Op.tscale:
        return 'Compressing then expanding does not recover the original — samples are lost for good.';
      case _Op.amp:
        return 'Amplitude reversal −x[n] flips values vertically; time reversal x[−n] flips the time axis. Different, unless the signal is symmetric.';
      case _Op.arith:
        return 'Add signals by index n, not list position — {[1],2,3} + {1,[2],3} is not {2,4,6} if they start at different n.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final y = _computeY();
    final xr = <double>[
      [x.n0, op == _Op.arith ? x2.n0 : y.n0].reduce((a, b) => a < b ? a : b).toDouble() - 1.5,
      [sigEnd(x), op == _Op.arith ? sigEnd(x2) : sigEnd(y)].reduce((a, b) => a > b ? a : b).toDouble() + 1.5,
    ];
    final ns = range(xr[0].floor(), xr[1].ceil());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shifting and scaling', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Pick an operation, change the settings, and see how y[n] relates to x[n].',
              style: TextStyle(color: AppColors.ink2, fontSize: 13.5)),
          const SizedBox(height: 14),
          SectionCard(
            title: op == _Op.arith ? 'First input x₁[n]' : 'Input x[n]',
            child: SignalInput(
              title: '',
              color: AppColors.blue,
              presets: _presetsX,
              onChange: (v) => setState(() => x = v),
            ),
          ),
          if (op == _Op.arith)
            SectionCard(
              title: 'Second input x₂[n]',
              child: SignalInput(
                title: '',
                color: AppColors.rasp,
                presets: _presetsH,
                onChange: (v) => setState(() => x2 = v),
              ),
            ),
          SectionCard(
            title: 'Operation',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final e in {
                      _Op.shift: 'Time shift',
                      _Op.reverse: 'Time reversal',
                      _Op.tscale: 'Time scaling',
                      _Op.amp: 'Amplitude scaling',
                      _Op.arith: 'Add & multiply',
                    }.entries)
                      ChoiceChip(label: Text(e.value), selected: op == e.key, onSelected: (_) => setState(() => op = e.key)),
                  ],
                ),
                const SizedBox(height: 12),
                if (op == _Op.shift)
                  ParamSlider(
                    label: 'Shift k',
                    value: shiftK.toDouble(),
                    min: -8,
                    max: 8,
                    divisions: 16,
                    readout: '$shiftK',
                    onChanged: (v) => setState(() => shiftK = v.round()),
                  ),
                if (op == _Op.reverse) const Text('Time reversal has no settings.', style: TextStyle(fontSize: 13, color: AppColors.ink3)),
                if (op == _Op.tscale) ...[
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'down', label: Text('Compress x[Mn]')),
                      ButtonSegment(value: 'up', label: Text('Expand x[n/L]')),
                    ],
                    selected: {tscaleMode},
                    onSelectionChanged: (s) => setState(() => tscaleMode = s.first),
                  ),
                  const SizedBox(height: 8),
                  if (tscaleMode == 'down')
                    ParamSlider(
                      label: 'Compress by M',
                      value: tscaleM.toDouble(),
                      min: 2,
                      max: 5,
                      divisions: 3,
                      readout: '$tscaleM',
                      onChanged: (v) => setState(() => tscaleM = v.round()),
                    )
                  else
                    ParamSlider(
                      label: 'Expand by L',
                      value: tscaleL.toDouble(),
                      min: 2,
                      max: 5,
                      divisions: 3,
                      readout: '$tscaleL',
                      onChanged: (v) => setState(() => tscaleL = v.round()),
                    ),
                ],
                if (op == _Op.amp) ...[
                  ParamSlider(
                      label: 'Gain A', value: ampA, min: -3, max: 3, divisions: 24, readout: fmt(ampA), onChanged: (v) => setState(() => ampA = v)),
                  ParamSlider(
                      label: 'Offset c', value: ampC, min: -3, max: 3, divisions: 24, readout: fmt(ampC), onChanged: (v) => setState(() => ampC = v)),
                ],
                if (op == _Op.arith)
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'add', label: Text('x₁ + x₂')),
                      ButtonSegment(value: 'sub', label: Text('x₁ − x₂')),
                      ButtonSegment(value: 'mul', label: Text('x₁ · x₂')),
                    ],
                    selected: {arithOp},
                    onSelectionChanged: (s) => setState(() => arithOp = s.first),
                  ),
              ],
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: showGhost,
            title: const Text('Show x[n] faintly behind y[n]', style: TextStyle(fontSize: 13.5)),
            onChanged: (v) => setState(() => showGhost = v ?? true),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: showLabels,
            title: const Text('Show sample values on plot', style: TextStyle(fontSize: 13.5)),
            onChanged: (v) => setState(() => showLabels = v ?? false),
          ),
          SectionCard(
            title: 'y[n]',
            child: SignalPlot(
              height: 240,
              series: [
                if (showGhost)
                  PlotSeries(
                    type: SeriesType.stem,
                    x: ns.map((e) => e.toDouble()).toList(),
                    y: ns.map((n) => sigAt(x, n)).toList(),
                    color: AppColors.gray,
                    width: 1.2,
                  ),
                PlotSeries(
                  type: SeriesType.stem,
                  x: ns.map((e) => e.toDouble()).toList(),
                  y: ns.map((n) => sigAt(y, n)).toList(),
                  color: AppColors.green,
                  labels: showLabels,
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Definition',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_eq(), style: AppTheme.mathStyle.copyWith(fontSize: 16)),
                const SizedBox(height: 8),
                Text(_desc(), style: const TextStyle(color: AppColors.ink2, fontSize: 14, height: 1.4)),
                NoteBox('Watch out. ${_mistake()}', color: AppColors.amber, bg: AppColors.amberSoft),
              ],
            ),
          ),
          SectionCard(
            title: 'All values',
            child: ValueTable(ns: ns, rows: [
              MapEntry('x[n]', ns.map((n) => fmt(sigAt(x, n), 3)).toList()),
              if (op == _Op.arith) MapEntry('x₂[n]', ns.map((n) => fmt(sigAt(x2, n), 3)).toList()),
              MapEntry('y[n]', ns.map((n) => fmt(sigAt(y, n), 3)).toList()),
            ]),
          ),
        ],
      ),
    );
  }
}

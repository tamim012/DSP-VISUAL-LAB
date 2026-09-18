import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../dsp/signal.dart';
import '../widgets/stem_plot.dart';
import '../widgets/signal_input.dart';
import '../widgets/ui_kit.dart';

class _Param {
  final String key;
  final String label;
  final double min;
  final double max;
  final double step;
  final double def;
  final bool isPi;

  const _Param(
    this.key,
    this.label,
    this.min,
    this.max,
    this.step,
    this.def, {
    this.isPi = false,
  });
}

class _SigDef {
  final String name;
  final String cat;
  final List<int> range;
  final List<_Param> params;
  final double Function(int n, Map<String, double> p) fn;
  final String Function(Map<String, double> p) eq;
  final String desc;
  final List<String> props;
  final bool custom;

  const _SigDef({
    required this.name,
    required this.cat,
    required this.range,
    this.params = const [],
    required this.fn,
    required this.eq,
    required this.desc,
    this.props = const [],
    this.custom = false,
  });
}

final Map<String, _SigDef> _sigs = {
  'impulse': _SigDef(
    name: 'Unit impulse',
    cat: 'basic',
    range: const [-10, 10],
    params: const [
      _Param('A', 'Amplitude A', -3, 3, 0.1, 1),
      _Param('k', 'Shift k', -8, 8, 1, 0),
    ],
    fn: (n, p) => n == p['k'] ? p['A']! : 0,
    eq: (p) => 'x[n] = ${fmt(p['A'])}·δ[n − ${fmt(p['k'])}]',
    desc:
        'The unit impulse is 1 at a single instant and 0 everywhere else. The response of an LTI system to it (the impulse response) tells you everything about the system.',
    props: const [
      'Sifting: x[n]·δ[n−k] = x[k]·δ[n−k].',
      'Any signal = Σ x[k]·δ[n−k].',
      'δ[n] = u[n] − u[n−1].',
    ],
  ),
  'step': _SigDef(
    name: 'Unit step',
    cat: 'basic',
    range: const [-10, 15],
    params: const [
      _Param('A', 'Amplitude A', -3, 3, 0.1, 1),
      _Param('k', 'Shift k', -8, 8, 1, 0),
    ],
    fn: (n, p) => n >= p['k']! ? p['A']! : 0,
    eq: (p) => 'x[n] = ${fmt(p['A'])}·u[n − ${fmt(p['k'])}]',
    desc:
        'The unit step switches on at n = k and stays on. Multiplying by u[n] keeps only values for n ≥ k.',
    props: const [
      'u[n] = running sum of δ[n].',
      'δ[n] = u[n] − u[n−1].',
      'Infinite energy, average power ½.',
    ],
  ),
  'ramp': _SigDef(
    name: 'Unit ramp',
    cat: 'basic',
    range: const [-5, 15],
    params: const [
      _Param('A', 'Slope A', -2, 2, 0.1, 1),
      _Param('k', 'Shift k', -8, 8, 1, 0),
    ],
    fn: (n, p) => n >= p['k']! ? p['A']! * (n - p['k']!) : 0,
    eq: (p) =>
        'x[n] = ${fmt(p['A'])}·r[n − ${fmt(p['k'])}],  r[n] = n·u[n]',
    desc:
        'The ramp grows by A each sample after it starts. It is the running sum of a delayed step.',
    props: const [
      'r[n] = n·u[n].',
      'u[n] = r[n+1] − r[n].',
      'Neither an energy nor a power signal.',
    ],
  ),
  'rect': _SigDef(
    name: 'Rectangular pulse',
    cat: 'basic',
    range: const [-10, 15],
    params: const [
      _Param('A', 'Amplitude A', -3, 3, 0.1, 1),
      _Param('k', 'Starts at k', -8, 8, 1, 0),
      _Param('N', 'Width N', 1, 15, 1, 5),
    ],
    fn: (n, p) =>
        (n >= p['k']! && n < p['k']! + p['N']!) ? p['A']! : 0,
    eq: (p) =>
        'x[n] = ${fmt(p['A'])}·(u[n−${fmt(p['k'])}] − u[n−${fmt(p['k']! + p['N']!)}])',
    desc:
        'A rectangular pulse is on for N samples: the difference of two shifted steps.',
    props: const [
      'Width N → samples k…k+N−1.',
      'Energy = A²·N.',
      'DTFT has a Dirichlet (periodic sinc) shape.',
    ],
  ),
  'tri': _SigDef(
    name: 'Triangular pulse',
    cat: 'basic',
    range: const [-12, 12],
    params: const [
      _Param('A', 'Peak A', -3, 3, 0.1, 1),
      _Param('k', 'Centre k', -6, 6, 1, 0),
      _Param('N', 'Half-width N', 1, 10, 1, 5),
    ],
    fn: (n, p) => (n - p['k']!).abs() <= p['N']!
        ? p['A']! * (1 - (n - p['k']!).abs() / p['N']!)
        : 0,
    eq: (p) =>
        'x[n] = ${fmt(p['A'])}·(1 − |n−${fmt(p['k'])}|/${fmt(p['N'])})',
    desc:
        'Rises linearly to a peak and falls back symmetrically. A rectangle convolved with itself gives a triangle.',
    props: const [
      'Even about its centre k.',
      'Triangle ∝ rect ∗ rect.',
      'Used as the Bartlett window.',
    ],
  ),
  'sgn': _SigDef(
    name: 'Signum',
    cat: 'basic',
    range: const [-10, 10],
    params: const [
      _Param('A', 'Amplitude A', -3, 3, 0.1, 1),
    ],
    fn: (n, p) => p['A']! * n.sign.toDouble(),
    eq: (p) => 'x[n] = ${fmt(p['A'])}·sgn[n]',
    desc:
        'Reports the sign of n: +1, 0, or −1. It is a purely odd signal.',
    props: const [
      'sgn[n] = u[n] − u[−n].',
      'Odd signal: x[−n] = −x[n].',
    ],
  ),
  'exp': _SigDef(
    name: 'Real exponential',
    cat: 'exp',
    range: const [-5, 20],
    params: const [
      _Param('A', 'Amplitude A', -3, 3, 0.1, 1),
      _Param('a', 'Base a', -1.4, 1.4, 0.01, 0.8),
    ],
    fn: (n, p) =>
        n >= 0 ? p['A']! * math.pow(p['a']!, n).toDouble() : 0,
    eq: (p) => 'x[n] = ${fmt(p['A'])}·(${fmt(p['a'])})ⁿ·u[n]',
    desc:
        'Multiplies by the same factor a each sample: decays if |a|<1, grows if |a|>1, alternates sign if a<0.',
    props: const [
      '|a|<1: stable/decaying. |a|>1: grows.',
      'For |a|<1, energy of Aⁿu[n] = A²/(1−a²).',
    ],
  ),
  'sin': _SigDef(
    name: 'Sinusoid',
    cat: 'exp',
    range: const [-5, 40],
    params: const [
      _Param('A', 'Amplitude A', 0, 3, 0.1, 1),
      _Param(
        'w',
        'Frequency ω₀ (×π rad/sample)',
        0,
        2,
        0.01,
        0.25,
        isPi: true,
      ),
      _Param(
        'phi',
        'Phase φ (×π rad)',
        -1,
        1,
        0.05,
        0,
        isPi: true,
      ),
    ],
    fn: (n, p) =>
        p['A']! *
        math.cos(
          p['w']! * math.pi * n + p['phi']! * math.pi,
        ),
    eq: (p) =>
        'x[n] = ${fmt(p['A'])}·cos(${fmt(p['w'])}πn + ${fmt(p['phi'])}π)',
    desc:
        'A cosine sampled at integers. Periodic only when ω₀/2π is rational; ω₀ and ω₀+2π look identical (aliasing).',
    props: const [
      'Periodic with period N only if ω₀/2π = m/N.',
      'Fastest oscillation at ω₀ = π: (−1)ⁿ.',
    ],
  ),
  'square': _SigDef(
    name: 'Square wave',
    cat: 'exp',
    range: const [-2, 40],
    params: const [
      _Param('A', 'Amplitude A', 0, 3, 0.1, 1),
      _Param('N', 'Period N', 2, 24, 1, 10),
      _Param('duty', 'Samples high per period', 1, 23, 1, 5),
    ],
    fn: (n, p) {
      final N = p['N']!.toInt();
      final duty = math.min(p['duty']!, N - 1);
      final m = ((n % N) + N) % N;
      return m < duty ? p['A']! : -p['A']!;
    },
    eq: (p) =>
        'x[n] = ±${fmt(p['A'])}, period N = ${p['N']!.toInt()}',
    desc: 'Switches between +A and −A, repeating every N samples.',
    props: const [
      'Periodic: x[n+N] = x[n].',
      'Duty cycle = high samples ÷ N.',
      'Average power = A².',
    ],
  ),
  'saw': _SigDef(
    name: 'Sawtooth',
    cat: 'exp',
    range: const [-2, 40],
    params: const [
      _Param('A', 'Amplitude A', 0, 3, 0.1, 1),
      _Param('N', 'Period N', 2, 24, 1, 8),
    ],
    fn: (n, p) {
      final N = p['N']!.toInt();
      final m = ((n % N) + N) % N;
      return p['A']! * (2 * m / (N - 1) - 1);
    },
    eq: (p) =>
        'x[n] = ${fmt(p['A'])}·(2·(n mod ${p['N']!.toInt()})/${p['N']!.toInt() - 1} − 1)',
    desc:
        'A periodic ramp: climbs from −A to +A over one period, then drops back. Rich in harmonics.',
    props: const [
      'Periodic with period N.',
      'Used as a synthesis/test waveform.',
    ],
  ),
  'custom': const _SigDef(
    name: 'Your own signal',
    cat: 'other',
    range: [-10, 10],
    fn: _zeroFn,
    eq: _customEq,
    desc:
        'Type a list of samples or a formula in n. Everything below updates for your signal.',
    props: [
      'Mark the n=0 sample with brackets, e.g. 1, 2, [3], 2, 1.',
      'Try 0.9^n*cos(pi*n/6)*u[n].',
    ],
    custom: true,
  ),
};

double _zeroFn(int n, Map<String, double> p) => 0;

String _customEq(Map<String, double> p) => 'x[n] = your entry';

class SignalsScreen extends StatefulWidget {
  const SignalsScreen({super.key});

  @override
  State<SignalsScreen> createState() => _SignalsScreenState();
}

class _SignalsScreenState extends State<SignalsScreen> {
  String cur = 'impulse';
  Map<String, double> params = {};
  int nA = -10;
  int nB = 10;
  bool showLabels = false;

  Signal customSig = const Signal(
    -2,
    [1, 2, 3, 2, 1],
  );

  @override
  void initState() {
    super.initState();
    _select('impulse');
  }

  void _select(String key) {
    final s = _sigs[key]!;

    setState(() {
      cur = key;
      nA = s.range[0];
      nB = s.range[1];
      params = {
        for (final p in s.params) p.key: p.def,
      };
    });
  }

  Signal _computeSignal() {
    final s = _sigs[cur]!;

    if (s.custom) {
      return sigPad(customSig, nA, nB);
    }

    return sigFromFn(
      (n) => s.fn(n, params),
      nA,
      nB,
    );
  }

  // ============================================================
  // Get x[n]
  // ============================================================
  double _originalAt(int index) {
    final s = _sigs[cur]!;

    if (s.custom) {
      return sigAt(customSig, index);
    }

    return s.fn(index, params);
  }

  // ============================================================
  // EVEN PART
  //
  // x_e[n] = (x[n] + x[-n]) / 2
  // ============================================================
  double _evenAt(int index) {
    return (_originalAt(index) + _originalAt(-index)) / 2;
  }

  // ============================================================
  // ODD PART
  //
  // x_o[n] = (x[n] - x[-n]) / 2
  // ============================================================
  double _oddAt(int index) {
    return (_originalAt(index) - _originalAt(-index)) / 2;
  }

  List<double> _evenValues(List<int> ns) {
    return [
      for (final index in ns) _evenAt(index),
    ];
  }

  List<double> _oddValues(List<int> ns) {
    return [
      for (final index in ns) _oddAt(index),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = _sigs[cur]!;
    final sig = _computeSignal();
    final ns = range(nA, nB);

    final evenValues = _evenValues(ns);
    final oddValues = _oddValues(ns);

    // ==========================================================
    // Statistics
    // ==========================================================
    final vals = sig.v;

    final energy = vals.fold<double>(
      0,
      (p, c) => p + c * c,
    );

    final sampleCount = vals.length;

    // FIX:
    // Explicit double typing prevents Dart from inferring `num`.
    final double mean = sampleCount == 0
        ? 0.0
        : vals.fold<double>(
              0.0,
              (p, c) => p + c,
            ) /
            sampleCount;

    // FIX:
    // Both branches are explicitly double and math.max is converted
    // to double, so fmt(peak, 4) receives a double.
    final double peak = vals.isEmpty
        ? 0.0
        : vals
            .map((v) => v.abs())
            .fold<double>(
              0.0,
              (a, b) => math.max(a, b).toDouble(),
            );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // TITLE
          // ======================================================
          Text(
            s.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Pick a signal, move the sliders, and read the plot, stats and table below.',
            style: TextStyle(
              color: AppColors.ink2,
              fontSize: 13.5,
            ),
          ),

          const SizedBox(height: 14),

          // ======================================================
          // SIGNAL PICKER
          // ======================================================
          for (final cat in ['basic', 'exp', 'other'])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in _sigs.entries.where(
                    (e) => e.value.cat == cat,
                  ))
                    ChoiceChip(
                      label: Text(e.value.name),
                      selected: cur == e.key,
                      onSelected: (_) => _select(e.key),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 6),

          // ======================================================
          // CUSTOM SIGNAL
          // ======================================================
          if (s.custom)
            SectionCard(
              child: SignalInput(
                title: 'Your signal',
                color: AppColors.blue,
                defaultExpr: '0.9^n*cos(pi*n/6)*u[n]',
                exprRange: const [-5, 30],
                presets: [
                  SignalPreset(
                    'Symmetric pulse 1, 2, [3], 2, 1',
                    () => const Signal(
                      -2,
                      [1, 2, 3, 2, 1],
                    ),
                  ),
                  SignalPreset(
                    'Textbook {[1], 2, −1, 3}',
                    () => const Signal(
                      0,
                      [1, 2, -1, 3],
                    ),
                  ),
                  SignalPreset(
                    'Staircase',
                    () => const Signal(
                      0,
                      [1, 1, 2, 2, 3, 3, 0],
                    ),
                  ),
                ],
                onChange: (v) {
                  setState(() {
                    customSig = v;
                  });
                },
              ),
            )
          else
            // ====================================================
            // PARAMETERS
            // ====================================================
            SectionCard(
              title: 'Parameters',
              child: Column(
                children: [
                  for (final p in s.params)
                    ParamSlider(
                      label: p.label,
                      value: params[p.key] ?? p.def,
                      min: p.min,
                      max: p.max,
                      divisions: ((p.max - p.min) / p.step)
                          .round()
                          .clamp(1, 10000)
                          .toInt(),
                      readout: p.isPi
                          ? '${fmt(params[p.key])}π'
                          : fmt(params[p.key]),
                      onChanged: (v) {
                        setState(() {
                          params[p.key] = v;
                        });
                      },
                    ),
                ],
              ),
            ),

          // ======================================================
          // VIEW WINDOW
          // ======================================================
          SectionCard(
            title: 'View window',
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('a$cur'),
                    initialValue: '$nA',
                    decoration: const InputDecoration(
                      labelText: 'from n =',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    onChanged: (v) {
                      setState(() {
                        nA = int.tryParse(v) ?? nA;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('b$cur'),
                    initialValue: '$nB',
                    decoration: const InputDecoration(
                      labelText: 'to n =',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    onChanged: (v) {
                      setState(() {
                        nB = int.tryParse(v) ?? nB;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // LABEL SWITCH
          // ======================================================
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: showLabels,
            title: const Text(
              'Show sample values on plot',
              style: TextStyle(fontSize: 13.5),
            ),
            onChanged: (v) {
              setState(() {
                showLabels = v ?? false;
              });
            },
          ),

          // ======================================================
          // ORIGINAL SIGNAL PLOT
          // ======================================================
          SectionCard(
            title: 'x[n]',
            subtitle: 'n from $nA to $nB',
            child: SignalPlot(
              height: 240,
              series: [
                PlotSeries(
                  type: SeriesType.stem,
                  x: ns.map((e) => e.toDouble()).toList(),
                  y: sig.v,
                  color: AppColors.blue,
                  labels: showLabels,
                ),
              ],
            ),
          ),

          // ======================================================
          // EVEN / ODD THEORY
          // ======================================================
          SectionCard(
            title: 'Even and odd decomposition',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Every discrete-time signal can be separated into an even part and an odd part:',
                  style: TextStyle(
                    color: AppColors.ink2,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'x[n] = xₑ[n] + xₒ[n]',
                  style: AppTheme.mathStyle.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'xₑ[n] = (x[n] + x[−n]) / 2',
                  style: AppTheme.mathStyle.copyWith(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'xₒ[n] = (x[n] − x[−n]) / 2',
                  style: AppTheme.mathStyle.copyWith(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'The even part is symmetric about n = 0, while the odd part is antisymmetric about n = 0.',
                  style: TextStyle(
                    color: AppColors.ink2,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // EVEN PART PLOT
          // ======================================================
          SectionCard(
            title: 'Even part xₑ[n]',
            subtitle: 'xₑ[n] = (x[n] + x[−n]) / 2',
            child: SignalPlot(
              height: 220,
              series: [
                PlotSeries(
                  type: SeriesType.stem,
                  x: ns.map((e) => e.toDouble()).toList(),
                  y: evenValues,
                  color: AppColors.green,
                  labels: showLabels,
                ),
              ],
            ),
          ),

          // ======================================================
          // ODD PART PLOT
          // ======================================================
          SectionCard(
            title: 'Odd part xₒ[n]',
            subtitle: 'xₒ[n] = (x[n] − x[−n]) / 2',
            child: SignalPlot(
              height: 220,
              series: [
                PlotSeries(
                  type: SeriesType.stem,
                  x: ns.map((e) => e.toDouble()).toList(),
                  y: oddValues,
                  color: AppColors.rasp,
                  labels: showLabels,
                ),
              ],
            ),
          ),

          // ======================================================
          // DEFINITION
          // ======================================================
          SectionCard(
            title: 'Definition',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.custom ? _customEq(params) : s.eq(params),
                  style: AppTheme.mathStyle.copyWith(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.desc,
                  style: const TextStyle(
                    color: AppColors.ink2,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Worth remembering',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                for (final pr in s.props)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '•  $pr',
                      style: const TextStyle(
                        color: AppColors.ink2,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ======================================================
          // STATS
          // ======================================================
          SectionCard(
            title: 'Measured over the window',
            child: StatGrid([
              MapEntry(
                'Energy  Σ|x[n]|²',
                fmt(energy, 4),
              ),
              MapEntry(
                'Average power',
                fmt(
                  sampleCount == 0
                      ? 0
                      : energy / sampleCount,
                  4,
                ),
              ),
              MapEntry(
                'Samples in window',
                '$sampleCount',
              ),
              MapEntry(
                'Mean',
                fmt(mean, 4),
              ),
              MapEntry(
                'Peak |x[n]|',
                fmt(peak, 4),
              ),
            ]),
          ),

          // ======================================================
          // SAMPLE TABLE
          // ======================================================
          SectionCard(
            title: 'Sample values',
            subtitle: 'highlighted column is n = 0',
            child: ValueTable(
              ns: ns,
              rows: [
                MapEntry(
                  'x[n]',
                  vals.map((v) => fmt(v, 3)).toList(),
                ),
                MapEntry(
                  'xₑ[n]',
                  evenValues.map((v) => fmt(v, 3)).toList(),
                ),
                MapEntry(
                  'xₒ[n]',
                  oddValues.map((v) => fmt(v, 3)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
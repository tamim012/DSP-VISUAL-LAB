import 'dart:async';

import 'package:flutter/material.dart';

import '../dsp/signal.dart';
import '../theme/app_theme.dart';
import '../widgets/signal_input.dart';
import '../widgets/stem_plot.dart';
import '../widgets/ui_kit.dart';

Signal _reverseSignal(Signal signal) {
  final reversedValues = signal.v.reversed.toList();

  return Signal(
    -sigEnd(signal),
    reversedValues,
  );
}

class ConvolutionScreen extends StatefulWidget {
  const ConvolutionScreen({super.key});

  @override
  State<ConvolutionScreen> createState() =>
      _ConvolutionScreenState();
}

class _ConvolutionScreenState
    extends State<ConvolutionScreen> {
  String mode = 'conv';

  Signal x = const Signal(
    0,
    [1, 2, 3],
  );

  Signal h = const Signal(
    0,
    [1, 1, 1],
  );

  int curN = 0;

  bool initialized = false;

  Timer? timer;

  int speedMs = 650;

  bool showLabels = true;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Signal get _hEff {
    final base = mode == 'acorr' ? x : h;

    if (mode == 'conv') {
      return base;
    }

    return _reverseSignal(base);
  }

  (int, int) get _support {
    final effectiveH = _hEff;

    return (
      x.n0 + effectiveH.n0,
      sigEnd(x) + sigEnd(effectiveH),
    );
  }

  double _yAt(int n) {
    final effectiveH = _hEff;

    double sum = 0;

    for (
      int k = x.n0;
      k <= sigEnd(x);
      k++
    ) {
      sum +=
          sigAt(x, k) *
          sigAt(effectiveH, n - k);
    }

    return sum;
  }

  void _ensureCurN() {
    final support = _support;
    final start = support.$1;
    final end = support.$2;

    if (!initialized ||
        curN < start ||
        curN > end) {
      curN = start;
      initialized = true;
    }
  }

  void _play() {
    final support = _support;
    final start = support.$1;
    final end = support.$2;

    if (timer != null) {
      timer!.cancel();

      setState(() {
        timer = null;
      });

      return;
    }

    if (curN >= end) {
      curN = start;
    }

    timer = Timer.periodic(
      Duration(milliseconds: speedMs),
      (t) {
        if (!mounted) {
          t.cancel();
          return;
        }

        setState(() {
          if (curN >= end) {
            t.cancel();
            timer = null;
          } else {
            curN++;
          }
        });
      },
    );

    setState(() {});
  }

  void _stop() {
    timer?.cancel();
    timer = null;
  }

  void _changeMode(String newMode) {
    _stop();

    setState(() {
      mode = newMode;
      initialized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    _ensureCurN();

    final support = _support;
    final a = support.$1;
    final b = support.$2;

    final effectiveH = _hEff;

    final outNs = range(a, b);

    final yFull = <double>[
      for (final n in outNs)
        n <= curN ? _yAt(n) : double.nan,
    ];

    final kLoCandidates = [
      x.n0,
      curN - sigEnd(effectiveH),
    ];

    final kHiCandidates = [
      sigEnd(x),
      curN - effectiveH.n0,
    ];

    final kLo = kLoCandidates.reduce(
      (value, element) =>
          value < element ? value : element,
    );

    final kHi = kHiCandidates.reduce(
      (value, element) =>
          value > element ? value : element,
    );

    final ks = range(kLo, kHi);

    final rowX = ks
        .map((k) => sigAt(x, k))
        .toList();

    final rowH = ks
        .map(
          (k) => sigAt(
            effectiveH,
            curN - k,
          ),
        )
        .toList();

    final rowP = List<double>.generate(
      ks.length,
      (i) => rowX[i] * rowH[i],
    );

    final yCur = rowP.fold<double>(
      0,
      (previous, current) =>
          previous + current,
    );

    final title = {
      'conv': 'Convolution',
      'xcorr': 'Cross-correlation',
      'acorr': 'Autocorrelation',
    }[mode]!;

    final equation = {
      'conv': 'y[n] = Σₖ x[k]·h[n−k]',
      'xcorr': 'r[n] = Σₖ x[k]·h[k−n]',
      'acorr': 'r[n] = Σₖ x[k]·x[k−n]',
    }[mode]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Flip, shift, multiply, add. Drag the slider or press play to build the output one sample at a time.',
            style: TextStyle(
              color: AppColors.ink2,
              fontSize: 13.5,
            ),
          ),

          const SizedBox(height: 14),

          SectionCard(
            title: 'What to compute',
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text(
                    'Convolution',
                  ),
                  selected: mode == 'conv',
                  onSelected: (_) =>
                      _changeMode('conv'),
                ),
                ChoiceChip(
                  label: const Text(
                    'Cross-correlation',
                  ),
                  selected: mode == 'xcorr',
                  onSelected: (_) =>
                      _changeMode('xcorr'),
                ),
                ChoiceChip(
                  label: const Text(
                    'Autocorrelation',
                  ),
                  selected: mode == 'acorr',
                  onSelected: (_) =>
                      _changeMode('acorr'),
                ),
              ],
            ),
          ),

          SectionCard(
            title: mode == 'acorr'
                ? 'Signal x[n]'
                : 'First signal x[k]',
            child: SignalInput(
              title: '',
              color: AppColors.blue,
              defaultPreset: 0,
              presets: [
                SignalPreset(
                  'Pulse {1,2,3}',
                  () => const Signal(
                    0,
                    [1, 2, 3],
                  ),
                ),
                SignalPreset(
                  'Textbook {[1],2,3,4}',
                  () => const Signal(
                    0,
                    [1, 2, 3, 4],
                  ),
                ),
                SignalPreset(
                  'Symmetric {1,2,[3],2,1}',
                  () => const Signal(
                    -2,
                    [1, 2, 3, 2, 1],
                  ),
                ),
                SignalPreset(
                  'Alternating {1,-1,1,-1}',
                  () => const Signal(
                    0,
                    [1, -1, 1, -1],
                  ),
                ),
              ],
              onChange: (value) {
                setState(() {
                  x = value;
                  initialized = false;
                });
              },
            ),
          ),

          if (mode != 'acorr')
            SectionCard(
              title: 'Second signal h[k]',
              child: SignalInput(
                title: '',
                color: AppColors.rasp,
                defaultPreset: 0,
                presets: [
                  SignalPreset(
                    'Pulse {1,1,1}',
                    () => const Signal(
                      0,
                      [1, 1, 1],
                    ),
                  ),
                  SignalPreset(
                    'Decaying {1,0.5,0.25}',
                    () => const Signal(
                      0,
                      [1, 0.5, 0.25],
                    ),
                  ),
                  SignalPreset(
                    'Step-down {2,1,0,-1}',
                    () => const Signal(
                      0,
                      [2, 1, 0, -1],
                    ),
                  ),
                ],
                onChange: (value) {
                  setState(() {
                    h = value;
                    initialized = false;
                  });
                },
              ),
            ),

          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: showLabels,
            title: const Text(
              'Show sample values',
              style: TextStyle(
                fontSize: 13.5,
              ),
            ),
            onChanged: (value) {
              setState(() {
                showLabels = value ?? true;
              });
            },
          ),

          SectionCard(
            title: 'Playback speed',
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 1100,
                  label: Text('Slow'),
                ),
                ButtonSegment(
                  value: 650,
                  label: Text('Normal'),
                ),
                ButtonSegment(
                  value: 300,
                  label: Text('Fast'),
                ),
              ],
              selected: {speedMs},
              onSelectionChanged: (values) {
                setState(() {
                  speedMs = values.first;
                });
              },
            ),
          ),

          SectionCard(
            title: equation,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.skip_previous,
                      ),
                      onPressed: () {
                        _stop();

                        setState(() {
                          curN = (curN - 1)
                              .clamp(a, b)
                              .toInt();
                        });
                      },
                    ),

                    FilledButton(
                      onPressed: _play,
                      child: Text(
                        timer != null
                            ? 'Pause'
                            : 'Play',
                      ),
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.skip_next,
                      ),
                      onPressed: () {
                        _stop();

                        setState(() {
                          curN = (curN + 1)
                              .clamp(a, b)
                              .toInt();
                        });
                      },
                    ),

                    const SizedBox(width: 8),

                    Text(
                      'n = $curN',
                      style: AppTheme.numStyle
                          .copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                Slider(
                  value: curN.toDouble(),
                  min: a.toDouble(),
                  max: b.toDouble(),
                  divisions:
                      (b - a) > 0 ? b - a : 1,
                  label: '$curN',
                  onChanged: (value) {
                    _stop();

                    setState(() {
                      curN = value.round();
                    });
                  },
                ),

                const SizedBox(height: 6),

                const Text(
                  'x[k]: the first signal, fixed',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.ink3,
                  ),
                ),

                ValueTable(
                  ns: ks,
                  rows: [
                    MapEntry(
                      'x[k]',
                      rowX
                          .map(
                            (value) =>
                                fmt(value, 3),
                          )
                          .toList(),
                    ),
                    MapEntry(
                      mode == 'conv'
                          ? 'h[n−k]'
                          : (mode == 'acorr'
                              ? 'x[k−n]'
                              : 'h[k−n]'),
                      rowH
                          .map(
                            (value) =>
                                fmt(value, 3),
                          )
                          .toList(),
                    ),
                    MapEntry(
                      'product',
                      rowP
                          .map(
                            (value) =>
                                fmt(value, 3),
                          )
                          .toList(),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'y[$curN] = Σ product = ${fmt(yCur, 4)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          SectionCard(
            title: 'Output',
            subtitle: 'n from $a to $b',
            child: SignalPlot(
              height: 220,
              highlightN: curN,
              series: [
                PlotSeries(
                  type: SeriesType.stem,
                  x: outNs
                      .map(
                        (value) =>
                            value.toDouble(),
                      )
                      .toList(),
                  y: yFull,
                  color: AppColors.green,
                  labels: showLabels,
                ),
              ],
            ),
          ),

          SectionCard(
            title: 'Result at a glance',
            child: StatGrid(
              [
                MapEntry(
                  'Output length',
                  '${b - a + 1} samples (n = $a … $b)',
                ),
                MapEntry(
                  'Energy so far',
                  fmt(
                    yFull
                        .where(
                          (value) =>
                              !value.isNaN,
                        )
                        .fold<double>(
                          0,
                          (previous, current) =>
                              previous +
                              current * current,
                        ),
                    4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
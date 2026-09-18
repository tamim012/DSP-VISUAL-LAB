import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../dsp/fourier.dart';
import '../dsp/signal.dart';
import '../theme/app_theme.dart';
import '../widgets/signal_input.dart';
import '../widgets/stem_plot.dart';
import '../widgets/ui_kit.dart';

enum _Tab {
  dtfs,
  dtft,
  fft,
  ifft,
}

class TransformsScreen extends StatefulWidget {
  const TransformsScreen({super.key});

  @override
  State<TransformsScreen> createState() =>
      _TransformsScreenState();
}

class _TransformsScreenState
    extends State<TransformsScreen> {
  _Tab tab = _Tab.dtfs;

  Signal sig = const Signal(
    0,
    [1, 2, 3, 2, 1, 0, 0, 0],
  );

  int kMax = 5;
  int periods = 3;

  String dtftAxis = '-pi';

  bool db = false;
  bool realImag = false;
  bool markFft = false;

  int mSample = 16;

  bool tone1 = true;
  bool tone2 = true;
  bool tone3 = false;

  double f1 = 12.5;
  double a1 = 1.0;
  double p1 = 0.0;

  double f2 = 30.0;
  double a2 = 0.5;
  double p2 = 0.0;

  double f3 = 70.0;
  double a3 = 0.3;
  double p3 = 0.0;

  double noise = 0.0;
  double fs = 100.0;

  int sampleCount = 64;

  String window = 'Rectangular';
  String zeroPadding = 'None';
  String fftAxis = 'Frequency Hz';
  String fftHeight = 'Amplitude estimate';

  bool twoSided = false;
  bool showPhase = false;

  int ifftN = 16;

  bool realMirror = true;

  String preset =
      'Bin k = 1 and its mirror → one cosine';

  List<double> ifftMag =
      List<double>.filled(16, 0);

  List<double> ifftPhase =
      List<double>.filled(16, 0);

  static const Map<
      _Tab,
      (String, String)> tabInfo = {
    _Tab.dtfs: (
      'DTFS',
      'periodic signals, N coefficients',
    ),
    _Tab.dtft: (
      'DTFT',
      'aperiodic signals, continuous ω',
    ),
    _Tab.fft: (
      'FFT',
      'N samples in, N frequency bins out',
    ),
    _Tab.ifft: (
      'Inverse FFT',
      'draw a spectrum, get the signal',
    ),
  };

  static const List<String> ifftPresets = [
    'Bin k = 1 and its mirror → one cosine',
    'Bins 1 and 3 → two cosines',
    'Only X[0] → constant (DC)',
    'Flat magnitude, zero phase → impulse',
    'Flat magnitude, linear phase → delayed impulse',
    'Low bins |k| ≤ 2 → smooth pulse',
    'Bin N/2 → fastest signal (−1)^n',
    'Single bin k = 2, no mirror → complex exponential',
  ];

  @override
  void initState() {
    super.initState();

    _loadIfftPresetValues();
  }

  void _loadIfftPresetValues() {
    final n = ifftN;

    final magnitude =
        List<double>.filled(n, 0);

    final phase =
        List<double>.filled(n, 0);

    if (preset.startsWith('Bin k = 1')) {
      if (n > 1) {
        magnitude[1] = 1;
        magnitude[n - 1] = 1;
      }
    } else if (preset.startsWith('Bins 1 and 3')) {
      if (n > 1) {
        magnitude[1] = 1;
        magnitude[n - 1] = 1;
      }

      if (n > 3) {
        magnitude[3] = 0.7;
        magnitude[n - 3] = 0.7;
      }
    } else if (preset.startsWith('Only X[0]')) {
      magnitude[0] = 2;
    } else if (
        preset.startsWith(
          'Flat magnitude, zero',
        )) {
      for (int i = 0; i < n; i++) {
        magnitude[i] = 1;
      }
    } else if (
        preset.startsWith(
          'Flat magnitude, linear',
        )) {
      for (int i = 0; i < n; i++) {
        magnitude[i] = 1;

        phase[i] =
            -2 *
            math.pi *
            i *
            2 /
            n;
      }
    } else if (
        preset.startsWith('Low bins')) {
      for (int i = 0; i < n; i++) {
        final k =
            math.min(i, n - i);

        if (k <= 2) {
          magnitude[i] = 1;
        }
      }
    } else if (
        preset.startsWith('Bin N/2')) {
      magnitude[n ~/ 2] = 1;
    } else {
      if (n > 2) {
        magnitude[2] = 1;
      }
    }

    ifftMag = magnitude;
    ifftPhase = phase;
  }

  void _applyIfftPreset() {
    setState(() {
      _loadIfftPresetValues();
    });
  }

  SignalInput _input({
    bool periodic = false,
  }) {
    return SignalInput(
      title: '',
      color: AppColors.blue,
      defaultExpr: 'cos(pi*n/4)',
      exprRange: const [0, 15],
      presets: [
        SignalPreset(
          'Pulse {1,2,3,2,1,0,0,0}',
          () => const Signal(
            0,
            [1, 2, 3, 2, 1, 0, 0, 0],
          ),
        ),
        SignalPreset(
          'Rectangular window (8 samples)',
          () => sigFromFn(
            (n) => 1.0,
            0,
            7,
          ),
        ),
        SignalPreset(
          'Cosine, 8 samples',
          () => sigFromFn(
            (n) =>
                math.cos(
                  math.pi * n / 4,
                ),
            0,
            7,
          ),
        ),
        SignalPreset(
          'Impulse {1,0,0,0}',
          () => const Signal(
            0,
            [1, 0, 0, 0],
          ),
        ),
      ],
      onChange: (value) {
        setState(() {
          sig = value;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (tab == _Tab.dtfs) {
      content = _dtfs();
    } else if (tab == _Tab.dtft) {
      content = _dtft();
    } else if (tab == _Tab.fft) {
      content = _fft();
    } else {
      content = _ifft();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        50,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'DTFS, DTFT and FFT',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Fourier series, the DTFT, the FFT in hertz, and building signals with the inverse FFT.',
            style: TextStyle(
              color: AppColors.ink2,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection:
                Axis.horizontal,
            child: Row(
              children: [
                for (final entry
                    in tabInfo.entries)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      right: 8,
                    ),
                    child: ChoiceChip(
                      label: SizedBox(
                        width: 145,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Text(
                              entry.value.$1,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            Text(
                              entry.value.$2,
                              style:
                                  const TextStyle(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      selected:
                          tab == entry.key,
                      onSelected: (_) {
                        setState(() {
                          tab = entry.key;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _dtfs() {
    final n = sig.v.length;

    if (n == 0) {
      return const SectionCard(
        title: 'DTFS',
        child: Text(
          'Enter at least one sample.',
        ),
      );
    }

    final spectrum =
        dft(sig.v, null);

    final coefficientMagnitude =
        List<double>.generate(
      n,
      (k) {
        final re = spectrum.re[k];
        final im = spectrum.im[k];

        return math
            .sqrt(re * re + im * im)
            .toDouble() /
            n;
      },
    );

    final sampleX =
        List<double>.generate(
      n,
      (i) => i.toDouble(),
    );

    final reconstruction =
        List<double>.filled(n, 0);

    for (int i = 0; i < n; i++) {
      double value = 0;

      for (int k = 0; k < n; k++) {
        final signedK =
            k <= n ~/ 2
                ? k
                : k - n;

        if (signedK.abs() <= kMax) {
          final ar =
              spectrum.re[k] / n;

          final ai =
              spectrum.im[k] / n;

          final angle =
              2 *
              math.pi *
              k *
              i /
              n;

          value +=
              ar * math.cos(angle) -
              ai * math.sin(angle);
        }
      }

      reconstruction[i] =
          value;
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: 'One period of x[n]',
          child: _input(periodic: true),
        ),

        SectionCard(
          title: 'Reconstruction',
          child: Column(
            children: [
              ParamSlider(
                label:
                    'Harmonics used, |k| ≤ K',
                value: kMax.toDouble(),
                min: 0,
                max: 5,
                divisions: 5,
                readout: 'K = $kMax',
                onChanged: (value) {
                  setState(() {
                    kMax = value.round();
                  });
                },
              ),

              ParamSlider(
                label: 'Periods shown',
                value: periods.toDouble(),
                min: 2,
                max: 6,
                divisions: 4,
                readout: '$periods',
                onChanged: (value) {
                  setState(() {
                    periods =
                        value.round();
                  });
                },
              ),

              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title: const Text(
                  'Centre k around 0',
                ),
                value: true,
                onChanged: (_) {},
              ),
            ],
          ),
        ),

        SectionCard(
          title:
              'Periodic signal and its reconstruction',
          child: SignalPlot(
            height: 250,
            series: [
              PlotSeries(
                type: SeriesType.stem,
                x: sampleX,
                y: sig.v,
                color: AppColors.blue,
                labels: true,
              ),
              PlotSeries(
                type: SeriesType.line,
                x: sampleX,
                y: reconstruction,
                color: AppColors.green,
                width: 2,
              ),
            ],
          ),
        ),

        SectionCard(
          title: 'DTFS definition',
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'x[n] = Σₖ₌₀ᴺ⁻¹ cₖ e^(j2πkn/N)',
                style:
                    AppTheme.mathStyle
                        .copyWith(
                  fontSize: 18,
                ),
              ),
              Text(
                'cₖ = (1/N) Σₙ₌₀ᴺ⁻¹ x[n] e^(−j2πkn/N)',
                style:
                    AppTheme.mathStyle
                        .copyWith(
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A periodic signal repeats every N samples, so it has exactly N Fourier-series coefficients at harmonics of ω₀ = 2π/N. The left side is synthesis; the coefficient sum on the right is analysis.',
                style: TextStyle(
                  color: AppColors.ink2,
                  height: 1.45,
                ),
              ),
              const NoteBox(
                'Keeping only |k| ≤ K is a Fourier-series approximation: fewer harmonics give a smoother reconstruction.',
                color: AppColors.blue,
                bg: AppColors.blueSoft,
              ),
            ],
          ),
        ),

        SectionCard(
          title: 'Coefficient magnitude |cₖ|',
          child: SignalPlot(
            height: 200,
            xLabel: 'k',
            series: [
              PlotSeries(
                type: SeriesType.stem,
                x: sampleX,
                y: coefficientMagnitude,
                color: AppColors.blue,
                labels: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dtft() {
    final double lo;

    final double hi;

    if (dtftAxis == '-3pi') {
      lo = -3 * math.pi;
      hi = 3 * math.pi;
    } else if (dtftAxis == '0-2pi') {
      lo = 0;
      hi = 2 * math.pi;
    } else {
      lo = -math.pi;
      hi = math.pi;
    }

    final frequencies =
        linspace(
      lo,
      hi,
      400,
    );

    final spectrum =
        dtft(
      sig,
      frequencies,
    );

    final magnitude =
        List<double>.generate(
      frequencies.length,
      (i) {
        final re =
            spectrum.re[i];

        final im =
            spectrum.im[i];

        return math
            .sqrt(re * re + im * im)
            .toDouble();
      },
    );

    final phase =
        List<double>.generate(
      frequencies.length,
      (i) {
        return math.atan2(
          spectrum.im[i],
          spectrum.re[i],
        );
      },
    );

    final shownMagnitude =
        db
            ? magnitude.map(
                (value) {
                  return 20 *
                      math.log(
                        math.max(
                          value,
                          1e-12,
                        ),
                      ) /
                      math.ln10;
                },
              ).toList()
            : magnitude;

    final xAtZero =
        sig.v.fold<double>(
      0,
      (previous, value) =>
          previous + value,
    );

    final xAtPi =
        List<double>.generate(
          sig.v.length,
          (i) =>
              sig.v[i] *
              (i.isEven ? 1 : -1),
        ).fold<double>(
          0,
          (previous, value) =>
              previous + value,
        );

    final energy =
        sig.v.fold<double>(
      0,
      (previous, value) =>
          previous + value * value,
    );

    return Column(
      children: [
        SectionCard(
          title: 'Signal x[n]',
          child: _input(),
        ),

        SectionCard(
          title: 'Frequency axis',
          child: Column(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: '-pi',
                    label: Text(
                      '−π to π',
                    ),
                  ),
                  ButtonSegment(
                    value: '0-2pi',
                    label: Text(
                      '0 to 2π',
                    ),
                  ),
                  ButtonSegment(
                    value: '-3pi',
                    label: Text(
                      '−3π to 3π',
                    ),
                  ),
                ],
                selected: {dtftAxis},
                onSelectionChanged:
                    (values) {
                  setState(() {
                    dtftAxis =
                        values.first;
                  });
                },
              ),

              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title: const Text(
                  'Magnitude in dB',
                ),
                value: db,
                onChanged: (value) {
                  setState(() {
                    db = value;
                  });
                },
              ),

              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title: const Text(
                  'Show real and imaginary parts instead of phase',
                ),
                value: realImag,
                onChanged: (value) {
                  setState(() {
                    realImag = value;
                  });
                },
              ),

              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title: const Text(
                  'Mark FFT samples',
                ),
                value: markFft,
                onChanged: (value) {
                  setState(() {
                    markFft = value;
                  });
                },
              ),

              if (markFft)
                ParamSlider(
                  label:
                      'Number FFT samples M',
                  value:
                      mSample.toDouble(),
                  min: 4,
                  max: 64,
                  divisions: 60,
                  readout:
                      '$mSample',
                  onChanged: (value) {
                    setState(() {
                      mSample =
                          value.round();
                    });
                  },
                ),
            ],
          ),
        ),

        SectionCard(
          title:
              'Magnitude |X(eʲω)|',
          subtitle:
              'continuous ω',
          child: SignalPlot(
            height: 230,
            xLabel: 'ω',
            series: [
              PlotSeries(
                type:
                    SeriesType.line,
                x: frequencies,
                y: shownMagnitude,
                color:
                    AppColors.blue,
              ),
            ],
          ),
        ),

        SectionCard(
          title: realImag
              ? 'Real and imaginary parts'
              : 'Phase ∠X(eʲω)',
          child: SignalPlot(
            height: 190,
            xLabel: 'ω',
            yRange: realImag
                ? null
                : const [-3.5, 3.5],
            series: realImag
                ? [
                    PlotSeries(
                      type:
                          SeriesType.line,
                      x: frequencies,
                      y: spectrum.re,
                      color:
                          AppColors.green,
                    ),
                    PlotSeries(
                      type:
                          SeriesType.line,
                      x: frequencies,
                      y: spectrum.im,
                      color:
                          AppColors.rasp,
                    ),
                  ]
                : [
                    PlotSeries(
                      type:
                          SeriesType.line,
                      x: frequencies,
                      y: phase,
                      color:
                          AppColors.rasp,
                    ),
                  ],
          ),
        ),

        SectionCard(
          title:
              'DTFT notes and checks',
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'The spectrum repeats every 2π. Choose −3π to 3π to see repeated copies.',
              ),
              const SizedBox(height: 6),
              const Text(
                'For a real signal, |X| is even and phase is odd (apart from phase wrapping).',
              ),
              const SizedBox(height: 6),
              const Text(
                'If FFT sample M is smaller than the signal length, those samples do not uniquely describe x[n].',
              ),
              const SizedBox(height: 8),
              StatGrid(
                [
                  MapEntry(
                    'X(eʲ0)',
                    fmt(xAtZero, 4),
                  ),
                  MapEntry(
                    'X(eʲπ)',
                    fmt(xAtPi, 4),
                  ),
                  MapEntry(
                    'Energy Σ|x[n]|²',
                    fmt(energy, 4),
                  ),
                ],
              ),
              const NoteBox(
                'Parseval: (1/2π) ∫ |X(eʲω)|² dω = Σ |x[n]|².',
                color: AppColors.green,
                bg: AppColors.greenSoft,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<double> _windowValues(
    int n,
  ) {
    if (n <= 0) {
      return <double>[];
    }

    final denominator =
        math.max(1, n - 1)
            .toDouble();

    switch (window) {
      case 'Hann':
        return List<double>.generate(
          n,
          (i) =>
              0.5 -
              0.5 *
                  math.cos(
                    2 *
                        math.pi *
                        i /
                        denominator,
                  ),
        );

      case 'Hamming':
        return List<double>.generate(
          n,
          (i) =>
              0.54 -
              0.46 *
                  math.cos(
                    2 *
                        math.pi *
                        i /
                        denominator,
                  ),
        );

      case 'Blackman':
        return List<double>.generate(
          n,
          (i) =>
              0.42 -
              0.5 *
                  math.cos(
                    2 *
                        math.pi *
                        i /
                        denominator,
                  ) +
              0.08 *
                  math.cos(
                    4 *
                        math.pi *
                        i /
                        denominator,
                  ),
        );

      default:
        return List<double>.filled(
          n,
          1.0,
        );
    }
  }

  Widget _fft() {
    final raw =
        <double>[];

    final windowValues =
        _windowValues(
      sampleCount,
    );

    final rng =
        math.Random(17);

    for (
      int n = 0;
      n < sampleCount;
      n++
    ) {
      double value = 0;

      if (tone1) {
        value +=
            a1 *
            math.cos(
              2 *
                  math.pi *
                  f1 *
                  n /
                  fs +
              p1 *
                  math.pi /
                  180,
            );
      }

      if (tone2) {
        value +=
            a2 *
            math.cos(
              2 *
                  math.pi *
                  f2 *
                  n /
                  fs +
              p2 *
                  math.pi /
                  180,
            );
      }

      if (tone3) {
        value +=
            a3 *
            math.cos(
              2 *
                  math.pi *
                  f3 *
                  n /
                  fs +
              p3 *
                  math.pi /
                  180,
            );
      }

      if (noise > 0) {
        value +=
            noise *
            gaussRand(rng);
      }

      raw.add(value);
    }

    final windowed =
        List<double>.generate(
      sampleCount,
      (i) =>
          raw[i] *
          windowValues[i],
    );

    int multiplier = 1;

    if (zeroPadding == '×2') {
      multiplier = 2;
    } else if (zeroPadding == '×4') {
      multiplier = 4;
    } else if (zeroPadding == '×8') {
      multiplier = 8;
    }

    final targetLength =
        sampleCount *
        multiplier;

    int fftLength = 1;

    while (fftLength <
        targetLength) {
      fftLength *= 2;
    }

    final fftInput = <double>[
      ...windowed,
      ...List<double>.filled(
        fftLength -
            windowed.length,
        0,
      ),
    ];

    final spectrum =
        dft(
      fftInput,
      null,
    );

    final half =
        fftLength ~/ 2;

    final List<int> bins;

    if (twoSided) {
      bins = List<int>.generate(
        fftLength,
        (i) =>
            i -
            half,
      );
    } else {
      bins = List<int>.generate(
        half + 1,
        (i) => i,
      );
    }

    final magnitudes =
        <double>[];

    final phases =
        <double>[];

    for (
      int i = 0;
      i < bins.length;
      i++
    ) {
      final k = twoSided
          ? (i + half) %
              fftLength
          : bins[i];

      final re =
          spectrum.re[k];

      final im =
          spectrum.im[k];

      final magnitude =
          math.sqrt(
        re * re + im * im,
      ).toDouble();

      magnitudes.add(
        _fftAmplitude(
          magnitude,
          k,
          windowValues,
          fftLength,
        ),
      );

      phases.add(
        math.atan2(
          im,
          re,
        ),
      );
    }

    final displayValues =
        _fftDisplayValues(
      magnitudes,
    );

    final xValues =
        <double>[];

    for (
      int i = 0;
      i < bins.length;
      i++
    ) {
      final bin =
          bins[i];

      if (fftAxis == 'bin k') {
        xValues.add(
          bin.toDouble(),
        );
      } else if (
          fftAxis ==
              'normalized ω rad/sample') {
        xValues.add(
          2 *
              math.pi *
              bin /
              fftLength,
        );
      } else {
        xValues.add(
          fs *
              bin /
              fftLength,
        );
      }
    }

    final toneFrequencies = [
      if (tone1) f1,
      if (tone2) f2,
      if (tone3) f3,
    ];

    final hasAliasing =
        toneFrequencies.any(
      (frequency) =>
          frequency > fs / 2,
    );

    bool hasLeakage = false;

    final frequencyResolution =
        fs / sampleCount;

    if (frequencyResolution >
        0) {
      hasLeakage =
          toneFrequencies.any(
        (frequency) {
          final nearest =
              (frequency /
                      frequencyResolution)
                  .round();

          final difference =
              (frequency /
                      frequencyResolution) -
                  nearest;

          return difference
                  .abs() >
              1e-6;
        },
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SectionCard(
          title:
              'Input: sum of sinusoids',
          child: Column(
            children: [
              _tone(
                'Tone 1',
                tone1,
                f1,
                a1,
                p1,
                (value) {
                  setState(() {
                    tone1 = value;
                  });
                },
                (value) {
                  setState(() {
                    f1 = value;
                  });
                },
                (value) {
                  setState(() {
                    a1 = value;
                  });
                },
                (value) {
                  setState(() {
                    p1 = value;
                  });
                },
              ),

              _tone(
                'Tone 2',
                tone2,
                f2,
                a2,
                p2,
                (value) {
                  setState(() {
                    tone2 = value;
                  });
                },
                (value) {
                  setState(() {
                    f2 = value;
                  });
                },
                (value) {
                  setState(() {
                    a2 = value;
                  });
                },
                (value) {
                  setState(() {
                    p2 = value;
                  });
                },
              ),

              _tone(
                'Tone 3',
                tone3,
                f3,
                a3,
                p3,
                (value) {
                  setState(() {
                    tone3 = value;
                  });
                },
                (value) {
                  setState(() {
                    f3 = value;
                  });
                },
                (value) {
                  setState(() {
                    a3 = value;
                  });
                },
                (value) {
                  setState(() {
                    p3 = value;
                  });
                },
              ),

              ParamSlider(
                label:
                    'Added noise σ',
                value: noise,
                min: 0,
                max: 1,
                divisions: 20,
                readout:
                    fmt(noise, 2),
                onChanged: (value) {
                  setState(() {
                    noise = value;
                  });
                },
              ),
            ],
          ),
        ),

        SectionCard(
          title:
              'Sampling and spectrum',
          child: Column(
            children: [
              TextFormField(
                initialValue:
                    fs.toString(),
                decoration:
                    const InputDecoration(
                  labelText:
                      'Sampling frequency Fs (Hz)',
                ),
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  final parsed =
                      double.tryParse(
                    value,
                  );

                  if (parsed != null &&
                      parsed > 0) {
                    setState(() {
                      fs = parsed;
                    });
                  }
                },
              ),

              DropdownButtonFormField<int>(
                initialValue:
                    sampleCount,
                decoration:
                    const InputDecoration(
                  labelText:
                      'N samples',
                ),
                items: [
                  16,
                  32,
                  64,
                  128,
                  256,
                  512,
                  1024,
                ]
                    .map(
                      (value) =>
                          DropdownMenuItem<int>(
                        value: value,
                        child:
                            Text('$value'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    sampleCount =
                        value;
                  });
                },
              ),

              DropdownButtonFormField<String>(
                initialValue: window,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Window',
                ),
                items: [
                  'Rectangular',
                  'Hann',
                  'Hamming',
                  'Blackman',
                ]
                    .map(
                      (value) =>
                          DropdownMenuItem<String>(
                        value: value,
                        child:
                            Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    window = value;
                  });
                },
              ),

              DropdownButtonFormField<String>(
                initialValue:
                    zeroPadding,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Zero-padding',
                ),
                items: [
                  'None',
                  '×2',
                  '×4',
                  '×8',
                ]
                    .map(
                      (value) =>
                          DropdownMenuItem<String>(
                        value: value,
                        child:
                            Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    zeroPadding =
                        value;
                  });
                },
              ),

              DropdownButtonFormField<String>(
                initialValue: fftAxis,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Spectrum axis',
                ),
                items: [
                  'Frequency Hz',
                  'bin k',
                  'normalized ω rad/sample',
                ]
                    .map(
                      (value) =>
                          DropdownMenuItem<String>(
                        value: value,
                        child:
                            Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    fftAxis = value;
                  });
                },
              ),

              DropdownButtonFormField<String>(
                initialValue:
                    fftHeight,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Height',
                ),
                items: [
                  'Amplitude estimate',
                  'Raw |X[k]|',
                  'dB relative to peak',
                ]
                    .map(
                      (value) =>
                          DropdownMenuItem<String>(
                        value: value,
                        child:
                            Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    fftHeight = value;
                  });
                },
              ),

              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title: const Text(
                  'Two-sided spectrum',
                ),
                value: twoSided,
                onChanged: (value) {
                  setState(() {
                    twoSided = value;
                  });
                },
              ),

              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title: const Text(
                  'Show phase',
                ),
                value: showPhase,
                onChanged: (value) {
                  setState(() {
                    showPhase = value;
                  });
                },
              ),
            ],
          ),
        ),

        SectionCard(
          title: 'FFT spectrum',
          child: SignalPlot(
            height: 250,
            xLabel:
                fftAxis ==
                        'Frequency Hz'
                    ? 'Hz'
                    : fftAxis ==
                            'bin k'
                        ? 'k'
                        : 'ω',
            series: [
              PlotSeries(
                type:
                    SeriesType.stem,
                x: xValues,
                y: displayValues,
                color:
                    AppColors.blue,
                labels: false,
              ),

              if (showPhase)
                PlotSeries(
                  type:
                      SeriesType.line,
                  x: xValues,
                  y: phases,
                  color:
                      AppColors.rasp,
                ),
            ],
          ),
        ),

        SectionCard(
          title: 'Time record',
          child: SignalPlot(
            height: 210,
            xLabel: 'n',
            series: [
              PlotSeries(
                type:
                    SeriesType.stem,
                x: List<double>.generate(
                  sampleCount,
                  (i) => i.toDouble(),
                ),
                y: raw,
                color:
                    AppColors.blue,
              ),
              PlotSeries(
                type:
                    SeriesType.line,
                x: List<double>.generate(
                  sampleCount,
                  (i) => i.toDouble(),
                ),
                y: windowed,
                color:
                    AppColors.green,
              ),
            ],
          ),
        ),

        SectionCard(
          title:
              'FFT facts and warnings',
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              StatGrid(
                [
                  MapEntry(
                    'Frequency resolution',
                    '${fmt(fs / sampleCount, 3)} Hz',
                  ),
                  MapEntry(
                    'Bin spacing',
                    '${fmt(fs / fftLength, 3)} Hz',
                  ),
                  MapEntry(
                    'Highest frequency',
                    '${fmt(fs / 2, 3)} Hz',
                  ),
                  MapEntry(
                    'Record length',
                    '${fmt(sampleCount / fs, 4)} s',
                  ),
                ],
              ),

              if (hasAliasing)
                const NoteBox(
                  'Aliasing: at least one tone is above the Nyquist frequency Fs/2.',
                  color: AppColors.amber,
                  bg: AppColors.amberSoft,
                ),

              if (hasLeakage)
                const NoteBox(
                  'Leakage: a tone that is not bin-aligned spreads energy across neighbouring FFT bins.',
                  color: AppColors.amber,
                  bg: AppColors.amberSoft,
                ),

              const NoteBox(
                'Zero-padding adds interpolated FFT samples; it does not improve the true frequency resolution of the recorded data.',
                color: AppColors.blue,
                bg: AppColors.blueSoft,
              ),

              const Text(
                'Bins above N/2 represent negative frequencies in the ordinary unshifted FFT ordering.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _fftAmplitude(
    double magnitude,
    int k,
    List<double> windowValues,
    int fftLength,
  ) {
    if (fftHeight == 'Raw |X[k]|') {
      return magnitude;
    }

    final windowSum =
        windowValues.fold<double>(
      0,
      (previous, value) =>
          previous + value,
    );

    if (fftHeight ==
        'dB relative to peak') {
      return magnitude;
    }

    double amplitude =
        magnitude /
            math.max(
              windowSum,
              1e-12,
            ).toDouble();

    if (!twoSided &&
        k != 0 &&
        k != fftLength ~/ 2) {
      amplitude *= 2;
    }

    return amplitude;
  }

  List<double> _fftDisplayValues(
    List<double> values,
  ) {
    if (fftHeight !=
        'dB relative to peak') {
      return values;
    }

    double peak = 0;

    for (final value in values) {
      if (value > peak) {
        peak = value;
      }
    }

    if (peak <= 0) {
      peak = 1;
    }

    return values.map(
      (value) {
        return 20 *
            math.log(
              math.max(
                value / peak,
                1e-12,
              ),
            ) /
            math.ln10;
      },
    ).toList();
  }

  Widget _tone(
    String label,
    bool enabled,
    double frequency,
    double amplitude,
    double phase,
    ValueChanged<bool> onEnabledChanged,
    ValueChanged<double> onFrequencyChanged,
    ValueChanged<double> onAmplitudeChanged,
    ValueChanged<double> onPhaseChanged,
  ) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding:
              EdgeInsets.zero,
          title: Text(label),
          value: enabled,
          onChanged:
              onEnabledChanged,
        ),

        if (enabled)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue:
                      '$frequency',
                  decoration:
                      const InputDecoration(
                    labelText:
                        'f Hz',
                  ),
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    final parsed =
                        double.tryParse(
                      value,
                    );

                    if (parsed != null) {
                      onFrequencyChanged(
                        parsed,
                      );
                    }
                  },
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: TextFormField(
                  initialValue:
                      '$amplitude',
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Amplitude',
                  ),
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    final parsed =
                        double.tryParse(
                      value,
                    );

                    if (parsed != null) {
                      onAmplitudeChanged(
                        parsed,
                      );
                    }
                  },
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: TextFormField(
                  initialValue:
                      '$phase',
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Phase °',
                  ),
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    final parsed =
                        double.tryParse(
                      value,
                    );

                    if (parsed != null) {
                      onPhaseChanged(
                        parsed,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _ifft() {
    final imaginary =
        List<double>.generate(
      ifftN,
      (i) {
        final magnitude =
            i < ifftMag.length
                ? ifftMag[i]
                : 0.0;

        final phase =
            i < ifftPhase.length
                ? ifftPhase[i]
                : 0.0;

        return magnitude *
            math.sin(phase);
      },
    );

    final realInput =
        List<double>.generate(
      ifftN,
      (i) {
        if (i < ifftMag.length) {
          return ifftMag[i] *
              math.cos(
                ifftPhase[i],
              );
        }

        return 0.0;
      },
    );

    final spectrum =
        dft(
      realInput,
      imaginary,
      inverse: true,
    );

    final sampleX =
        List<double>.generate(
      ifftN,
      (i) => i.toDouble(),
    );

    final phaseForPlot =
        ifftPhase
            .map(
              (value) => value,
            )
            .toList();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SectionCard(
          title:
              'Inverse FFT controls',
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue:
                    preset,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Preset',
                ),
                items:
                    ifftPresets.map(
                  (value) {
                    return DropdownMenuItem<
                        String>(
                      value: value,
                      child: Text(
                        value,
                        overflow:
                            TextOverflow
                                .ellipsis,
                      ),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    preset = value;
                    _loadIfftPresetValues();
                  });
                },
              ),

              DropdownButtonFormField<int>(
                initialValue:
                    ifftN,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Bins N',
                ),
                items: [
                  8,
                  16,
                  32,
                  64,
                ].map(
                  (value) {
                    return DropdownMenuItem<
                        int>(
                      value: value,
                      child: Text(
                        '$value',
                      ),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    ifftN = value;
                    _loadIfftPresetValues();
                  });
                },
              ),

              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title: const Text(
                  'Keep x[n] real (mirror bin k onto N−k)',
                ),
                value: realMirror,
                onChanged: (value) {
                  setState(() {
                    realMirror = value;
                  });
                },
              ),

              const SizedBox(height: 8),

              const Text(
                'Magnitude |X[k]|',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              SizedBox(
                height: 180,
                child: SignalPlot(
                  series: [
                    PlotSeries(
                      type:
                          SeriesType.stem,
                      x: sampleX,
                      y: ifftMag,
                      color:
                          AppColors.amber,
                      labels: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Phase ∠X[k] in radians',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              SizedBox(
                height: 160,
                child: SignalPlot(
                  yRange:
                      const [
                    -math.pi,
                    math.pi,
                  ],
                  series: [
                    PlotSeries(
                      type:
                          SeriesType.stem,
                      x: sampleX,
                      y: phaseForPlot,
                      color:
                          AppColors.rasp,
                    ),
                  ],
                ),
              ),

              Row(
                children: [
                  FilledButton(
                    onPressed:
                        _applyIfftPreset,
                    child: const Text(
                      'Apply typed values',
                    ),
                  ),

                  const SizedBox(width: 8),

                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        ifftMag =
                            List<double>.filled(
                          ifftN,
                          0,
                        );

                        ifftPhase =
                            List<double>.filled(
                          ifftN,
                          0,
                        );
                      });
                    },
                    child: const Text(
                      'Clear all bins',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SectionCard(
          title:
              'Reconstructed x[n]',
          subtitle:
              'N = $ifftN samples',
          child: SignalPlot(
            height: 230,
            series: [
              PlotSeries(
                type:
                    SeriesType.stem,
                x: sampleX,
                y: spectrum.re,
                color:
                    AppColors.green,
                labels: true,
              ),
            ],
          ),
        ),

        SectionCard(
          title:
              'Inverse FFT notes',
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'x[n] = (1/N) Σ X[k]e^(+j2πkn/N).',
              ),
              const SizedBox(height: 6),
              const Text(
                'All zero bins produce the zero signal. Each active bin contributes a complex exponential; a mirrored pair combines into a cosine.',
              ),
              const SizedBox(height: 6),
              const Text(
                'Flat magnitude with zero phase gives an impulse. A straight-line phase −2πkd/N moves an impulse to n=d.',
              ),

              if (!realMirror)
                const NoteBox(
                  'Without conjugate/magnitude mirroring the IFFT can contain an imaginary part; this view plots the real component.',
                  color:
                      AppColors.amber,
                  bg:
                      AppColors.amberSoft,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
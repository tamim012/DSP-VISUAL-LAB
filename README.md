# DSP Visual Lab — Flutter port

A Flutter/Dart re-implementation of the original **DSP Visual Lab** static
HTML/JS site (`index.html`, `signals.html`, `operations.html`,
`convolution.html`, `transforms.html`).

## What was analyzed in the original project

- **Theme**: a light "paper & ink" academic look — off-white background,
  near-black ink text, one accent blue (`#1D5FD1`), plus raspberry/green/amber
  accents for secondary series. Rounded cards, pill-shaped nav/segmented
  buttons, a monospace font for numbers and an italic serif for math.
- **Navigation**: a single shared top bar (`mountTopbar()`) links all 5 pages
  (`Home`, `Signal types`, `Shifting & scaling`, `Convolution & correlation`,
  `DTFS · DTFT · FFT`), with the current page highlighted.
- **Buttons / controls identified per page**, and how they're wired together:
  - **Home**: 4 topic cards → navigate to the other 4 pages.
  - **Signals**: chips select a signal type → parameter sliders rebuild →
    view-window fields + checkboxes → stem plot, equation, stats, value table
    all re-render from the same signal object.
  - **Operations**: an `x[n]` input (presets / typed values / formula) feeds
    an operation tab (shift / reverse / time-scale / amplitude-scale /
    add-multiply, the last needing a second input `x₂[n]`) → parameter
    controls for that operation → `y[n]` is recomputed and plotted next to a
    "ghost" of `x[n]`.
  - **Convolution**: a mode selector (convolution / cross-correlation /
    autocorrelation) plus one or two signal inputs feed a step-through
    player (◀ / Play-Pause / ▶ / scrub slider) that reveals the output one
    sample at a time, backed by a product table (`x[k]`, shifted/flipped
    `h`, product, running sum).
  - **Transforms**: tabs (DTFS / DTFT / FFT / Inverse FFT) around a shared
    FFT/DFT/DTFT math core; a signal (or, for the inverse tab, a spectrum)
    feeds magnitude/phase plots.
- **Shared JS "core"** (`parseSequence`, `compileExpr`, `sigFromFn`, `dft`,
  `fftInPlace`, `dtft`, the hand-rolled canvas `Plot` class) is the part that
  actually had to be ported line-for-line rather than just re-skinned.

## How the Flutter app is structured

```
lib/
  main.dart                     App shell: bottom-nav bar wiring the 5 screens
                                 together (Home/Signals/Operations/Convolution/
                                 Transforms), mirroring mountTopbar()'s links.
  theme/app_theme.dart          Colors + ThemeData ported 1:1 from the CSS
                                 custom properties (--blue, --rasp, --ink, …).
  dsp/
    signal.dart                 Signal model + sigAt/sigEnd/sigFromFn/
                                 parseSequence/fmt (port of the JS "core").
    expr.dart                   Recursive-descent compiler for formula mode
                                 (u[n], d[n], r[n], rect(n,N), cos, sin, exp,
                                 pi, ^ …) — port of compileExpr()/EXPR_FUNCS.
    fourier.dart                fftInPlace / dft / dtft — ported line-for-line.
  widgets/
    stem_plot.dart               CustomPainter port of the canvas Plot class
                                 (grid, zero axis, stems, lines, labels).
    signal_input.dart            Port of signalInput(): Presets / Type values
                                 / Formula segmented control.
    ui_kit.dart                  SectionCard / NoteBox / StatGrid / ParamSlider
                                 / ValueTable — small shared building blocks.
  screens/
    home_screen.dart             4 topic cards → the 4 feature screens.
    signals_screen.dart          10 signal types + custom signal, sliders,
                                 stats, table (subset of the original 14).
    operations_screen.dart       Shift / reverse / time-scale / amplitude
                                 scale / add&multiply.
    convolution_screen.dart      Convolution / cross-correlation /
                                 autocorrelation with a play/step animator.
    transforms_screen.dart       DTFS / DTFT / FFT / inverse-FFT tabs.
```

No third-party packages are required — everything (including the plots) is
built on the stock Flutter SDK, so `flutter pub get` has nothing to fetch
beyond `cupertino_icons`.

## Known simplifications vs. the original site

This is a faithful **functional** port, not a pixel-identical clone — a few
things were intentionally trimmed to keep the app a manageable size:

- Signals: kept the most-used 9 built-in types + "your own signal" (custom
  values/formula), out of the original's 14 (dropped complex exponential,
  damped sinusoid, sinc, and random-noise — the same `SignalInput`/plot
  infrastructure makes these easy to add back).
- Operations: dropped the "combined transform" (`y[n]=A·x[σMn+b]`) tab;
  the other 5 operations are implemented.
- No hover tooltips on the plots (mobile has no hover) — tapping/scrubbing
  the convolution slider is the equivalent interaction instead.
- The even/odd-parts panel and the interactive drag-to-shift animation were
  left out of Operations/Signals to keep scope reasonable; the underlying
  math (`sigAt`, `sigFromFn`) supports adding them.

## Running it

```
cd dsp_flutter
flutter pub get
flutter run            # or: flutter build apk
```

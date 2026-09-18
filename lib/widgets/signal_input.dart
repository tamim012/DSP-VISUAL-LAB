import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../dsp/signal.dart';
import '../dsp/expr.dart';

class SignalPreset {
  final String name;
  final Signal Function() sig;
  const SignalPreset(this.name, this.sig);
}

enum InputMode { preset, typedValues, expr }

/// Lets the user supply a signal three ways, exactly like the original
/// `signalInput()` component: pick a preset, type raw samples (bracket
/// marks n = 0), or type a formula in n (u[n], d[n], r[n], rect(n,N), …).
class SignalInput extends StatefulWidget {
  final String title;
  final Color color;
  final List<SignalPreset> presets;
  final int defaultPreset;
  final String defaultExpr;
  final List<int> exprRange;
  final void Function(Signal) onChange;

  const SignalInput({
    super.key,
    required this.title,
    required this.color,
    required this.presets,
    required this.onChange,
    this.defaultPreset = 0,
    this.defaultExpr = 'u[n] - u[n-5]',
    this.exprRange = const [-10, 10],
  });

  @override
  State<SignalInput> createState() => SignalInputState();
}

class SignalInputState extends State<SignalInput> {
  InputMode mode = InputMode.preset;
  late int presetIdx = widget.defaultPreset;
  final valuesCtrl = TextEditingController(text: '1, 2, [3], 2, 1');
  final startCtrl = TextEditingController(text: '0');
  late final exprCtrl = TextEditingController(text: widget.defaultExpr);
  late final aCtrl = TextEditingController(text: '${widget.exprRange[0]}');
  late final bCtrl = TextEditingController(text: '${widget.exprRange[1]}');
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fire());
  }

  Signal? _read() {
    try {
      if (mode == InputMode.preset) {
        return widget.presets[presetIdx].sig();
      } else if (mode == InputMode.typedValues) {
        return parseSequence(valuesCtrl.text, startCtrl.text);
      } else {
        final f = compileExpr(exprCtrl.text);
        final a = int.tryParse(aCtrl.text) ?? -10;
        final b = int.tryParse(bCtrl.text) ?? 10;
        if (b < a) throw const FormatException('The range end must be at least the start.');
        if (b - a > 600) throw const FormatException('Keep the range to 600 samples or fewer.');
        final s = sigFromFn((n) => f(n.toDouble()), a, b);
        if (s.v.any((x) => x.isNaN)) {
          throw const FormatException(
              'The formula gives an undefined value somewhere in the range (e.g. 1/0). Adjust the range or formula.');
        }
        return s;
      }
    } catch (e) {
      setState(() => error = e is FormatException ? e.message : e.toString());
      return null;
    }
  }

  void fire() {
    setState(() => error = null);
    final s = _read();
    if (s != null) widget.onChange(s);
  }

  @override
  void dispose() {
    valuesCtrl.dispose();
    startCtrl.dispose();
    exprCtrl.dispose();
    aCtrl.dispose();
    bCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 11, height: 11, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
        ]),
        const SizedBox(height: 8),
        SegmentedButton<InputMode>(
          segments: const [
            ButtonSegment(value: InputMode.preset, label: Text('Presets')),
            ButtonSegment(value: InputMode.typedValues, label: Text('Type values')),
            ButtonSegment(value: InputMode.expr, label: Text('Formula')),
          ],
          selected: {mode},
          onSelectionChanged: (s) {
            setState(() => mode = s.first);
            fire();
          },
        ),
        const SizedBox(height: 10),
        if (mode == InputMode.preset)
          DropdownButtonFormField<int>(
            initialValue: presetIdx,
            isExpanded: true,
            items: [
              for (int i = 0; i < widget.presets.length; i++)
                DropdownMenuItem(value: i, child: Text(widget.presets[i].name, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) {
              setState(() => presetIdx = v ?? 0);
              fire();
            },
          ),
        if (mode == InputMode.typedValues) ...[
          const Text('Samples, comma-separated. Put the n = 0 sample in brackets.',
              style: TextStyle(fontSize: 12.5, color: AppColors.ink3)),
          const SizedBox(height: 4),
          TextField(
            controller: valuesCtrl,
            maxLines: 2,
            style: AppTheme.numStyle.copyWith(fontSize: 13.5),
            onChanged: (_) => fire(),
          ),
          const SizedBox(height: 6),
          Row(children: [
            const Text('First sample at n = ', style: TextStyle(fontSize: 13)),
            SizedBox(
              width: 60,
              child: TextField(
                controller: startCtrl,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                onChanged: (_) => fire(),
              ),
            ),
          ]),
        ],
        if (mode == InputMode.expr) ...[
          const Text('Formula in n. Use u[n], d[n] (impulse), r[n] (ramp), rect(n,N), cos, sin, exp, pi, ^.',
              style: TextStyle(fontSize: 12.5, color: AppColors.ink3)),
          const SizedBox(height: 4),
          TextField(controller: exprCtrl, style: AppTheme.numStyle.copyWith(fontSize: 14), onChanged: (_) => fire()),
          const SizedBox(height: 6),
          Row(children: [
            const Text('from n = ', style: TextStyle(fontSize: 13)),
            SizedBox(width: 56, child: TextField(controller: aCtrl, keyboardType: TextInputType.number, onChanged: (_) => fire())),
            const SizedBox(width: 12),
            const Text('to n = ', style: TextStyle(fontSize: 13)),
            SizedBox(width: 56, child: TextField(controller: bCtrl, keyboardType: TextInputType.number, onChanged: (_) => fire())),
          ]),
        ],
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(error!, style: const TextStyle(color: AppColors.errorRed, fontSize: 12.5)),
          ),
      ],
    );
  }
}

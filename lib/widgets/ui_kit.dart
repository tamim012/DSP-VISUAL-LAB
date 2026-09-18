import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A bordered card, mirrors `.figure` / `.explain` panels in the CSS.
class SectionCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  const SectionCard({super.key, this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.rule),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(title!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  if (subtitle != null)
                    Text(subtitle!, style: const TextStyle(fontSize: 12.5, color: AppColors.ink3)),
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// A colored callout box, mirrors `.note` / `.note.amber` in the CSS.
class NoteBox extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  const NoteBox(this.text, {super.key, this.color = AppColors.blue, this.bg = AppColors.blueSoft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border(left: BorderSide(color: color, width: 3)),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.4)),
    );
  }
}

/// Grid of small labeled stat chips, mirrors `.stats`/`.stat` in the CSS.
class StatGrid extends StatelessWidget {
  final List<MapEntry<String, String>> stats;
  const StatGrid(this.stats, {super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in stats)
          Container(
            constraints: const BoxConstraints(minWidth: 130),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.rule),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.key, style: const TextStyle(fontSize: 11.5, color: AppColors.ink3)),
                const SizedBox(height: 2),
                Text(e.value, style: AppTheme.numStyle.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }
}

/// A labeled slider row with a live numeric readout, mirrors `.field`.
class ParamSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min, max;
  final int? divisions;
  final String readout;
  final ValueChanged<double> onChanged;
  const ParamSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.readout,
    required this.onChanged,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.ink2)),
            Text(readout, style: AppTheme.numStyle.copyWith(fontSize: 12.5)),
          ]),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(trackHeight: 3),
            child: Slider(value: value.clamp(min, max).toDouble(), min: min, max: max, divisions: divisions, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

/// Horizontally-scrollable sample-value table, mirrors `table.vals`.
class ValueTable extends StatelessWidget {
  final List<int> ns;
  final List<MapEntry<String, List<String>>> rows; // label -> values aligned with ns
  const ValueTable({super.key, required this.ns, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (ns.length > 80) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('Table hidden: more than 80 samples. Shorten the window to see every value.',
            style: TextStyle(fontSize: 12.5, color: AppColors.ink3)),
      );
    }
    Widget cell(String text, {bool header = false, bool zero = false}) => Container(
          width: 46,
          padding: const EdgeInsets.symmetric(vertical: 5),
          alignment: Alignment.center,
          color: zero ? AppColors.amberSoft : (header ? AppColors.panel : null),
          child: Text(text,
              style: AppTheme.numStyle.copyWith(
                  fontSize: 12.5, fontWeight: header || zero ? FontWeight.w700 : FontWeight.w400, color: AppColors.ink2)),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.rule), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Row(children: [
              cell('n', header: true),
              for (final n in ns) cell('$n', zero: n == 0),
            ]),
            for (final r in rows)
              Row(children: [
                cell(r.key, header: true),
                for (final v in r.value) cell(v),
              ]),
          ],
        ),
      ),
    );
  }
}

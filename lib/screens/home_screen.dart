import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int tabIndex) goTo;
  const HomeScreen({super.key, required this.goTo});

  @override
  Widget build(BuildContext context) {
    final topics = [
      (
        icon: Icons.show_chart,
        title: 'Signal types',
        desc:
            'Impulse, step, ramp, exponentials, sinusoids and more, with energy, power and even/odd parts.',
        tab: 1,
        color: AppColors.blue,
      ),
      (
        icon: Icons.compare_arrows,
        title: 'Shifting and scaling',
        desc:
            'Time shift, reversal, compression, expansion, amplitude scaling and combined operations.',
        tab: 2,
        color: AppColors.green,
      ),
      (
        icon: Icons.blur_linear,
        title: 'Convolution and correlation',
        desc: 'Flip, slide, multiply and add, one output sample at a time.',
        tab: 3,
        color: AppColors.rasp,
      ),
      (
        icon: Icons.graphic_eq,
        title: 'DTFS, DTFT and FFT',
        desc:
            'Fourier series, the DTFT, the FFT in hertz, and building signals with the inverse FFT.',
        tab: 4,
        color: AppColors.amber,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('DSP Visual Lab',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.4)),
        const SizedBox(height: 6),
        const Text(
          'Interactive visualisations for the digital signal processing course. Open a topic, change the inputs, and watch the plots respond.',
          style: TextStyle(color: AppColors.ink2, fontSize: 14.5, height: 1.4),
        ),
        const SizedBox(height: 20),
        for (final t in topics)
          Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => goTo(t.tab),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                          color: t.color.withValues(alpha:0.12),
                          shape: BoxShape.circle),
                      child: Icon(t.icon, color: t.color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title,
                              style: const TextStyle(
                                  fontSize: 16.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 3),
                          Text(t.desc,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.ink2,
                                  height: 1.35)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.ink3),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        const Center(
          child: Text('Designed & Debuged by: Anik Biswas  •  Developed by: MD.Serajus Salekin',
              style: TextStyle(fontSize: 12.5, color: AppColors.ink3)),
        ),
      ],
    );
  }
}

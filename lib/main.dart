import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/signals_screen.dart';
import 'screens/operations_screen.dart';
import 'screens/convolution_screen.dart';
import 'screens/transforms_screen.dart';

void main() => runApp(const DspVisualLabApp());

class DspVisualLabApp extends StatelessWidget {
  const DspVisualLabApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'DSP Visual Lab',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const MainShell(),
      );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  late final List<Widget> pages = [
    HomeScreen(goTo: (i) => setState(() => index = i)),
    const SignalsScreen(),
    const OperationsScreen(),
    const ConvolutionScreen(),
    const TransformsScreen(),
  ];

  static const names = [
    'DSP Visual Lab',
    'Signal types',
    'Shifting & scaling',
    'Convolution & correlation',
    'DTFS · DTFT · FFT',
  ];

  void _go(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final mobile = c.maxWidth < 760;
      return Scaffold(
        appBar: mobile
            ? AppBar(
                title: Row(children: [
                  const _BrandLogo(),
                  const SizedBox(width: 9),
                  Flexible(child: Text(names[index], overflow: TextOverflow.ellipsis)),
                ]),
                actions: [
                  IconButton(
                    tooltip: 'About',
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _about(context),
                  ),
                ],
              )
            : PreferredSize(
                preferredSize: const Size.fromHeight(58),
                child: Material(
                  color: AppColors.paper,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.rule))),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Row(children: [
                        const _BrandLogo(),
                        const SizedBox(width: 9),
                        const Text('DSP Visual Lab', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 18),
                        for (int i = 0; i < names.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: index == i ? AppColors.ink : Colors.transparent,
                                foregroundColor: index == i ? Colors.white : AppColors.ink2,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () => _go(i),
                              child: Text(i == 0 ? 'Home' : names[i]),
                            ),
                          ),
                        const Spacer(),
                        const Text('Designed & Debuged by: Anik Biswas  •  Developed by: MD.Serajus Salekin',
                            style: TextStyle(fontSize: 12, color: AppColors.ink3)),
                        IconButton(icon: const Icon(Icons.info_outline), onPressed: () => _about(context)),
                      ]),
                    ),
                  ),
                ),
              ),
        body: Material(color: AppColors.paper, child: IndexedStack(index: index, children: pages)),
        bottomNavigationBar: mobile
            ? NavigationBar(
                selectedIndex: index,
                onDestinationSelected: _go,
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                  NavigationDestination(icon: Icon(Icons.show_chart), label: 'Signals'),
                  NavigationDestination(icon: Icon(Icons.compare_arrows), label: 'Operations'),
                  NavigationDestination(icon: Icon(Icons.blur_linear), label: 'Convolution'),
                  NavigationDestination(icon: Icon(Icons.graphic_eq), label: 'Transforms'),
                ],
              )
            : null,
      );
    });
  }

  void _about(BuildContext context) => showAboutDialog(
        context: context,
        applicationName: 'DSP Visual Lab',
        applicationVersion: '1.0.0',
        children: const [
          Text('Interactive visualisations for digital signal processing.'),
          SizedBox(height: 8),
          Text('Designed & Debuged by: Anik Biswas\nDeveloped by: MD.Serajus Salekin'),
        ],
      );
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();
  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(26, 20), painter: _LogoPainter());
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = AppColors.ink..strokeWidth = 1.2;
    final stem = Paint()..color = AppColors.blue..strokeWidth = 1.5;
    final dot = Paint()..color = AppColors.blue;
    final h = size.height;
    canvas.drawLine(Offset(0, h * .76), Offset(size.width, h * .76), base);
    const p = [.1, .28, .46, .64, .82, 1.0];
    const q = [.75, .45, .15, .45, .75, .95];
    for (var i = 0; i < p.length; i++) {
      final x = p[i] * size.width, y = q[i] * h;
      canvas.drawLine(Offset(x, h * .76), Offset(x, y), stem);
      canvas.drawCircle(Offset(x, y), 1.8, dot);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

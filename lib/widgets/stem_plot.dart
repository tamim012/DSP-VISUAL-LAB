import 'package:flutter/material.dart';

import '../dsp/signal.dart' show fmt;
import '../theme/app_theme.dart';

enum SeriesType {
  stem,
  line,
}

class PlotSeries {
  final SeriesType type;
  final List<double> x;
  final List<double> y;
  final Color color;
  final double width;
  final bool labels;
  final bool dashed;

  const PlotSeries({
    required this.type,
    required this.x,
    required this.y,
    required this.color,
    this.width = 1.6,
    this.labels = false,
    this.dashed = false,
  });
}

class SignalPlot extends StatelessWidget {
  final List<PlotSeries> series;
  final double height;
  final String xLabel;
  final String yLabel;
  final List<double>? yRange;
  final int? highlightN;

  const SignalPlot({
    super.key,
    required this.series,
    this.height = 220,
    this.xLabel = 'n',
    this.yLabel = '',
    this.yRange,
    this.highlightN,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.rule,
        ),
        borderRadius:
            BorderRadius.circular(8),
      ),
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _PlotPainter(
          series,
          xLabel,
          yLabel,
          yRange,
          highlightN,
        ),
      ),
    );
  }
}

class _Bounds {
  double xmin;
  double xmax;
  double ymin;
  double ymax;

  _Bounds(
    this.xmin,
    this.xmax,
    this.ymin,
    this.ymax,
  );
}

class _PlotPainter extends CustomPainter {
  final List<PlotSeries> series;
  final String xLabel;
  final String yLabel;
  final List<double>? yRangeOverride;
  final int? highlightN;

  _PlotPainter(
    this.series,
    this.xLabel,
    this.yLabel,
    this.yRangeOverride,
    this.highlightN,
  );

  static const TextStyle _tickTextStyle =
      TextStyle(
    color: AppColors.ink3,
    fontSize: 10,
  );

  static const TextStyle _xAxisTextStyle =
      TextStyle(
    color: AppColors.ink2,
    fontSize: 12,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle _yAxisTextStyle =
      TextStyle(
    color: AppColors.ink2,
    fontSize: 11,
    fontStyle: FontStyle.italic,
  );

  _Bounds _bounds() {
    double xmin = double.infinity;
    double xmax = -double.infinity;

    double ymin = 0;
    double ymax = 0;

    for (final s in series) {
      final count = s.x.length < s.y.length
          ? s.x.length
          : s.y.length;

      for (int i = 0; i < count; i++) {
        final x = s.x[i];
        final y = s.y[i];

        if (!y.isFinite) {
          continue;
        }

        if (x < xmin) {
          xmin = x;
        }

        if (x > xmax) {
          xmax = x;
        }

        if (y < ymin) {
          ymin = y;
        }

        if (y > ymax) {
          ymax = y;
        }
      }
    }

    if (!xmin.isFinite) {
      xmin = -5;
      xmax = 5;
    }

    xmin -= 0.8;
    xmax += 0.8;

    if (yRangeOverride != null &&
        yRangeOverride!.length >= 2) {
      ymin = yRangeOverride![0];
      ymax = yRangeOverride![1];
    } else {
      if (ymax - ymin < 1e-9) {
        ymin -= 1;
        ymax += 1;
      }

      final padding =
          (ymax - ymin) * 0.16;

      if (ymax > 0) {
        ymax += padding;
      }

      if (ymin < 0) {
        ymin -= padding;
      }

      if (ymin == 0 && ymax > 0) {
        ymin = -padding * 0.35;
      }

      if (ymax == 0 && ymin < 0) {
        ymax = padding * 0.35;
      }
    }

    return _Bounds(
      xmin,
      xmax,
      ymin,
      ymax,
    );
  }

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final width = size.width;
    final height = size.height;

    final bounds = _bounds();

    const left = 46.0;
    const right = 12.0;
    const top = 10.0;
    const bottom = 24.0;

    final plotWidth =
        width - left - right;

    final plotHeight =
        height - top - bottom;

    if (plotWidth <= 0 ||
        plotHeight <= 0) {
      return;
    }

    double xToPixel(double x) {
      return left +
          (x - bounds.xmin) /
              (bounds.xmax - bounds.xmin) *
              plotWidth;
    }

    double yToPixel(double y) {
      return top +
          (bounds.ymax - y) /
              (bounds.ymax - bounds.ymin) *
              plotHeight;
    }

    final gridPaint = Paint()
      ..color = AppColors.grid
      ..strokeWidth = 1;

    final xStep = _xStep(
      bounds.xmax - bounds.xmin,
      plotWidth,
    );

    for (
      double value =
          (bounds.xmin / xStep)
                  .ceilToDouble() *
              xStep;
      value <= bounds.xmax;
      value += xStep
    ) {
      final pixel = xToPixel(value);

      if (pixel < left - 1 ||
          pixel > left + plotWidth + 1) {
        continue;
      }

      canvas.drawLine(
        Offset(pixel, top),
        Offset(
          pixel,
          top + plotHeight,
        ),
        gridPaint,
      );

      _paintText(
        canvas,
        _fmtTick(value),
        Offset(
          pixel,
          top + plotHeight + 4,
        ),
        _tickTextStyle,
        center: true,
      );
    }

    final yStep = _niceStepSafe(
      bounds.ymax - bounds.ymin,
      (plotHeight / 42)
          .floorToDouble()
          .clamp(2, 100)
          .toDouble(),
    );

    for (
      double value =
          (bounds.ymin / yStep)
                  .ceilToDouble() *
              yStep;
      value <= bounds.ymax + 1e-9;
      value += yStep
    ) {
      final pixel = yToPixel(value);

      canvas.drawLine(
        Offset(left, pixel),
        Offset(
          left + plotWidth,
          pixel,
        ),
        gridPaint,
      );

      _paintText(
        canvas,
        fmt(value, 2),
        Offset(left - 6, pixel),
        _tickTextStyle,
        alignRight: true,
        centerV: true,
      );
    }

    final framePaint = Paint()
      ..color = AppColors.rule
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(
      Rect.fromLTWH(
        left,
        top,
        plotWidth,
        plotHeight,
      ),
      framePaint,
    );

    final axisPaint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 1.2;

    final hasZeroY =
        bounds.ymin < 0 &&
            bounds.ymax > 0 ||
        bounds.ymin == 0 ||
        bounds.ymax == 0;

    if (hasZeroY) {
      final zeroY = yToPixel(0);

      canvas.drawLine(
        Offset(left, zeroY),
        Offset(
          left + plotWidth,
          zeroY,
        ),
        axisPaint,
      );
    }

    if (bounds.xmin < 0 &&
        bounds.xmax > 0) {
      final zeroX = xToPixel(0);

      final zeroXPaint = Paint()
        ..color =
            const Color(0xFFB9C2CC)
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(zeroX, top),
        Offset(
          zeroX,
          top + plotHeight,
        ),
        zeroXPaint,
      );
    }

    if (highlightN != null) {
      final highlightX =
          xToPixel(
        highlightN!.toDouble(),
      );

      final highlightPaint = Paint()
        ..color = AppColors.amber
        ..strokeWidth = 1.4;

      canvas.drawLine(
        Offset(highlightX, top),
        Offset(
          highlightX,
          top + plotHeight,
        ),
        highlightPaint,
      );
    }

    canvas.save();

    canvas.clipRect(
      Rect.fromLTWH(
        left,
        top,
        plotWidth,
        plotHeight,
      ),
    );

    for (final s in series) {
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..style = PaintingStyle.stroke;

      if (s.type == SeriesType.line) {
        final path = Path();

        bool started = false;

        final count =
            s.x.length < s.y.length
                ? s.x.length
                : s.y.length;

        for (int i = 0; i < count; i++) {
          final valueY = s.y[i];

          if (!valueY.isFinite) {
            started = false;
            continue;
          }

          final pixelX =
              xToPixel(s.x[i]);

          final pixelY =
              yToPixel(valueY);

          if (!started) {
            path.moveTo(
              pixelX,
              pixelY,
            );
            started = true;
          } else {
            path.lineTo(
              pixelX,
              pixelY,
            );
          }
        }

        canvas.drawPath(
          path,
          paint,
        );
      } else {
        final dotPaint = Paint()
          ..color = s.color;

        final zeroY = yToPixel(0);

        final count =
            s.x.length < s.y.length
                ? s.x.length
                : s.y.length;

        for (int i = 0; i < count; i++) {
          final valueY = s.y[i];

          if (!valueY.isFinite) {
            continue;
          }

          final pixelX =
              xToPixel(s.x[i]);

          final pixelY =
              yToPixel(valueY);

          canvas.drawLine(
            Offset(pixelX, zeroY),
            Offset(pixelX, pixelY),
            paint,
          );

          canvas.drawCircle(
            Offset(pixelX, pixelY),
            3.2,
            dotPaint,
          );

          if (s.labels) {
            _paintText(
              canvas,
              fmt(valueY, 2),
              Offset(
                pixelX,
                pixelY -
                    (valueY >= 0
                        ? 12
                        : -4),
              ),
              TextStyle(
                color: s.color,
                fontSize: 9.5,
                fontWeight:
                    FontWeight.w600,
              ),
              center: true,
            );
          }
        }
      }
    }

    canvas.restore();

    _paintText(
      canvas,
      xLabel,
      Offset(
        left + plotWidth - 4,
        top + plotHeight - 4,
      ),
      _xAxisTextStyle,
      alignRight: true,
    );

    if (yLabel.isNotEmpty) {
      _paintText(
        canvas,
        yLabel,
        const Offset(
          left + 4,
          top + 2,
        ),
        _yAxisTextStyle,
      );
    }
  }

  double _xStep(
    double span,
    double plotWidth,
  ) {
    final target =
        (plotWidth / 55)
            .clamp(2, 40)
            .toDouble();

    return _niceStepSafe(
      span,
      target,
    );
  }

  double _niceStepSafe(
    double span,
    double target,
  ) {
    if (span <= 0) {
      return 1;
    }

    final raw =
        span /
        (target < 1 ? 1 : target);

    final power = _p10(raw);

    final magnitude =
        raw / power;

    final multiplier =
        magnitude < 1.5
            ? 1
            : (magnitude < 3
                ? 2
                : (magnitude < 7
                    ? 5
                    : 10));

    final result =
        multiplier * power;

    return result <= 0
        ? 1
        : result;
  }

  double _p10(double raw) {
    if (raw <= 0) {
      return 1;
    }

    var power = 1.0;

    if (raw >= 1) {
      while (power * 10 <= raw) {
        power *= 10;
      }
    } else {
      while (power > raw) {
        power /= 10;
      }
    }

    return power;
  }

  String _fmtTick(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return fmt(value, 1);
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle style, {
    bool center = false,
    bool alignRight = false,
    bool centerV = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style,
      ),
      textDirection:
          TextDirection.ltr,
    )..layout();

    double dx = position.dx;
    double dy = position.dy;

    if (center) {
      dx -= textPainter.width / 2;
    }

    if (alignRight) {
      dx -= textPainter.width;
    }

    if (centerV) {
      dy -= textPainter.height / 2;
    }

    textPainter.paint(
      canvas,
      Offset(dx, dy),
    );
  }

  @override
  bool shouldRepaint(
    covariant _PlotPainter oldDelegate,
  ) {
    return true;
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../features/musyrif/domain/musyrif_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Grafik garis persen_hadir bersama untuk dashboard Musyrif dan Admin.
class TrenGrafik extends StatelessWidget {
  final List<TrenHarian> data;

  const TrenGrafik({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final validData = data.where((d) => d.persenHadir != null).toList();
    final avg = validData.isNotEmpty
        ? (validData.map((d) => d.persenHadir!).reduce((a, b) => a + b) /
                validData.length)
            .toStringAsFixed(1)
        : '-';
    final last = data.isNotEmpty ? data.last : null;
    final lastLabel = last == null
        ? null
        : last.persenHadir == null
            ? '- (${last.total} data)'
            : '${last.persenDisplay}% (${last.total} data)';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rata-rata Kehadiran',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        avg == '-' ? '-' : '$avg%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.emerald,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (lastLabel != null)
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Nilai Terakhir',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 16, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(
                          width: 34,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('100%', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              Text('75%', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              Text('50%', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              Text('25%', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              Text('0%', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _LinePainter(data: data),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 42),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (data.isNotEmpty)
                          Text(
                            _singkatTanggal(data.first.tanggal),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        if (data.length > 2)
                          Text(
                            _singkatTanggal(data[data.length ~/ 2].tanggal),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        if (data.isNotEmpty)
                          Text(
                            _singkatTanggal(data.last.tanggal),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  static String _singkatTanggal(String tanggal) {
    try {
      final parsed = DateTime.parse(tanggal);
      return DateFormat('dd/MM').format(parsed);
    } catch (_) {
      return tanggal;
    }
  }
}

class _LinePainter extends CustomPainter {
  final List<TrenHarian> data;

  _LinePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.lightGrey
      ..strokeWidth = 1;

    for (int step = 0; step <= 4; step++) {
      final y = size.height * (step / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (data.isEmpty) return;

    final paintLine = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final paintDot = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    final paintDotInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    double maxX = (data.length - 1).toDouble();
    if (maxX == 0) maxX = 1;

    double? prevX;
    double? prevY;

    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final x = (size.width / maxX) * i;
      double? y;
      if (d.persenHadir != null) {
        y = size.height * (1 - (d.persenHadir! / 100).clamp(0.0, 1.0));
      }

      if (y != null && prevY != null && prevX != null) {
        canvas.drawLine(Offset(prevX, prevY), Offset(x, y), paintLine);
      }
      if (y != null) {
        canvas.drawCircle(Offset(x, y), 4, paintDot);
        canvas.drawCircle(Offset(x, y), 2, paintDotInner);
      }
      prevX = x;
      prevY = y;
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    if (oldDelegate.data.length != data.length) return true;
    for (int i = 0; i < data.length; i++) {
      if (oldDelegate.data[i] != data[i]) return true;
    }
    return false;
  }
}

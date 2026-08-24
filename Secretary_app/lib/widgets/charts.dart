import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../domain/models/json_utils.dart';
import 'app_widgets.dart';

/// One slice or bar.
class ChartDatum {
  const ChartDatum({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

/// Reads `{label, value}` rows out of a stored-procedure result.
///
/// The dashboard's chart payloads name their columns differently per branch
/// (`category`/`amount` on one, `month_name`/`amount` on another), so the keys
/// are passed in and colours are assigned by position from the series ramp.
List<ChartDatum> chartData(
  List<Map<String, dynamic>> rows, {
  required List<String> labelKeys,
  required List<String> valueKeys,
  int limit = 12,
}) {
  final data = <ChartDatum>[];

  for (final row in rows.take(limit)) {
    final value = asDouble(_firstOf(row, valueKeys));
    if (value == null) continue;

    data.add(
      ChartDatum(
        label: pick(row, labelKeys) ?? '—',
        value: value,
        color: AppTheme.chartSeries[data.length % AppTheme.chartSeries.length],
      ),
    );
  }

  return data;
}

dynamic _firstOf(Map<String, dynamic> row, List<String> keys) {
  for (final k in keys) {
    if (row[k] != null) return row[k];
  }
  return null;
}

/// A donut with the total in the middle and a legend beside or beneath it.
///
/// Values are also written into the legend rather than only onto the slices:
/// a slice too thin to label is exactly the one whose number matters.
class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.data,
    this.centerLabel,
    this.height = 190,
  });

  final List<ChartDatum> data;
  final String? centerLabel;
  final double height;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.data.fold<double>(0, (sum, d) => sum + d.value);

    if (widget.data.isEmpty || total <= 0) {
      return _ChartEmpty(height: widget.height);
    }

    return SizedBox(
      height: widget.height,
      child: Row(
        children: [
          SizedBox(
            width: widget.height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: widget.height * 0.27,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          _touched = event.isInterestedForInteractions
                              ? (response
                                        ?.touchedSection
                                        ?.touchedSectionIndex ??
                                    -1)
                              : -1;
                        });
                      },
                    ),
                    sections: [
                      for (var i = 0; i < widget.data.length; i++)
                        _section(widget.data[i], i, total),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.centerLabel ?? 'Total',
                      style: AppTheme.overline.copyWith(fontSize: 9.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      compactMoney(total),
                      style: AppTheme.numeralSm.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < widget.data.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space3),
                    child: _legendRow(widget.data[i], total),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _section(ChartDatum datum, int index, double total) {
    final isTouched = index == _touched;
    final share = datum.value / total;

    return PieChartSectionData(
      value: datum.value,
      color: datum.color,
      radius: isTouched ? widget.height * 0.26 : widget.height * 0.22,
      // A percentage under about 8% has no room to print inside its own slice.
      title: share < 0.08 ? '' : '${(share * 100).round()}%',
      titleStyle: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _legendRow(ChartDatum datum, double total) {
    return Row(
      children: [
        Container(
          height: 9,
          width: 9,
          decoration: BoxDecoration(
            color: datum.color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppTheme.space2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                datum.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.darkText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${moneyFlat(datum.value)}  ·  '
                '${(datum.value / total * 100).round()}%',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.caption.copyWith(fontSize: 11.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A bar chart for a short series.
///
/// Not currently on a screen — the dashboard shows the same monthly figures
/// as a trend line instead. Kept because the accounts and reports screens are
/// the natural home for a categorical comparison, which a line cannot do.
class BarChartCard extends StatelessWidget {
  const BarChartCard({
    super.key,
    required this.data,
    this.height = 200,
    this.barColor = AppTheme.primary,
  });

  final List<ChartDatum> data;
  final double height;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _ChartEmpty(height: height);

    final maxValue = data.fold<double>(0, (m, d) => d.value > m ? d.value : m);
    // Headroom so the tallest bar does not touch the top of the plot.
    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.22;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 3,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppTheme.spacer, strokeWidth: 1),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppTheme.darkerText,
              tooltipRoundedRadius: AppTheme.radiusSm,
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                    '${data[groupIndex].label}\n',
                    const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: moneyFlat(rod.toY),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: maxY / 3,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      compactMoney(value),
                      style: AppTheme.caption.copyWith(fontSize: 10.5),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final label = data[index].label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      // Month names are too wide to sit side by side; three
                      // letters is enough to tell them apart.
                      label.length > 3 ? label.substring(0, 3) : label,
                      style: AppTheme.caption.copyWith(fontSize: 10.5),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].value,
                    width: 15,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                    gradient: LinearGradient(
                      colors: [barColor.withValues(alpha: 0.55), barColor],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bar_chart_rounded,
              size: 30,
              color: AppTheme.deactivatedText,
            ),
            const SizedBox(height: AppTheme.space2),
            Text('No figures yet', style: AppTheme.caption),
          ],
        ),
      ),
    );
  }
}

/// A card wrapping a chart, with its heading.
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.title),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppTheme.caption),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppTheme.space5),
          child,
        ],
      ),
    );
  }
}

/// A filled line chart for a short series — collection month by month.
///
/// Area rather than bars because the point here is the shape of the trend,
/// not comparing one month against another precisely; the gradient fill is
/// what makes a rise or a dip readable at a glance.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.data,
    this.height = 180,
    this.color = AppTheme.primary,
  });

  final List<ChartDatum> data;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // A single point has no trend to draw, and fl_chart cannot span a line
    // between one spot.
    if (data.length < 2) return _ChartEmpty(height: height);

    final maxValue = data.fold<double>(0, (m, d) => d.value > m ? d.value : m);
    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.25;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 3,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppTheme.spacer, strokeWidth: 1),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppTheme.darkerText,
              tooltipRoundedRadius: AppTheme.radiusSm,
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    '${data[spot.x.toInt()].label}\n',
                    const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: moneyFlat(spot.y),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: maxY / 3,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      compactMoney(value),
                      style: AppTheme.caption.copyWith(fontSize: 10.5),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final label = data[index].label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label.length > 3 ? label.substring(0, 3) : label,
                      style: AppTheme.caption.copyWith(fontSize: 10.5),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < data.length; i++)
                  FlSpot(i.toDouble(), data[i].value),
              ],
              isCurved: true,
              // Below about 0.35 the curve starts overshooting into negative
              // territory between two very different months.
              curveSmoothness: 0.3,
              preventCurveOverShooting: true,
              color: color,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 3.5,
                      color: AppTheme.white,
                      strokeWidth: 2,
                      strokeColor: color,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.28),
                    color.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

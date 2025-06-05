import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';

class PerformanceChart extends StatelessWidget {
  final List<HistoricalGradeData> historicalData;
  final double currentAverage;
  final bool showDescription;

  const PerformanceChart({
    Key? key,
    required this.historicalData,
    required this.currentAverage,
    this.showDescription = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (historicalData.isEmpty) {
      return const Center(
        child: Text('No hay datos de rendimiento disponibles'),
      );
    }

    // Ordenar datos por fecha
    final sortedData = List<HistoricalGradeData>.from(historicalData)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Limitar a 10 puntos si hay demasiados datos
    final displayData = sortedData.length > 10 
        ? sortedData.sublist(sortedData.length - 10) 
        : sortedData;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ajustar altura basada en el espacio disponible
        final availableHeight = constraints.maxHeight;
        final chartHeight = availableHeight * 0.6; // 60% para el gráfico
        final legendHeight = availableHeight * 0.3; // 30% para la leyenda

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promedio actual: ${currentAverage.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: chartHeight,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: true,
                    horizontalInterval: 20,
                    verticalInterval: 1,
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < displayData.length) {
                            final date = displayData[value.toInt()].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '${date.day}/${date.month}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                            ),
                          );
                        },
                        reservedSize: 30,
                        interval: 20,
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xff37434d), width: 1),
                  ),
                  minX: 0,
                  maxX: displayData.length - 1.0,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(displayData.length, (index) {
                        return FlSpot(index.toDouble(), displayData[index].grade);
                      }),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: Theme.of(context).primaryColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          final data = displayData[index];
                          final description = showDescription && data.description.isNotEmpty
                              ? '\n${data.description}'
                              : '';
                          return LineTooltipItem(
                            '${data.grade.toStringAsFixed(1)}$description',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (showDescription && displayData.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Leyenda:'),
                      const SizedBox(height: 4),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: displayData.length,
                          itemBuilder: (context, index) {
                            final data = displayData[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${data.date.day}/${data.date.month}: ${data.grade.toStringAsFixed(1)} - ${data.description}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}


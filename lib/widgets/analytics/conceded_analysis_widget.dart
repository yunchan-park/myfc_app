import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:myfc_app/models/analytics.dart';
import 'package:myfc_app/config/theme.dart';

class ConcededAnalysisWidget extends StatelessWidget {
  final ConcededLossCorrelation concededLossCorrelation;

  const ConcededAnalysisWidget({
    super.key,
    required this.concededLossCorrelation,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConcededInsightsCard(),
          const SizedBox(height: 16),
          _buildConcededBarChart(),
          const SizedBox(height: 16),
          _buildConcededDataTable(),
        ],
      ),
    );
  }

  Widget _buildConcededInsightsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '실점 분석 인사이트',
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            '위험 임계점',
            '${concededLossCorrelation.dangerThreshold}골',
            AppColors.error,
            Icons.warning,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            '패배 평균 실점',
            '${concededLossCorrelation.avgConcededForLoss}골',
            AppColors.warning,
            Icons.trending_down,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(color: color),
                ),
                Text(
                  value,
                  style: AppTextStyles.displaySmall.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcededBarChart() {
    if (concededLossCorrelation.concededRanges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('데이터가 없습니다'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '실점별 패배율',
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final concededRange = concededLossCorrelation.concededRanges[groupIndex];
                      return BarTooltipItem(
                        '${concededRange.conceded}골\n패배율: ${concededRange.lossRate}%\n경기: ${concededRange.matches}',
                        AppTextStyles.bodySmall.copyWith(color: AppColors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: AppTextStyles.bodySmall,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < concededLossCorrelation.concededRanges.length) {
                          return Text(
                            '${concededLossCorrelation.concededRanges[index].conceded}골',
                            style: AppTextStyles.bodySmall,
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: concededLossCorrelation.concededRanges.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.lossRate,
                        color: _getBarColor(data.lossRate),
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBarColor(double lossRate) {
    if (lossRate >= 70) return AppColors.error;
    if (lossRate >= 50) return AppColors.warning;
    return AppColors.success;
  }

  Widget _buildConcededDataTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '실점별 상세 데이터',
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              dataTextStyle: AppTextStyles.bodyMedium,
              columns: const [
                DataColumn(label: Text('실점 수')),
                DataColumn(label: Text('경기 수')),
                DataColumn(label: Text('패배')),
                DataColumn(label: Text('패배율')),
              ],
              rows: concededLossCorrelation.concededRanges.map((data) {
                return DataRow(
                  cells: [
                    DataCell(Text('${data.conceded}골')),
                    DataCell(Text(data.matches.toString())),
                    DataCell(Text(data.losses.toString())),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getBarColor(data.lossRate).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${data.lossRate}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _getBarColor(data.lossRate),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
} 
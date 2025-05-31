import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:myfc_app/models/analytics.dart';
import 'package:myfc_app/config/theme.dart';

class GoalsAnalysisWidget extends StatelessWidget {
  final GoalsWinCorrelation goalsWinCorrelation;

  const GoalsAnalysisWidget({
    super.key,
    required this.goalsWinCorrelation,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGoalsInsightsCard(),
          const SizedBox(height: 16),
          _buildGoalsBarChart(),
          const SizedBox(height: 16),
          _buildGoalsDataTable(),
        ],
      ),
    );
  }

  Widget _buildGoalsInsightsCard() {
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
            '득점 분석 인사이트',
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            '최적 득점 수',
            '${goalsWinCorrelation.optimalGoals}골',
            AppColors.success,
            Icons.gps_fixed,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            '승리 평균 득점',
            '${goalsWinCorrelation.avgGoalsForWin}골',
            AppColors.primary,
            Icons.trending_up,
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

  Widget _buildGoalsBarChart() {
    if (goalsWinCorrelation.goalRanges.isEmpty) {
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
            '득점별 승률',
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
                      final goalRange = goalsWinCorrelation.goalRanges[groupIndex];
                      return BarTooltipItem(
                        '${goalRange.goals}골\n승률: ${goalRange.winRate}%\n경기: ${goalRange.matches}',
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
                        if (index >= 0 && index < goalsWinCorrelation.goalRanges.length) {
                          return Text(
                            '${goalsWinCorrelation.goalRanges[index].goals}골',
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
                barGroups: goalsWinCorrelation.goalRanges.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.winRate,
                        color: _getBarColor(data.winRate),
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

  Color _getBarColor(double winRate) {
    if (winRate >= 70) return AppColors.success;
    if (winRate >= 50) return AppColors.warning;
    return AppColors.error;
  }

  Widget _buildGoalsDataTable() {
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
            '득점별 상세 데이터',
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
                DataColumn(label: Text('득점 수')),
                DataColumn(label: Text('경기 수')),
                DataColumn(label: Text('승리')),
                DataColumn(label: Text('승률')),
              ],
              rows: goalsWinCorrelation.goalRanges.map((data) {
                return DataRow(
                  cells: [
                    DataCell(Text('${data.goals}골')),
                    DataCell(Text(data.matches.toString())),
                    DataCell(Text(data.wins.toString())),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getBarColor(data.winRate).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${data.winRate}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _getBarColor(data.winRate),
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
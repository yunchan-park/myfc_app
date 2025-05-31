import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:myfc_app/models/analytics.dart';
import 'package:myfc_app/config/theme.dart';

class AnalyticsOverviewWidget extends StatelessWidget {
  final TeamAnalyticsOverview overview;

  const AnalyticsOverviewWidget({
    super.key,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(),
          const SizedBox(height: 16),
          _buildWinRatePieChart(),
          const SizedBox(height: 16),
          _buildMatchRecordsCard(),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
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
            '시즌 요약',
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '총 경기',
                  overview.totalMatches.toString(),
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '승률',
                  '${overview.winRate}%',
                  AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '평균 득점',
                  overview.avgGoalsScored.toString(),
                  AppColors.warning,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '평균 실점',
                  overview.avgGoalsConceded.toString(),
                  AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.displayLarge.copyWith(
              color: color,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinRatePieChart() {
    final total = overview.wins + overview.draws + overview.losses;
    if (total == 0) {
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
            '승부 분포',
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: overview.wins.toDouble(),
                          title: '승\n${overview.wins}',
                          color: AppColors.success,
                          radius: 60,
                          titleStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          value: overview.draws.toDouble(),
                          title: '무\n${overview.draws}',
                          color: AppColors.warning,
                          radius: 60,
                          titleStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          value: overview.losses.toDouble(),
                          title: '패\n${overview.losses}',
                          color: AppColors.error,
                          radius: 60,
                          titleStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 20,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('승리', AppColors.success, overview.wins),
                      _buildLegendItem('무승부', AppColors.warning, overview.draws),
                      _buildLegendItem('패배', AppColors.error, overview.losses),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label ($value)',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchRecordsCard() {
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
            '특별 기록',
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 16),
          _buildRecordItem(
            '최다 득점 경기',
            '${overview.highestScoringMatch['goals']}골',
            AppColors.success,
            Icons.sports_soccer,
          ),
          const SizedBox(height: 12),
          _buildRecordItem(
            '최다 실점 경기',
            '${overview.mostConcededMatch['goals']}골',
            AppColors.error,
            Icons.shield,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(String title, String value, Color color, IconData icon) {
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
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: color,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.displaySmall.copyWith(
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
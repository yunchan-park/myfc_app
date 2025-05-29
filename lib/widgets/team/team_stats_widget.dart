import 'package:flutter/material.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/models/player.dart';

class TeamStatsWidget extends StatelessWidget {
  final int totalMatches;
  final int wins;
  final int draws;
  final int losses;
  final int totalGoalsScored;
  final int totalGoalsConceded;
  final Player? topScorer;
  final Player? topAssister;
  final Player? mvp;

  const TeamStatsWidget({
    super.key,
    required this.totalMatches,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.totalGoalsScored,
    required this.totalGoalsConceded,
    this.topScorer,
    this.topAssister,
    this.mvp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsCard(),
          const SizedBox(height: 16),
          _buildPlayerAwardsCard(),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final winRate = totalMatches > 0 ? (wins / totalMatches * 100).toStringAsFixed(1) : '0.0';
    final avgGoalsScored = totalMatches > 0 ? (totalGoalsScored / totalMatches).toStringAsFixed(1) : '0.0';
    final avgGoalsConceded = totalMatches > 0 ? (totalGoalsConceded / totalMatches).toStringAsFixed(1) : '0.0';

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
            '시즌 통계',
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '총 경기',
                  totalMatches.toString(),
                  AppColors.primary,
                  Icons.sports_soccer,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '승률',
                  '$winRate%',
                  AppColors.success,
                  Icons.trending_up,
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
                  avgGoalsScored,
                  AppColors.warning,
                  Icons.sports_score,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '평균 실점',
                  avgGoalsConceded,
                  AppColors.error,
                  Icons.shield,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildWinLossBar(),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.displayMedium.copyWith(
              color: color,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWinLossBar() {
    if (totalMatches == 0) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    final winPercent = wins / totalMatches;
    final drawPercent = draws / totalMatches;
    final lossPercent = losses / totalMatches;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('승부 분포', style: AppTextStyles.bodyMedium),
            Text('$wins승 $draws무 $losses패', style: AppTextStyles.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              if (winPercent > 0)
                Expanded(
                  flex: (winPercent * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(4),
                        bottomLeft: const Radius.circular(4),
                        topRight: drawPercent + lossPercent == 0 
                            ? const Radius.circular(4) 
                            : Radius.zero,
                        bottomRight: drawPercent + lossPercent == 0 
                            ? const Radius.circular(4) 
                            : Radius.zero,
                      ),
                    ),
                  ),
                ),
              if (drawPercent > 0)
                Expanded(
                  flex: (drawPercent * 100).round(),
                  child: Container(
                    color: AppColors.warning,
                  ),
                ),
              if (lossPercent > 0)
                Expanded(
                  flex: (lossPercent * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.only(
                        topRight: const Radius.circular(4),
                        bottomRight: const Radius.circular(4),
                        topLeft: winPercent + drawPercent == 0 
                            ? const Radius.circular(4) 
                            : Radius.zero,
                        bottomLeft: winPercent + drawPercent == 0 
                            ? const Radius.circular(4) 
                            : Radius.zero,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerAwardsCard() {
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
            '개인 어워드',
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAwardItem(
                  '득점왕',
                  topScorer?.name ?? '-',
                  topScorer != null ? '${topScorer!.goalCount}골' : '',
                  const Color(0xFFFFD700), // Gold
                  Icons.sports_soccer,
                ),
              ),
              Expanded(
                child: _buildAwardItem(
                  '도움왕',
                  topAssister?.name ?? '-',
                  topAssister != null ? '${topAssister!.assistCount}회' : '',
                  const Color(0xFFC0C0C0), // Silver
                  Icons.sports_handball,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: _buildAwardItem(
              'MVP',
              mvp?.name ?? '-',
              mvp != null ? '${mvp!.momCount}회' : '',
              const Color(0xFFCD7F32), // Bronze
              Icons.star,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAwardItem(String title, String playerName, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            playerName,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 
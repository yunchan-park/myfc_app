import 'package:flutter/material.dart';
import 'package:myfc_app/models/analytics.dart';
import 'package:myfc_app/config/theme.dart';

class PlayerContributionsWidget extends StatelessWidget {
  final PlayerContributionsResponse playerContributions;

  const PlayerContributionsWidget({
    super.key,
    required this.playerContributions,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopContributorsCard(),
          const SizedBox(height: 16),
          _buildPlayersList(),
        ],
      ),
    );
  }

  Widget _buildTopContributorsCard() {
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
            '핵심 선수',
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTopPlayerCard(
                  '최고 기여자',
                  playerContributions.topContributor['name'] ?? '-',
                  '${playerContributions.topContributor['score'] ?? '0'}점',
                  AppColors.warning,
                  Icons.star,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTopPlayerCard(
                  '최고 신뢰도',
                  playerContributions.mostReliable['name'] ?? '-',
                  '${playerContributions.mostReliable['win_rate'] ?? '0'}%',
                  AppColors.success,
                  Icons.verified,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopPlayerCard(String title, String name, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: AppTextStyles.displaySmall.copyWith(color: color),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList() {
    if (playerContributions.players.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('선수 데이터가 없습니다'),
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
            '선수별 기여도',
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: playerContributions.players.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final player = playerContributions.players[index];
              return _buildPlayerItem(player, index + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerItem(PlayerContribution player, int rank) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // 순위
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // 선수 정보
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${player.matchesPlayed}경기 출전',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          
          // 통계
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('기여도', '${player.contributionScore}', AppColors.primary),
                _buildStatColumn('승률', '${player.winRate}%', AppColors.success),
                _buildStatColumn('평균골', '${player.avgGoalsPerMatch}', AppColors.warning),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.neutral;
    }
  }
} 
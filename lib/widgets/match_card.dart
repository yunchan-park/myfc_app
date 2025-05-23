import 'package:flutter/material.dart';
import 'package:myfc_app/models/match.dart';
import 'package:myfc_app/config/theme.dart';

class MatchCard extends StatelessWidget {
  final int id;
  final String date;
  final String opponent;
  final String score;
  final MatchResult? result;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final String? teamName;
  final String? teamLogoUrl;
  final String? opponentLogoUrl;

  const MatchCard({
    super.key,
    required this.id,
    required this.date,
    required this.opponent,
    required this.score,
    this.result,
    this.onTap,
    this.onDelete,
    this.teamName = 'FC UBUNTU',
    this.teamLogoUrl,
    this.opponentLogoUrl,
  });

  Color _getResultColor() {
    if (result == null) return AppColors.warning;
    switch (result!) {
      case MatchResult.win:
        return AppColors.success;
      case MatchResult.lose:
        return AppColors.error;
      case MatchResult.draw:
        return AppColors.warning;
    }
  }

  String _getResultText() {
    if (result == null) return '무';
    switch (result!) {
      case MatchResult.win:
        return '승';
      case MatchResult.lose:
        return '패';
      case MatchResult.draw:
        return '무';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and result
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutral,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getResultColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getResultText(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _getResultColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Teams and score
              Row(
                children: [
                  // Our team
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamLogo(teamLogoUrl),
                        const SizedBox(height: 8),
                        Text(
                          teamName ?? 'FC UBUNTU',
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Score
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      score,
                      style: AppTextStyles.displayMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Opponent team
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamLogo(opponentLogoUrl),
                        const SizedBox(height: 8),
                        Text(
                          opponent,
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTeamLogo(String? logoUrl) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.lightGray,
      ),
      child: logoUrl != null && logoUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.network(
                logoUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.sports_soccer,
                    size: 24,
                    color: AppColors.neutral,
                  );
                },
              ),
            )
          : const Icon(
              Icons.sports_soccer,
              size: 24,
              color: AppColors.neutral,
            ),
    );
  }
} 
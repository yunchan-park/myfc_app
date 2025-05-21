import 'package:flutter/material.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/models/match.dart';
import 'package:myfc_app/widgets/common/app_card.dart';

class MatchCardItem extends StatelessWidget {
  final Match match;
  final String? teamName;
  final String? teamLogoUrl;
  final String? opponentLogoUrl;
  final VoidCallback? onTap;
  final bool showDate;

  const MatchCardItem({
    Key? key,
    required this.match,
    this.teamName = 'FC UBUNTU',
    this.teamLogoUrl,
    this.opponentLogoUrl,
    this.onTap,
    this.showDate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final result = match.getResultEnum();
    String onlyDate = match.date.contains('T') 
        ? match.date.split('T').first 
        : match.date;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and result row
              if (showDate)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      onlyDate,
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
                        color: _getResultColor(result).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        match.getResult(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _getResultColor(result),
                        ),
                      ),
                    ),
                  ],
                ),
              if (showDate) 
                const SizedBox(height: 16),
              
              // Teams and score row
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
                      match.score,
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
                          match.opponent,
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

  Color _getResultColor(MatchResult result) {
    switch (result) {
      case MatchResult.win:
        return AppColors.success;
      case MatchResult.draw:
        return AppColors.warning;
      case MatchResult.lose:
        return AppColors.error;
    }
  }
} 
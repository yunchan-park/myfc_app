import 'package:flutter/material.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/models/match.dart' as models;
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/widgets/common/app_card.dart';
import 'package:myfc_app/widgets/quarter_score_widget.dart' as widgets;
import 'package:myfc_app/widgets/goal_list_widget.dart' as widgets;

class MatchDetailScreen extends StatefulWidget {
  final int matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  models.Match? _match;
  int _selectedQuarter = 1;
  String _opponentName = 'FC UNIX';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatchDetail();
  }

  Future<void> _loadMatchDetail() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return;

      final matchDetail = await _apiService.getMatchDetail(widget.matchId, token);
      
      if (mounted) {
        setState(() {
          _match = matchDetail;
          _opponentName = matchDetail.opponent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Helpers.showSnackBar(
          context,
          '매치 상세 정보를 불러올 수 없습니다.',
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteMatch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final result = await _apiService.deleteMatch(widget.matchId, token);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '매치가 삭제되었습니다.')),
        );
        Navigator.of(context).pop(true); // 삭제 성공 표시
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('매치 삭제에 실패했습니다. 다시 시도해주세요.')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '매치 상세',
          style: AppTextStyles.displaySmall,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete,
              color: AppColors.neutral,
            ),
            onPressed: _isLoading ? null : _confirmDelete,
            tooltip: '매치 삭제',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _match == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.neutral,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '매치 정보를 불러올 수 없습니다',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.neutral,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildMatchDetailContent(),
    );
  }

  Widget _buildMatchDetailContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScoreCard(),
            const SizedBox(height: 24),
            if (_match!.quarterScores != null && _match!.quarterScores!.isNotEmpty)
              Column(
                children: [
                  _buildQuarterScoreWidget(),
                  const SizedBox(height: 24),
                ],
              ),
            _buildGoalScorers(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    final score = _match!.score.split(':');
    final ourScore = int.tryParse(score[0]) ?? 0;
    final opponentScore = int.tryParse(score[1]) ?? 0;
    final result = _match!.getResultEnum();
    
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              _match!.date,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.neutral,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '우리팀',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.neutral,
                  ),
                ),
                Text(
                  '$ourScore : $opponentScore',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  _opponentName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.neutral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _getResultColor(result).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _match!.getResult(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _getResultColor(result),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getResultColor(models.MatchResult result) {
    switch (result) {
      case models.MatchResult.win:
        return AppColors.success;
      case models.MatchResult.draw:
        return AppColors.warning;
      case models.MatchResult.lose:
        return AppColors.error;
    }
  }

  Widget _buildQuarterScoreWidget() {
    if (_match!.quarterScores == null || _match!.quarterScores!.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              '쿼터별 점수 정보가 없습니다',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral.withOpacity(0.6),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '쿼터별 점수',
          style: AppTextStyles.displayLarge.copyWith(
            color: AppColors.neutral,
          ),
        ),
        const SizedBox(height: 16),
        widgets.QuarterScoreWidget(
          quarterScores: _match!.quarterScores as Map<int, models.QuarterScore>,
          selectedQuarter: _selectedQuarter,
          maxQuarters: _match!.quarterScores!.length,
          onQuarterSelected: (quarter) {
            setState(() {
              _selectedQuarter = quarter;
            });
          },
        ),
      ],
    );
  }

  Widget _buildGoalScorers() {
    if (_match!.goals == null || _match!.goals!.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              '득점 기록이 없습니다',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral.withOpacity(0.6),
              ),
            ),
          ),
        ),
      );
    }

    // 쿼터별 필터링
    final filteredGoals = _match!.goals!.where((goal) => goal.quarter == _selectedQuarter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '득점 기록',
          style: AppTextStyles.displayLarge.copyWith(
            color: AppColors.neutral,
          ),
        ),
        const SizedBox(height: 16),
        widgets.GoalListWidget(
          goals: filteredGoals,
          emptyMessage: '해당 쿼터의 득점 기록이 없습니다',
        ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          '매치 삭제',
          style: AppTextStyles.displayLarge,
        ),
        content: Text(
          '정말 이 매치를 삭제하시겠습니까?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutral,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '취소',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              '삭제',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteMatch();
    }
  }
}
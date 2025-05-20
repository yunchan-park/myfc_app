import 'package:flutter/material.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/widgets/common/app_button.dart';
import 'package:myfc_app/widgets/widgets.dart';

class AddMatchStep4Screen extends StatefulWidget {
  final Map<String, dynamic> matchData;
  
  const AddMatchStep4Screen({
    Key? key,
    required this.matchData,
  }) : super(key: key);

  @override
  State<AddMatchStep4Screen> createState() => _AddMatchStep4ScreenState();
}

class _AddMatchStep4ScreenState extends State<AddMatchStep4Screen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  List<Player> _players = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }
  
  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final teamId = await _storageService.getTeamId();
      final token = await _storageService.getToken();
      
      if (teamId != null) {
        final allPlayers = await _apiService.getTeamPlayers(teamId, token);
        
        // Filter players by selected playerIds
        final selectedPlayers = allPlayers.where(
          (player) => widget.matchData['playerIds'].contains(player.id)
        ).toList();
        
        if (mounted) {
          setState(() {
            _players = selectedPlayers;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '선수 정보를 불러오는 데 실패했습니다.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _submitMatch() async {
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final teamId = await _storageService.getTeamId();
      final token = await _storageService.getToken();
      
      if (teamId != null) {
        // Create match
        final match = await _apiService.createMatch(
          widget.matchData['date'],
          widget.matchData['opponent'],
          widget.matchData['score'],
          int.parse(teamId),
          widget.matchData['playerIds'].cast<int>(),
          token,
          widget.matchData['quarterScores'] as Map<int, Map<String, int>>
        );
        
        // Add goals if there are any
        if (widget.matchData['goals'] != null) {
          print('${widget.matchData['goals'].length}개의 골 기록 등록 시작');
          for (final goal in widget.matchData['goals']) {
            await _apiService.addGoal(
              match.id,
              goal['player_id'],
              goal['assist_player_id'],
              goal['quarter'],
              token
            );
            print('골 등록 완료: 득점자=${goal['player_id']}, 어시스트=${goal['assist_player_id']}, 쿼터=${goal['quarter']}');
          }
          print('모든 골 기록 등록 완료 - 통계 업데이트는 백엔드에서 자동으로 처리됨');
        }
        
        // Show success message
        if (mounted) {
          Helpers.showSnackBar(context, '매치가 등록되었습니다.');
          
          // Navigate back to match summary screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '매치 등록에 실패했습니다. 다시 시도해주세요.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
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
          '매치 추가',
          style: AppTextStyles.displaySmall,
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step indicator
                        _buildStepIndicator(),
                        const SizedBox(height: 32),
                        
                        // Match summary
                        Text(
                          '경기 요약',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: AppColors.neutral,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Match details
                        _buildMatchSummary(),
                        const SizedBox(height: 32),
                        
                        // Quarter scores
                        _buildQuarterScores(),
                        const SizedBox(height: 32),
                        
                        // Goals
                        if (widget.matchData['goals'] != null && 
                            (widget.matchData['goals'] as List).isNotEmpty)
                          _buildGoalsSummary(),
                      ],
                    ),
                  ),
                ),
                
                // Submit button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppButton(
                    text: '매치 등록 완료하기',
                    onPressed: _isSubmitting ? null : _submitMatch,
                    isLoading: _isSubmitting,
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(1, false),
        _buildStepLine(),
        _buildStepCircle(2, false),
        _buildStepLine(),
        _buildStepCircle(3, false),
        _buildStepLine(),
        _buildStepCircle(4, true),
      ],
    );
  }
  
  Widget _buildStepCircle(int step, bool isActive) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.primary : AppColors.neutral.withOpacity(0.1),
      ),
      child: Center(
        child: Text(
          '$step',
          style: AppTextStyles.label.copyWith(
            color: isActive ? AppColors.white : AppColors.neutral,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 2,
        color: AppColors.neutral.withOpacity(0.1),
      ),
    );
  }
  
  Widget _buildMatchSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.neutral.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
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
                widget.matchData['score'],
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Text(
                widget.matchData['opponent'],
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.neutral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '참여 선수 ${widget.matchData['playerIds'].length}명',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuarterScores() {
    final quarterScores = widget.matchData['quarterScores'] as Map<int, Map<String, int>>;
    
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
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: quarterScores.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final quarter = index + 1;
            final score = quarterScores[quarter]!;
            
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.neutral.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$quarter쿼터',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutral,
                    ),
                  ),
                  Text(
                    '${score['our_score']} : ${score['opponent_score']}',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildGoalsSummary() {
    final goals = widget.matchData['goals'] as List;
    
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
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: goals.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final goal = goals[index];
            final scorer = _players.firstWhere(
              (player) => player.id == goal['player_id'],
            );
            final assistPlayer = goal['assist_player_id'] != null
                ? _players.firstWhere(
                    (player) => player.id == goal['assist_player_id'],
                  )
                : null;
            
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.neutral.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.neutral.withOpacity(0.1),
                    child: Text(
                      scorer.name[0],
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.neutral,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${scorer.name} (${goal['quarter']}쿼터)',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.neutral,
                          ),
                        ),
                        if (assistPlayer != null)
                          Text(
                            '어시스트: ${assistPlayer.name}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.neutral.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
} 
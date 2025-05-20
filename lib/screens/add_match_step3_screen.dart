import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/widgets/common/app_button.dart';
import 'package:myfc_app/widgets/common/app_input.dart';
import 'package:myfc_app/widgets/widgets.dart';
import 'package:myfc_app/models/match.dart' as models;
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/widgets/common/app_card.dart';

class AddMatchStep3Screen extends StatefulWidget {
  final DateTime date;
  final String opponent;
  final int quarters;
  final List<int> playerIds;
  
  const AddMatchStep3Screen({
    Key? key,
    required this.date,
    required this.opponent,
    required this.quarters,
    required this.playerIds,
  }) : super(key: key);

  @override
  State<AddMatchStep3Screen> createState() => _AddMatchStep3ScreenState();
}

class _AddMatchStep3ScreenState extends State<AddMatchStep3Screen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  List<Player> _players = [];
  bool _isLoading = true;
  
  Map<int, Map<String, int>> _quarterScores = {};
  
  List<Map<String, dynamic>> _goals = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.quarters, vsync: this);
    
    for (int i = 1; i <= widget.quarters; i++) {
      _quarterScores[i] = {
        'our_score': 0,
        'opponent_score': 0,
      };
    }
    
    _loadPlayers();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final teamId = await _authService.getTeamId();
      final token = await _authService.getToken();
      
      if (teamId != null) {
        final allPlayers = await _apiService.getTeamPlayers(teamId, token);
        
        final selectedPlayers = allPlayers.where(
          (player) => widget.playerIds.contains(player.id)
        ).toList();
        
        if (mounted) {
          setState(() {
            _players = selectedPlayers;
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
  
  void _addOurScore(int quarter) {
    _showScoreDialog(quarter, true);
  }
  
  void _addOpponentScore(int quarter) {
    setState(() {
      _quarterScores[quarter]!['opponent_score'] = _quarterScores[quarter]!['opponent_score']! + 1;
    });
  }
  
  void _showScoreDialog(int quarter, bool isOurTeam) {
    if (isOurTeam) {
      showDialog(
        context: context,
        builder: (context) => _buildScoreDialog(quarter),
      );
    } else {
      _addOpponentScore(quarter);
    }
  }
  
  Widget _buildScoreDialog(int quarter) {
    int? selectedPlayerId;
    int? selectedAssistPlayerId;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            '득점 정보',
            style: AppTextStyles.displayLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '득점 선수',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '득점 선수를 선택해주세요',
                ),
                items: _players.map((player) {
                  return DropdownMenuItem<int>(
                    value: player.id,
                    child: Text('${player.number}. ${player.name}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPlayerId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(
                '어시스트 선수 (선택)',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '어시스트 선수를 선택해주세요',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('없음'),
                  ),
                  ..._players.map((player) {
                    return DropdownMenuItem<int?>(
                      value: player.id,
                      child: Text('${player.number}. ${player.name}'),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedAssistPlayerId = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '취소',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutral,
                ),
              ),
            ),
            AppButton(
              text: '확인',
              onPressed: () {
                if (selectedPlayerId != null) {
                  _registerGoal(quarter, selectedPlayerId!, selectedAssistPlayerId);
                  Navigator.pop(context);
                } else {
                  Helpers.showSnackBar(
                    context,
                    '득점 선수를 선택해주세요.',
                    isError: true,
                  );
                }
              },
            ),
          ],
        );
      }
    );
  }
  
  void _registerGoal(int quarter, int playerId, int? assistPlayerId) {
    setState(() {
      _quarterScores[quarter]!['our_score'] = _quarterScores[quarter]!['our_score']! + 1;
      
      _goals.add({
        'quarter': quarter,
        'player_id': playerId,
        'assist_player_id': assistPlayerId,
      });
    });
  }
  
  void _goToNextStep() {
    int ourTotalScore = 0;
    int opponentTotalScore = 0;
    
    for (final quarterScore in _quarterScores.values) {
      ourTotalScore += quarterScore['our_score']!;
      opponentTotalScore += quarterScore['opponent_score']!;
    }
    
    final score = '$ourTotalScore:$opponentTotalScore';
    
    Navigator.pushNamed(
      context,
      AppRoutes.addMatchStep4,
      arguments: {
        'date': widget.date,
        'opponent': widget.opponent,
        'score': score,
        'playerIds': widget.playerIds,
        'quarterScores': _quarterScores,
        'goals': _goals,
      },
    );
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
          : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    return Column(
      children: [
        _buildStepIndicator(),
        Expanded(
          child: DefaultTabController(
            length: widget.quarters,
            child: Column(
              children: [
                Container(
                  color: AppColors.white,
                  child: TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.neutral,
                    indicatorColor: AppColors.primary,
                    tabs: List.generate(
                      widget.quarters,
                      (index) => Tab(
                        text: '${index + 1}쿼터',
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: List.generate(
                      widget.quarters,
                      (index) => _buildQuarterContent(index + 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStep(1, '기본 정보', true),
          _buildStep(2, '선수 선택', true),
          _buildStep(3, '점수 입력', false),
          _buildStep(4, '확인', true),
        ],
      ),
    );
  }
  
  Widget _buildStep(int step, String label, bool isCompleted) {
    final isCurrentStep = step == 3;
    final color = isCurrentStep ? AppColors.primary : AppColors.neutral;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCurrentStep ? AppColors.primary : AppColors.white,
            border: Border.all(
              color: color,
              width: 2,
            ),
            shape: BoxShape.circle,
          ),
          child: isCompleted
              ? Icon(
                  Icons.check,
                  size: 16,
                  color: isCurrentStep ? AppColors.white : color,
                )
              : Text(
                  step.toString(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isCurrentStep ? AppColors.white : color,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: color,
          ),
        ),
        if (step < 4) ...[
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 2,
            color: color,
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
  
  Widget _buildQuarterContent(int quarter) {
    final ourScore = _quarterScores[quarter]!['our_score']!;
    final opponentScore = _quarterScores[quarter]!['opponent_score']!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScoreInput(quarter),
          const SizedBox(height: 24),
          _buildGoalInput(quarter),
          const SizedBox(height: 24),
          AppButton(
            onPressed: () => _goToNextStep(),
            text: '다음',
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreInput(int quarter) {
    // 쿼터별 우리팀 득점 자동 계산
    final ourScore = _goals.where((goal) => goal['quarter'] == quarter).length;
    final opponentScore = _quarterScores[quarter]?['opponent_score'] ?? 0;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '점수',
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.neutral,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '우리팀',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.neutral.withOpacity(0.2)),
                        ),
                        child: Text(
                          ourScore.toString(),
                          style: AppTextStyles.displayLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  ':',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.neutral,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '상대팀',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            color: AppColors.primary,
                            onPressed: () {
                              setState(() {
                                final current = _quarterScores[quarter]?['opponent_score'] ?? 0;
                                _quarterScores[quarter] = {
                                  'our_score': ourScore,
                                  'opponent_score': current > 0 ? current - 1 : 0,
                                };
                              });
                            },
                          ),
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              opponentScore.toString(),
                              style: AppTextStyles.displayLarge.copyWith(
                                color: AppColors.neutral,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            color: AppColors.primary,
                            onPressed: () {
                              setState(() {
                                final current = _quarterScores[quarter]?['opponent_score'] ?? 0;
                                _quarterScores[quarter] = {
                                  'our_score': ourScore,
                                  'opponent_score': current + 1,
                                };
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGoalInput(int quarter) {
    final quarterGoals = _goals.where((goal) => goal['quarter'] == quarter).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppButton(
          text: '득점 추가',
          onPressed: () => _showScoreDialog(quarter, true),
        ),
        const SizedBox(height: 12),
        if (quarterGoals.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.neutral.withOpacity(0.2),
              ),
            ),
            child: Center(
              child: Text(
                '아직 득점 기록이 없습니다',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutral.withOpacity(0.5),
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: quarterGoals.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final goal = quarterGoals[index];
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
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        scorer.name[0],
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scorer.name,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.neutral,
                            ),
                          ),
                          if (assistPlayer != null)
                            Text(
                              '어시스트: ${assistPlayer.name}',
                              style: AppTextStyles.bodyMedium.copyWith(
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
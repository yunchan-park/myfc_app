import 'package:flutter/material.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/widgets/common/app_button.dart';
import 'package:myfc_app/utils/helpers.dart';

class AddMatchStep3Screen extends StatefulWidget {
  final String opponent;
  final DateTime date;
  final int quarters;
  final List<int> playerIds;
  
  const AddMatchStep3Screen({
    Key? key,
    required this.opponent,
    required this.date,
    required this.quarters,
    required this.playerIds,
  }) : super(key: key);

  @override
  State<AddMatchStep3Screen> createState() => _AddMatchStep3ScreenState();
}

class _AddMatchStep3ScreenState extends State<AddMatchStep3Screen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  late TabController _tabController;
  List<Player> _players = [];
  bool _isLoading = true;
  String _teamName = 'FC LINUX';
  
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
    _loadTeamName();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadTeamName() async {
    try {
      final teamIdString = await _storageService.getTeamId();
      final token = await _storageService.getToken();
      
      if (teamIdString != null) {
        final teamId = int.parse(teamIdString);
        final team = await _apiService.getTeam(teamId, token);
        if (mounted) {
          setState(() {
            _teamName = team.name;
          });
        }
      }
    } catch (e) {
      // 팀 이름을 불러오지 못해도 기본값 사용
    }
  }
  
  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final teamIdString = await _storageService.getTeamId();
      final token = await _storageService.getToken();
      
      if (teamIdString != null) {
        final teamId = int.parse(teamIdString);
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
  
  void _addGoal() {
    final currentQuarter = _tabController.index + 1;
    _showGoalDialog(currentQuarter);
  }
  
  void _addOpponentScore() {
    final currentQuarter = _tabController.index + 1;
    setState(() {
      _quarterScores[currentQuarter]!['opponent_score'] = 
          _quarterScores[currentQuarter]!['opponent_score']! + 1;
    });
  }
  
  void _removeGoal() {
    final currentQuarter = _tabController.index + 1;
    if (_quarterScores[currentQuarter]!['our_score']! > 0) {
      setState(() {
        _quarterScores[currentQuarter]!['our_score'] = 
            _quarterScores[currentQuarter]!['our_score']! - 1;
        
        // 해당 쿼터의 마지막 골 기록 제거
        final quarterGoals = _goals.where((goal) => goal['quarter'] == currentQuarter).toList();
        if (quarterGoals.isNotEmpty) {
          _goals.remove(quarterGoals.last);
        }
      });
    }
  }
  
  void _removeOpponentScore() {
    final currentQuarter = _tabController.index + 1;
    if (_quarterScores[currentQuarter]!['opponent_score']! > 0) {
      setState(() {
        _quarterScores[currentQuarter]!['opponent_score'] = 
            _quarterScores[currentQuarter]!['opponent_score']! - 1;
      });
    }
  }
  
  void _showGoalDialog(int quarter) {
    showDialog(
      context: context,
      builder: (context) => _buildGoalDialog(quarter),
    );
  }
  
  Widget _buildGoalDialog(int quarter) {
    int? selectedPlayerId;
    int? selectedAssistPlayerId;
    
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '${quarter}쿼터 득점 기록',
            style: AppTextStyles.displayMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '득점 선수',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedPlayerId,
                    hint: Text(
                      '득점 선수를 선택해주세요',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.neutral,
                      ),
                    ),
                    isExpanded: true,
                    items: _players.map((player) {
                      return DropdownMenuItem<int>(
                        value: player.id,
                        child: Text('${player.number}. ${player.name}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedPlayerId = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '어시스트 선수 (선택사항)',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: selectedAssistPlayerId,
                    hint: Text(
                      '어시스트 선수를 선택해주세요',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.neutral,
                      ),
                    ),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          '없음',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.neutral,
                          ),
                        ),
                      ),
                      ..._players
                          .where((player) => player.id != selectedPlayerId)
                          .map((player) {
                        return DropdownMenuItem<int?>(
                          value: player.id,
                          child: Text('${player.number}. ${player.name}'),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedAssistPlayerId = value;
                      });
                    },
                  ),
                ),
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
            ElevatedButton(
              onPressed: selectedPlayerId != null
                  ? () {
                      _registerGoal(quarter, selectedPlayerId!, selectedAssistPlayerId);
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
  
  void _registerGoal(int quarter, int playerId, int? assistPlayerId) {
    setState(() {
      _quarterScores[quarter]!['our_score'] = 
          _quarterScores[quarter]!['our_score']! + 1;
      
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
          '매치 등록',
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                _buildStepIndicator(),
                _buildQuarterTabs(),
                Expanded(child: _buildScoreContent()),
                _buildBottomButton(),
              ],
            ),
    );
  }
  
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepDot(1, false, true),
          _buildStepLine(true),
          _buildStepDot(2, false, true),
          _buildStepLine(true),
          _buildStepDot(3, true, false),
          _buildStepLine(false),
          _buildStepDot(4, false, false),
        ],
      ),
    );
  }
  
  Widget _buildStepDot(int step, bool isActive, bool isCompleted) {
    Color backgroundColor = AppColors.white;
    Color borderColor = AppColors.neutral;
    Widget? child;
    
    if (isCompleted) {
      backgroundColor = AppColors.primary;
      borderColor = AppColors.primary;
      child = Icon(Icons.check, size: 16, color: AppColors.white);
    } else if (isActive) {
      backgroundColor = AppColors.primary;
      borderColor = AppColors.primary;
      child = Text(
        step.toString(),
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      child = Text(
        step.toString(),
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.neutral,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
        shape: BoxShape.circle,
      ),
      child: Center(child: child),
    );
  }
  
  Widget _buildStepLine(bool isCompleted) {
    return Container(
      width: 32,
      height: 2,
      color: isCompleted ? AppColors.primary : AppColors.neutral,
    );
  }
  
  Widget _buildQuarterTabs() {
    return Container(
      color: AppColors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.neutral,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: List.generate(widget.quarters, (index) {
          final quarter = index + 1;
          final ourScore = _quarterScores[quarter]!['our_score']!;
          final opponentScore = _quarterScores[quarter]!['opponent_score']!;
          
          return Tab(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${quarter}쿼터',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$ourScore:$opponentScore',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildScoreContent() {
    return TabBarView(
      controller: _tabController,
      children: List.generate(widget.quarters, (index) {
        final quarter = index + 1;
        return _buildQuarterContent(quarter);
      }),
    );
  }
  
  Widget _buildQuarterContent(int quarter) {
    final ourScore = _quarterScores[quarter]!['our_score']!;
    final opponentScore = _quarterScores[quarter]!['opponent_score']!;
    final quarterGoals = _goals.where((goal) => goal['quarter'] == quarter).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 팀명 vs 팀명
          Text(
            '$_teamName vs ${widget.opponent}',
            style: AppTextStyles.displayMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          
          // 대형 점수 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;
                final scoreSize = isSmallScreen ? 48.0 : 56.0;
                final buttonSize = isSmallScreen ? 24.0 : 28.0;
                final spacing = isSmallScreen ? 8.0 : 16.0;
                
                return Column(
                  children: [
                    // 우리팀 점수
                    _buildTeamScoreSection(
                      teamName: _teamName,
                      score: ourScore,
                      color: AppColors.primary,
                      label: '득점',
                      onAdd: _addGoal,
                      onRemove: ourScore > 0 ? _removeGoal : null,
                      scoreSize: scoreSize,
                      buttonSize: buttonSize,
                      spacing: spacing,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 구분선과 VS
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.neutral)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'VS',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.neutral,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.neutral)),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 상대팀 점수
                    _buildTeamScoreSection(
                      teamName: widget.opponent,
                      score: opponentScore,
                      color: AppColors.error,
                      label: '실점',
                      onAdd: _addOpponentScore,
                      onRemove: opponentScore > 0 ? _removeOpponentScore : null,
                      scoreSize: scoreSize,
                      buttonSize: buttonSize,
                      spacing: spacing,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // 득점 상세 기록 및 빠른 조정 버튼
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _addGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sports_soccer, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        '득점 기록',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: ourScore > 0 ? _removeGoal : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ourScore > 0 ? AppColors.error : AppColors.neutral,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.undo, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        '득점 취소',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // 득점 기록 리스트
          if (quarterGoals.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${quarter}쿼터 득점 기록',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...quarterGoals.map((goal) {
                    final scorer = _players.firstWhere(
                      (p) => p.id == goal['player_id'],
                      orElse: () => Player(
                        id: 0,
                        name: '알 수 없음',
                        position: 'Unknown',
                        number: 0,
                        teamId: 0,
                      ),
                    );
                    
                    final assister = goal['assist_player_id'] != null
                        ? _players.firstWhere(
                            (p) => p.id == goal['assist_player_id'],
                            orElse: () => Player(
                              id: 0,
                              name: '알 수 없음',
                              position: 'Unknown',
                              number: 0,
                              teamId: 0,
                            ),
                          )
                        : null;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              assister != null
                                  ? 'GOAL ${scorer.name} (${assister.name})'
                                  : 'GOAL ${scorer.name}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTeamScoreSection({
    required String teamName,
    required int score,
    required Color color,
    required String label,
    required VoidCallback onAdd,
    required VoidCallback? onRemove,
    required double scoreSize,
    required double buttonSize,
    required double spacing,
  }) {
    return Column(
      children: [
        Text(
          teamName,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 감소 버튼
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.remove_circle,
                color: onRemove != null ? color : AppColors.neutral,
                size: buttonSize,
              ),
              constraints: BoxConstraints(
                minWidth: buttonSize + 16,
                minHeight: buttonSize + 16,
              ),
              padding: EdgeInsets.all(spacing / 2),
            ),
            SizedBox(width: spacing),
            // 점수 표시
            Container(
              constraints: const BoxConstraints(minWidth: 80),
              child: Text(
                score.toString(),
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: scoreSize,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: spacing),
            // 증가 버튼
            IconButton(
              onPressed: onAdd,
              icon: Icon(
                Icons.add_circle,
                color: color,
                size: buttonSize,
              ),
              constraints: BoxConstraints(
                minWidth: buttonSize + 16,
                minHeight: buttonSize + 16,
              ),
              padding: EdgeInsets.all(spacing / 2),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.white,
      child: SafeArea(
        child: AppButton(
          onPressed: _goToNextStep,
          text: '다음 단계로',
        ),
      ),
    );
  }
} 
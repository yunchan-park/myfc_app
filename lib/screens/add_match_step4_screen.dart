import 'package:flutter/material.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/widgets/common/app_button.dart';
import 'package:intl/intl.dart';

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
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  
  bool _isSubmitting = false;
  String _teamName = 'FC LINUX';
  List<Player> _players = [];
  int _selectedQuarter = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final teamId = await _authService.getTeamId();
      final token = await _authService.getToken();
      
      if (teamId != null) {
        // 팀 정보 로드
        final team = await _apiService.getTeam(teamId, token);
        
        // 선수 정보 로드
        final allPlayers = await _apiService.getTeamPlayers(teamId, token);
        final selectedPlayers = allPlayers.where(
          (player) => (widget.matchData['playerIds'] as List).contains(player.id)
        ).toList();
        
        if (mounted) {
          setState(() {
            _teamName = team.name;
            _players = selectedPlayers;
          });
        }
      }
    } catch (e) {
      // 에러 발생 시 기본값 사용
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
          
          // Navigate back to home screen
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
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMatchHeader(),
                    const SizedBox(height: 24),
                    _buildScoreCard(),
                    const SizedBox(height: 24),
                    _buildQuarterScoresTable(),
                    const SizedBox(height: 24),
                    if (widget.matchData['goals'] != null && 
                        (widget.matchData['goals'] as List).isNotEmpty)
                      _buildGoalsSection(),
                  ],
                ),
              ),
            ),
          ),
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
          _buildStepDot(3, false, true),
          _buildStepLine(true),
          _buildStepDot(4, true, false),
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

  Widget _buildMatchHeader() {
    final date = widget.matchData['date'] as DateTime;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            '경기 요약',
            style: AppTextStyles.displayMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat('yyyy년 MM월 dd일').format(date),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.neutral,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '참여 선수: ${widget.matchData['playerIds'].length}명',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    final scores = widget.matchData['score'].toString().split(':');
    final ourScore = scores[0];
    final opponentScore = scores[1];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 팀명
          Text(
            '$_teamName vs ${widget.matchData['opponent']}',
            style: AppTextStyles.displayMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // 대형 점수
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 우리팀 점수
              Column(
                children: [
                  Text(
                    _teamName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ourScore,
                    style: AppTextStyles.displayLarge.copyWith(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              
              // 구분선
              Text(
                ':',
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral,
                ),
              ),
              
              // 상대팀 점수
              Column(
                children: [
                  Text(
                    widget.matchData['opponent'],
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    opponentScore,
                    style: AppTextStyles.displayLarge.copyWith(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuarterScoresTable() {
    final quarterScores = widget.matchData['quarterScores'] as Map<int, Map<String, int>>;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              '쿼터별 점수',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // 쿼터별 탭
          Container(
            height: 50,
            child: Row(
              children: List.generate(quarterScores.length, (index) {
                final quarter = index + 1;
                final isSelected = _selectedQuarter == quarter;
                
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedQuarter = quarter;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${quarter}쿼터',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.neutral,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // 선택된 쿼터 점수
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  '${_selectedQuarter}쿼터',
                  style: AppTextStyles.displayMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          _teamName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          quarterScores[_selectedQuarter]!['our_score'].toString(),
                          style: AppTextStyles.displayLarge.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      ':',
                      style: AppTextStyles.displayLarge.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          widget.matchData['opponent'],
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          quarterScores[_selectedQuarter]!['opponent_score'].toString(),
                          style: AppTextStyles.displayLarge.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection() {
    final goals = widget.matchData['goals'] as List;
    final quarterGoals = goals.where((goal) => goal['quarter'] == _selectedQuarter).toList();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_selectedQuarter}쿼터 골 기록',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          
          if (quarterGoals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_selectedQuarter}쿼터에는 득점 기록이 없습니다.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutral,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
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
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.sports_soccer,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GOAL ${scorer.name}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          if (assister != null)
                            Text(
                              'Assist: ${assister.name}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.white,
      child: SafeArea(
        child: AppButton(
          text: '매치 등록 완료하기',
          onPressed: _isSubmitting ? null : _submitMatch,
          isLoading: _isSubmitting,
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/utils/helpers.dart';
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
  final AuthService _authService = AuthService();
  
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
      final teamId = await _authService.getTeamId();
      final token = await _authService.getToken();
      
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
      final teamId = await _authService.getTeamId();
      final token = await _authService.getToken();
      
      if (teamId != null) {
        // Create match
        final match = await _apiService.createMatch(
          widget.matchData['date'],
          widget.matchData['opponent'],
          widget.matchData['score'],
          teamId,
          widget.matchData['playerIds'].cast<int>(),
          token
        );
        
        // Add goals if there are any
        if (widget.matchData['goals'] != null) {
          for (final goal in widget.matchData['goals']) {
            await _apiService.addGoal(
              match.id,
              goal['player_id'],
              goal['assist_player_id'],
              goal['quarter'],
              token
            );
          }
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
      appBar: AppBar(
        title: const Text('매치 추가'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[300],
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        const Text(
                          '경기 요약',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitMatch,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('매치 등록 완료하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
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
        color: isActive ? Colors.black : Colors.grey[300],
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
  
  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 2,
        color: Colors.grey[300],
      ),
    );
  }
  
  Widget _buildMatchSummary() {
    // Parse score
    final scoreComponents = widget.matchData['score'].split(':');
    final ourScore = int.parse(scoreComponents[0]);
    final opponentScore = int.parse(scoreComponents[1]);
    
    // Determine result
    String result = '무';
    Color resultColor = Colors.grey;
    if (ourScore > opponentScore) {
      result = '승';
      resultColor = Colors.blue;
    } else if (ourScore < opponentScore) {
      result = '패';
      resultColor = Colors.red;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date and opponent
            Row(
              children: [
                Text(
                  Helpers.formatDateKorean(widget.matchData['date']),
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: resultColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Teams and score
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: const Text(
                    '우리 팀',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.matchData['score'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.matchData['opponent'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Player count
            Text(
              '참여 선수: ${_players.length}명',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuarterScores() {
    final Map<int, QuarterScore> quarterScores = {};
    final rawQuarterScores = widget.matchData['quarterScores'] as Map<dynamic, dynamic>;
    
    rawQuarterScores.forEach((key, value) {
      final quarter = int.parse(key.toString());
      final scores = value as Map<String, dynamic>;
      
      quarterScores[quarter] = QuarterScore(
        ourScore: scores['our_score'],
        opponentScore: scores['opponent_score'],
      );
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '쿼터별 스코어',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        QuarterScoreWidget(
          quarterScores: quarterScores,
          selectedQuarter: 1, // Default to first quarter
          maxQuarters: quarterScores.length,
        ),
      ],
    );
  }
  
  Widget _buildGoalsSummary() {
    final goals = widget.matchData['goals'] as List;
    
    // Group goals by quarter
    final quarterGoals = <int, List<Goal>>{};
    
    for (final goal in goals) {
      final quarter = goal['quarter'] as int;
      
      // Find player names
      final player = _players.firstWhere(
        (p) => p.id == goal['player_id'],
        orElse: () => Player(
          id: 0,
          name: '알 수 없음',
          number: 0,
          position: '',
          teamId: 0,
          createdAt: DateTime.now(),
        ),
      );
      
      String? assistName;
      if (goal['assist_player_id'] != null) {
        final assistPlayer = _players.firstWhere(
          (p) => p.id == goal['assist_player_id'],
          orElse: () => Player(
            id: 0,
            name: '알 수 없음',
            number: 0,
            position: '',
            teamId: 0,
            createdAt: DateTime.now(),
          ),
        );
        assistName = '${assistPlayer.name} (${assistPlayer.number}번)';
      }
      
      if (!quarterGoals.containsKey(quarter)) {
        quarterGoals[quarter] = [];
      }
      
      quarterGoals[quarter]!.add(Goal(
        scorer: '${player.name} (${player.number}번)',
        assistant: assistName,
        quarter: quarter,
      ));
    }
    
    // Sort quarters
    final quarters = quarterGoals.keys.toList()..sort();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '득점 기록',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...quarters.map((quarter) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$quarter쿼터',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GoalListWidget(
                        goals: quarterGoals[quarter]!,
                        emptyMessage: '이 쿼터에 득점 기록이 없습니다.',
                      ),
                      const Divider(),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 
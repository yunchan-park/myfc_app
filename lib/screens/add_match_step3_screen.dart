import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/widgets/widgets.dart';

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
  
  // Quarter scores (quarter number -> {our_score, opponent_score})
  Map<int, Map<String, int>> _quarterScores = {};
  
  // Goal records
  List<Map<String, dynamic>> _goals = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.quarters, vsync: this);
    
    // Initialize quarter scores
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
      if (teamId != null) {
        final allPlayers = await _apiService.getTeamPlayers(teamId);
        
        // Filter players by selected playerIds
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
          title: const Text('득점 정보'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('득점 선수'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  hintText: '득점 선수를 선택해주세요',
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
              const Text('어시스트 선수 (선택)'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                decoration: const InputDecoration(
                  hintText: '어시스트 선수를 선택해주세요',
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
              child: const Text('취소'),
            ),
            ElevatedButton(
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
              child: const Text('확인'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
            ),
          ],
        );
      }
    );
  }
  
  void _registerGoal(int quarter, int playerId, int? assistPlayerId) {
    setState(() {
      // Update quarter score
      _quarterScores[quarter]!['our_score'] = _quarterScores[quarter]!['our_score']! + 1;
      
      // Add goal record
      _goals.add({
        'quarter': quarter,
        'player_id': playerId,
        'assist_player_id': assistPlayerId,
      });
    });
  }
  
  void _goToNextStep() {
    // Calculate total score
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
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildStepIndicator(),
                ),
                
                // Tab bar
                TabBar(
                  controller: _tabController,
                  tabs: List.generate(widget.quarters, (index) {
                    return Tab(text: '${index + 1}쿼터');
                  }),
                  indicatorColor: Colors.black,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                ),
                
                // Tab views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: List.generate(widget.quarters, (index) {
                      return _buildQuarterScoreTab(index + 1);
                    }),
                  ),
                ),
                
                // Next button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _goToNextStep,
                    child: const Text('다음 단계로'),
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
        _buildStepCircle(3, true),
        _buildStepLine(),
        _buildStepCircle(4, false),
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
  
  Widget _buildQuarterScoreTab(int quarter) {
    final quarterScore = _quarterScores[quarter]!;
    
    // Create goals list
    final quarterGoals = _goals
        .where((goal) => goal['quarter'] == quarter)
        .map((goal) {
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
          
          String? assistPlayerName;
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
            assistPlayerName = '${assistPlayer.name} (${assistPlayer.number}번)';
          }
          
          return Goal(
            scorer: '${player.name} (${player.number}번)',
            assistant: assistPlayerName,
            quarter: quarter,
            id: goal.hashCode.toString(), // Use hash as unique identifier
          );
        })
        .toList();
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Score display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '우리 팀',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '${quarterScore['our_score']} : ${quarterScore['opponent_score']}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.opponent,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _addOurScore(quarter),
                  icon: const Icon(Icons.add),
                  label: const Text('득점 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _addOpponentScore(quarter),
                  icon: const Icon(Icons.add),
                  label: const Text('실점 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Goals list for this quarter
          if (_goals.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '득점 기록',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Expanded(
                    child: GoalListWidget(
                      goals: quarterGoals,
                      isEditable: true,
                      onDeleteGoal: (goalId) {
                        if (goalId != null) {
                          // Find corresponding goal in _goals
                          final goalIndex = _goals.indexWhere((g) => g.hashCode.toString() == goalId);
                          if (goalIndex >= 0) {
                            setState(() {
                              _goals.removeAt(goalIndex);
                              _quarterScores[quarter]!['our_score'] = _quarterScores[quarter]!['our_score']! - 1;
                            });
                          }
                        }
                      },
                      emptyMessage: '이 쿼터에 득점 기록이 없습니다.',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 
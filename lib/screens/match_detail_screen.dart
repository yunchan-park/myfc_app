import 'package:flutter/material.dart';
import 'package:myfc_app/models/match.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/config/routes.dart';
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
  Match? _match;
  int _selectedQuarter = 1;
  String _opponentName = 'FC UNIX';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatchDetails();
  }

  Future<void> _loadMatchDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final match = await _apiService.getMatchDetail(widget.matchId, token);
      print('매치 세부 정보 로드됨: ${match.id}, 상대: ${match.opponent}, 점수: ${match.score}');
      
      // 상대팀 이름 설정
      setState(() {
        _match = match;
        _opponentName = match.opponent;
        _isLoading = false;
      });
      
      // 디버그 로그 출력
      if (match.quarterScores != null) {
        print('쿼터 스코어: ${match.quarterScores!.length}개');
        match.quarterScores!.forEach((quarter, score) {
          print('$quarter쿼터: ${score.ourScore}:${score.opponentScore}');
        });
      }
      
      if (match.goals != null) {
        print('골 기록: ${match.goals!.length}개');
        for (var goal in match.goals!) {
          final playerName = goal.player?.name ?? '알 수 없음';
          final assistName = goal.assistPlayer?.name ?? '없음';
          print('$playerName의 골 (쿼터: ${goal.quarter}, 어시스트: $assistName)');
        }
      }
    } catch (e) {
      print('매치 세부 정보 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
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
      print('매치 삭제 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('매치 삭제 실패: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('매치 삭제'),
        content: const Text('정말 이 매치를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteMatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _confirmDelete,
            tooltip: '매치 삭제',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _match == null
              ? const Center(child: Text('매치 정보를 불러올 수 없습니다.'))
              : _buildMatchDetailContent(),
    );
  }

  Widget _buildMatchDetailContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScoreCard(),
            const SizedBox(height: 20),
            if (_match!.quarterScores != null && _match!.quarterScores!.isNotEmpty)
              Column(
                children: [
                  _buildQuarterScoreWidget(),
                  const SizedBox(height: 20),
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
    
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              _match!.date,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Expanded(
                  child: Text(
                    'FC C++',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  '$ourScore : $opponentScore',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    _opponentName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '결과: ${_match!.getResult()}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _match!.getResultEnum() == MatchResult.win
                    ? Colors.green
                    : _match!.getResultEnum() == MatchResult.lose
                        ? Colors.red
                        : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuarterScoreWidget() {
    if (_match!.quarterScores == null || _match!.quarterScores!.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('쿼터 스코어 정보가 없습니다.'),
        ),
      );
    }

    // Convert from Match.QuarterScore to widgets.QuarterScore
    Map<int, widgets.QuarterScore> widgetQuarterScores = {};
    _match!.quarterScores!.forEach((quarter, score) {
      widgetQuarterScores[quarter] = widgets.QuarterScore(
        ourScore: score.ourScore, 
        opponentScore: score.opponentScore
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '쿼터별 스코어',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        widgets.QuarterScoreWidget(
          quarterScores: widgetQuarterScores,
          selectedQuarter: _selectedQuarter,
          onQuarterSelected: (quarter) {
            setState(() {
              _selectedQuarter = quarter;
            });
          },
          maxQuarters: 4,
        ),
      ],
    );
  }

  Widget _buildGoalScorers() {
    if (_match!.goals == null || _match!.goals!.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('득점 기록이 없습니다.')),
        ),
      );
    }
    
    // 현재 선택된 쿼터의 골만 필터링
    final List<Goal> quarterGoals = _match!.goals!
        .where((goal) => goal.quarter == _selectedQuarter)
        .toList();
    
    // 쿼터에 따른 골 수 맵 생성
    final Map<int, int> goalsPerQuarter = {};
    for (var goal in _match!.goals!) {
      goalsPerQuarter[goal.quarter] = (goalsPerQuarter[goal.quarter] ?? 0) + 1;
    }
    
    // 위젯에서 사용할 Goal 객체로 변환
    final List<widgets.Goal> widgetGoals = quarterGoals.map((goal) {
      final Player? scorer = goal.player;
      String scorerDisplay = '알 수 없음';
      
      if (scorer != null) {
        scorerDisplay = '${scorer.name} (${scorer.number}번)';
        
        // 로그 출력
        print('골 스코어러: ${scorer.name}, 골 수: ${scorer.goalCount}, 어시스트 수: ${scorer.assistCount}, MOM 수: ${scorer.momCount}');
      }
      
      String? assistantDisplay;
      if (goal.assistPlayer != null) {
        final Player assistPlayer = goal.assistPlayer!;
        assistantDisplay = '${assistPlayer.name} (${assistPlayer.number}번)';
        
        // 로그 출력
        print('어시스트: ${assistPlayer.name}, 골 수: ${assistPlayer.goalCount}, 어시스트 수: ${assistPlayer.assistCount}, MOM 수: ${assistPlayer.momCount}');
      }
      
      return widgets.Goal(
        scorer: scorerDisplay,
        assistant: assistantDisplay,
        quarter: goal.quarter,
        id: goal.id.toString(),
      );
    }).toList();

    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  '득점 기록',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 현재 쿼터 표시
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$_selectedQuarter쿼터',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            
            // 쿼터 선택 버튼
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [1, 2, 3, 4].map((quarter) {
                  final hasGoals = goalsPerQuarter.containsKey(quarter) && goalsPerQuarter[quarter]! > 0;
                  
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedQuarter == quarter
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade200,
                          foregroundColor: _selectedQuarter == quarter
                              ? Colors.white
                              : Colors.black87,
                          disabledBackgroundColor: Colors.grey.shade100,
                          disabledForegroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedQuarter = quarter;
                          });
                        },
                        child: Text(
                          '$quarter쿼터${hasGoals ? ' (${goalsPerQuarter[quarter]})' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _selectedQuarter == quarter ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // 골 목록
            if (quarterGoals.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('이 쿼터의 득점 기록이 없습니다.')),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: widgets.GoalListWidget(
                  goals: widgetGoals,
                  emptyMessage: '이 쿼터에는 득점 기록이 없습니다.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
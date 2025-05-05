import 'package:flutter/material.dart';
import 'package:myfc_app/models/match.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/widgets/widgets.dart';

class MatchDetailScreen extends StatefulWidget {
  final int matchId;
  
  const MatchDetailScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  
  Match? _match;
  bool _isLoading = true;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMatchDetail();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMatchDetail() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final match = await _apiService.getMatchDetail(widget.matchId);
      
      setState(() {
        _match = match;
      });
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '경기 정보를 불러오는 데 실패했습니다.',
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매치 상세 정보'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
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
        : _match == null
          ? const Center(child: Text('경기 정보를 불러올 수 없습니다.'))
          : SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Team names and score
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '우리 팀',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _match!.score,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _match!.opponent,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Match date
                          Text(
                            Helpers.formatDateKorean(_match!.date),
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Quarter score summary
                          if (_match!.quarterScores != null && _match!.quarterScores!.isNotEmpty)
                            _buildQuarterScoreSummary(),
                        ],
                      ),
                    ),
                  ),
                  
                  // Quarter tabs
                  if (_match!.quarterScores != null && _match!.quarterScores!.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Divider(color: Colors.grey[300], height: 1),
                          
                          TabBar(
                            controller: _tabController,
                            indicatorColor: Colors.black,
                            labelColor: Colors.black,
                            unselectedLabelColor: Colors.grey,
                            tabs: _buildQuarterTabs(),
                          ),
                        ],
                      ),
                    ),
                    
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 300,
                        child: TabBarView(
                          controller: _tabController,
                          children: _buildQuarterViews(),
                        ),
                      ),
                    ),
                  ],
                  
                  // Goals summary
                  if (_match!.goals != null && _match!.goals!.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildGoalsSummary(),
                    ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildQuarterScoreSummary() {
    final quarterScores = <int, QuarterScore>{};
    _match!.quarterScores!.forEach((quarter, score) {
      quarterScores[quarter] = QuarterScore(
        ourScore: score.ourScore,
        opponentScore: score.opponentScore,
      );
    });
    
    return QuarterScoreWidget(
      quarterScores: quarterScores,
      selectedQuarter: _tabController.index + 1,
      onQuarterSelected: (quarter) {
        _tabController.animateTo(quarter - 1);
      },
      maxQuarters: _match!.quarterScores!.length,
    );
  }
  
  List<Tab> _buildQuarterTabs() {
    final quarterKeys = _match!.quarterScores!.keys.toList()..sort();
    
    return quarterKeys.map((quarter) => Tab(
      text: '${quarter}쿼터',
    )).toList();
  }
  
  List<Widget> _buildQuarterViews() {
    final quarterKeys = _match!.quarterScores!.keys.toList()..sort();
    
    return quarterKeys.map((quarter) => _buildQuarterDetails(quarter)).toList();
  }
  
  Widget _buildQuarterDetails(int quarter) {
    final quarterScore = _match!.quarterScores![quarter]!;
    final quarterGoals = _match!.goals
        ?.where((goal) => goal.quarter == quarter)
        .toList() ?? [];
    
    // Convert to Goal objects for GoalListWidget
    final goals = quarterGoals.map((goal) {
      return Goal(
        scorer: goal.player?.name ?? '알 수 없음',
        assistant: goal.assistPlayer?.name,
        quarter: quarter,
      );
    }).toList();
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quarter score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  '우리 팀',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${quarterScore.ourScore} : ${quarterScore.opponentScore}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _match!.opponent,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Goals in this quarter
          if (quarterGoals.isNotEmpty) ...[
            const Text(
              '득점 기록',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: SingleChildScrollView(
                child: GoalListWidget(
                  goals: goals,
                  emptyMessage: '이 쿼터에 득점 기록이 없습니다.',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildGoalsSummary() {
    if (_match!.goals == null || _match!.goals!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Group goals by player
    final playerGoals = <int, int>{};
    final playerAssists = <int, int>{};
    
    for (final goal in _match!.goals!) {
      playerGoals[goal.playerId] = (playerGoals[goal.playerId] ?? 0) + 1;
      
      if (goal.assistPlayerId != null) {
        playerAssists[goal.assistPlayerId!] = (playerAssists[goal.assistPlayerId!] ?? 0) + 1;
      }
    }
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '개인 통계',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Goal scorers
          if (playerGoals.isNotEmpty) ...[
            const Text(
              '득점',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...playerGoals.entries.map((entry) {
              final player = _match!.goals!
                  .firstWhere((goal) => goal.playerId == entry.key)
                  .player;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        player?.name ?? '알 수 없음',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${entry.value}골'),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
          
          // Assist providers
          if (playerAssists.isNotEmpty) ...[
            const Text(
              '어시스트',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...playerAssists.entries.map((entry) {
              final player = _match!.goals!
                  .firstWhere((goal) => goal.assistPlayerId == entry.key)
                  .assistPlayer;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        player?.name ?? '알 수 없음',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${entry.value}개'),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
} 
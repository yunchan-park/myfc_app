import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/models/team.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/models/match.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:intl/intl.dart';

class TeamProfileScreen extends StatefulWidget {
  const TeamProfileScreen({Key? key}) : super(key: key);

  @override
  State<TeamProfileScreen> createState() => TeamProfileScreenState();
}

class TeamProfileScreenState extends State<TeamProfileScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  Team? _team;
  List<Player> _players = [];
  List<Match> _matches = [];
  bool _isLoading = true;
  bool _isImageLoading = false;
  bool _hasError = false;
  
  int _totalMatches = 0;
  int _wins = 0;
  int _draws = 0;
  int _losses = 0;
  int _totalGoalsScored = 0;
  int _totalGoalsConceded = 0;
  
  // Player awards
  Player? _topScorer;
  Player? _topAssister;
  Player? _mvp;
  
  Team? get team => _team;
  List<Player> get players => _players;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      final teamId = await _authService.getTeamId();
      final token = await _authService.getToken();
      
      if (teamId != null && token != null) {
        final team = await _apiService.getTeam(teamId, token);
        
        final matches = await _apiService.getTeamMatches(teamId, token);
        
        final players = await _apiService.getTeamPlayers(teamId, token);
        
        _calculateMatchStatistics(matches);
        
        // 선수 어워드 계산
        _topScorer = null;
        _topAssister = null;
        _mvp = null;
        if (players.isNotEmpty) {
          final scorer = players.reduce((a, b) => a.goalCount >= b.goalCount ? a : b);
          if (scorer.goalCount > 0) _topScorer = scorer;
          final assister = players.reduce((a, b) => a.assistCount >= b.assistCount ? a : b);
          if (assister.assistCount > 0) _topAssister = assister;
          final mvp = players.reduce((a, b) => a.momCount >= b.momCount ? a : b);
          if (mvp.momCount > 0) _mvp = mvp;
        }
        
        if (mounted) {
          setState(() {
            _team = team;
            _matches = matches;
            _players = players;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading team profile: $e');
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '데이터를 불러오는 데 실패했습니다.',
          isError: true,
        );
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }
  
  void _calculateMatchStatistics(List<Match> matches) {
    _totalMatches = matches.length;
    _wins = matches.where((m) => m.getResult() == '승').length;
    _draws = matches.where((m) => m.getResult() == '무').length;
    _losses = matches.where((m) => m.getResult() == '패').length;
    
    _totalGoalsScored = matches.fold(0, (sum, m) => sum + m.ourScore);
    _totalGoalsConceded = matches.fold(0, (sum, m) => sum + m.opponentScore);
  }
  
  Future<List<Match>> _getRecentMatches(int limit) async {
    try {
      final teamId = await _authService.getTeamId();
      final token = await _authService.getToken();
      if (teamId != null && token != null) {
        final matches = await _apiService.getTeamMatches(teamId, token);
        final recent = matches.take(limit).toList();
        List<Match> detailed = [];
        for (var match in recent) {
          final detail = await _apiService.getMatchDetail(match.id, token);
          detailed.add(detail);
        }
        return detailed;
      }
    } catch (e) {
      print('매치 데이터 가져오기 실패: $e');
    }
    return [];
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_team == null || _hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('구단 정보를 불러올 수 없습니다.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder<List<Match>>(
              future: _getRecentMatches(5),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 400,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return MatchCardsSlider(
                    matches: snapshot.data!,
                    teamName: _team?.name ?? '',
                  );
                }
                return Container(
                  height: 400,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_soccer, size: 48, color: Color(0xFF9CA3AF)),
                        SizedBox(height: 16),
                        Text(
                          '등록된 매치가 없습니다',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildPlayerAwardsSection(),
            const SizedBox(height: 16),
            _buildPlayerStatsCard(context),
            const SizedBox(height: 16),
            _buildMatchStatsCard(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlayerStatsCard(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(context, '/player-management');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${_players.length}명',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(width: 8),
              Text(
                '총 선수',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMatchStatsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$_totalMatches매치',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 16),
                _buildResultChip('승', _wins, const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _buildResultChip('무', _draws, const Color(0xFF9CA3AF)),
                const SizedBox(width: 8),
                _buildResultChip('패', _losses, const Color(0xFFEF4444)),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatText('승', _wins, _totalMatches, const Color(0xFF3B82F6)),
                      const SizedBox(height: 8),
                      _buildStatText('무', _draws, _totalMatches, const Color(0xFF9CA3AF)),
                      const SizedBox(height: 8),
                      _buildStatText('패', _losses, _totalMatches, const Color(0xFFEF4444)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildScoreText('합계', '$_totalGoalsScored 득점', '$_totalGoalsConceded 실점'),
                      const SizedBox(height: 8),
                      _buildScoreText(
                        '평균',
                        '${(_totalGoalsScored / (_totalMatches == 0 ? 1 : _totalMatches)).toStringAsFixed(1)} 득점',
                        '${(_totalGoalsConceded / (_totalMatches == 0 ? 1 : _totalMatches)).toStringAsFixed(1)} 실점',
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
  
  Widget _buildResultChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildProgressBar() {
    final winRatio = _totalMatches > 0 ? _wins / _totalMatches : 0.0;
    final drawRatio = _totalMatches > 0 ? _draws / _totalMatches : 0.0;
    final lossRatio = _totalMatches > 0 ? _losses / _totalMatches : 0.0;
    
    return Row(
      children: [
        Expanded(
          flex: (winRatio * 100).round(),
          child: Container(
            height: 8,
            color: const Color(0xFF3B82F6),
          ),
        ),
        Expanded(
          flex: (drawRatio * 100).round(),
          child: Container(
            height: 8,
            color: const Color(0xFF9CA3AF),
          ),
        ),
        Expanded(
          flex: (lossRatio * 100).round(),
          child: Container(
            height: 8,
            color: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatText(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    return Text(
      '$label $count $percentage%',
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildScoreText(String label, String scored, String conceded) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          scored,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          conceded,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerAwardsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAwardCard('득점왕', _topScorer),
          _buildAwardCard('도움왕', _topAssister),
          _buildAwardCard('MOM', _mvp),
        ],
      ),
    );
  }

  Widget _buildAwardCard(String title, Player? player) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFFE5E7EB),
                    child: const Icon(Icons.person, size: 40, color: Color(0xFF9CA3AF)),
                  ),
                  Positioned(
                    top: 0,
                    child: Icon(Icons.emoji_events, color: Color(0xFFFFC107), size: 32),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                player != null ? player.name : '선정된\n선수가 없어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: player != null ? Colors.black : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MatchCardsSlider extends StatefulWidget {
  final List<Match> matches;
  final String teamName;
  const MatchCardsSlider({Key? key, required this.matches, required this.teamName}) : super(key: key);

  @override
  State<MatchCardsSlider> createState() => _MatchCardsSliderState();
}

class _MatchCardsSliderState extends State<MatchCardsSlider> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.matches.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final match = widget.matches[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: MatchCardBanner(
                    match: match,
                    teamName: widget.teamName,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/match_detail',
                        arguments: match.id,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.matches.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _currentIndex == index ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class MatchCardBanner extends StatelessWidget {
  final Match match;
  final String teamName;
  final VoidCallback? onTap;
  const MatchCardBanner({Key? key, required this.match, required this.teamName, this.onTap}) : super(key: key);

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return DateFormat('yyyy.MM.dd').format(dt);
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = match.goals ?? [];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 350,
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/soccer_field_background.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          _formatDate(match.date),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '$teamName vs ${match.opponent}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            match.score,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '득점자',
                                  style: TextStyle(
                                    color: Color(0xFFD1D5DB),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...goals.map((goal) => Text(
                                  goal.player?.name ?? '',
                                  style: const TextStyle(
                                    color: Color(0xFFE5E7EB),
                                    fontSize: 14,
                                  ),
                                )),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  '어시스트',
                                  style: TextStyle(
                                    color: Color(0xFFD1D5DB),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...goals.where((goal) => goal.assistPlayer != null)
                                    .map((goal) => Text(
                                  goal.assistPlayer!.name,
                                  style: const TextStyle(
                                    color: Color(0xFFE5E7EB),
                                    fontSize: 14,
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/models/team.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/models/match.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/widgets/common/app_button.dart';
import 'package:myfc_app/widgets/common/app_card.dart';
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
  
  bool _showPlayerList = false;
  
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
        final matches = await _apiService.getRecentMatches(teamId, token, limit: limit);
        List<Match> detailed = [];
        for (var match in matches) {
          final detail = await _apiService.getMatchDetail(match.id, token);
          detailed.add(detail);
        }
        return detailed;
      }
    } catch (e) {
      // 매치 데이터 가져오기 실패는 무시
    }
    return [];
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }
    
    if (_team == null || _hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '구단 정보를 불러올 수 없습니다.',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 16),
            AppButton(
              text: '다시 시도',
              onPressed: _loadData,
            ),
          ],
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder<List<Match>>(
              future: _getRecentMatches(5),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 400,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
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
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          size: 48,
                          color: AppColors.neutral,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '등록된 매치가 없습니다',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.neutral,
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
            _buildPlayerStatsAccordion(context),
            const SizedBox(height: 16),
            FutureBuilder<List<Match>>(
              future: _getRecentMatches(9),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  );
                }
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return RecentMatchSummaryCard(recentMatches: snapshot.data!);
                }
                return Container(
                  height: 180,
                  child: Center(
                    child: Text('최근 매치 데이터가 없습니다'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlayerStatsAccordion(BuildContext context) {
    return Column(
      children: [
        AppCard(
          onTap: () {
            setState(() {
              _showPlayerList = !_showPlayerList;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${_players.length}명',
                  style: AppTextStyles.displaySmall,
                ),
                const SizedBox(width: 8),
                Text(
                  '총 선수',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.neutral,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _showPlayerList ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.neutral,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildPlayerList(),
          crossFadeState: _showPlayerList ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildPlayerList() {
    if (_players.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            '등록된 선수가 없습니다',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.neutral,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: _players.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final player = _players[index];
        return AppCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    player.number.toString(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 15),
                      ),
                      Text(
                        player.position,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutral,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPlayerAwardsSection() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '선수 어워드',
              style: AppTextStyles.displaySmall,
            ),
            const SizedBox(height: 16),
            if (_topScorer != null)
              _buildAwardItem(
                '득점왕',
                _topScorer!.name,
                _topScorer!.goalCount.toString(),
                Icons.sports_soccer,
              ),
            if (_topAssister != null)
              _buildAwardItem(
                '도움왕',
                _topAssister!.name,
                _topAssister!.assistCount.toString(),
                Icons.assistant,
              ),
            if (_mvp != null)
              _buildAwardItem(
                'MVP',
                _mvp!.name,
                _mvp!.momCount.toString(),
                Icons.emoji_events,
              ),
            if (_topScorer == null && _topAssister == null && _mvp == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '아직 어워드가 없습니다',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.neutral,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAwardItem(String title, String playerName, String count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral,
                  ),
                ),
                Text(
                  playerName,
                  style: AppTextStyles.bodyLarge,
                ),
              ],
            ),
          ),
          Text(
            count,
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
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
    if (date.contains('T')) {
      return date.split('T').first;
    }
    try {
      final dt = DateTime.parse(date);
      return DateFormat('yyyy-MM-dd').format(dt);
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
                                  goal.player?.name?.isNotEmpty == true
                                    ? goal.player!.name
                                    : (goal.scorerName ?? ''),
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
                                ...goals.where((goal) => goal.assistPlayer != null || (goal.assistName != null && goal.assistName!.isNotEmpty))
                                    .map((goal) => Text(
                                  goal.assistPlayer?.name?.isNotEmpty == true
                                    ? goal.assistPlayer!.name
                                    : (goal.assistName ?? ''),
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

class RecentMatchSummaryCard extends StatelessWidget {
  final List<Match> recentMatches;

  const RecentMatchSummaryCard({required this.recentMatches, super.key});

  @override
  Widget build(BuildContext context) {
    final total = recentMatches.length;
    final wins = recentMatches.where((m) => m.getResult() == '승').length;
    final draws = recentMatches.where((m) => m.getResult() == '무').length;
    final losses = recentMatches.where((m) => m.getResult() == '패').length;
    final totalGoals = recentMatches.fold(0, (sum, m) => sum + m.ourScore);
    final totalConceded = recentMatches.fold(0, (sum, m) => sum + m.opponentScore);

    final winRate = total == 0 ? 0 : (wins / total * 100).round();
    final drawRate = total == 0 ? 0 : (draws / total * 100).round();
    final lossRate = total == 0 ? 0 : (losses / total * 100).round();

    final avgGoals = total == 0 ? 0 : (totalGoals / total);
    final avgConceded = total == 0 ? 0 : (totalConceded / total);

    final recentResults = recentMatches.map((m) => m.getResult()).toList();

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('$total매치', style: AppTextStyles.displaySmall),
                const SizedBox(width: 8),
                ...recentResults.map((result) => _buildResultChip(result)).toList(),
              ],
            ),
            const SizedBox(height: 8),
            _buildResultBar(winRate, drawRate, lossRate),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('$wins승 $winRate%', style: TextStyle(color: AppColors.success)),
                const SizedBox(width: 8),
                Text('$draws무 $drawRate%', style: TextStyle(color: AppColors.warning)),
                const SizedBox(width: 8),
                Text('$losses패 $lossRate%', style: TextStyle(color: AppColors.error)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('합계 ', style: AppTextStyles.bodyMedium),
                Text('$totalGoals 득점', style: TextStyle(color: AppColors.primary)),
                Text('  $totalConceded 실점', style: TextStyle(color: AppColors.error)),
              ],
            ),
            Row(
              children: [
                Text('평균 ', style: AppTextStyles.bodyMedium),
                Text('${avgGoals.toStringAsFixed(1)} 득점', style: TextStyle(color: AppColors.primary)),
                Text('  ${avgConceded.toStringAsFixed(1)} 실점', style: TextStyle(color: AppColors.error)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultChip(String result) {
    Color color;
    String text;
    switch (result) {
      case '승':
        color = AppColors.success;
        text = '승';
        break;
      case '무':
        color = AppColors.warning;
        text = '무';
        break;
      case '패':
        color = AppColors.error;
        text = '패';
        break;
      default:
        color = AppColors.neutral;
        text = '?';
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildResultBar(int winRate, int drawRate, int lossRate) {
    return Row(
      children: [
        Expanded(
          flex: winRate,
          child: Container(height: 6, color: AppColors.success),
        ),
        Expanded(
          flex: drawRate,
          child: Container(height: 6, color: AppColors.warning),
        ),
        Expanded(
          flex: lossRate,
          child: Container(height: 6, color: AppColors.error),
        ),
      ],
    );
  }
} 
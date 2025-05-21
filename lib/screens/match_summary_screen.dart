import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/models/match.dart';
import 'package:myfc_app/models/team.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/widgets/common/app_button.dart';
import 'package:myfc_app/widgets/common/app_card.dart';
import 'package:myfc_app/widgets/match_card_item.dart';
import 'package:myfc_app/widgets/widgets.dart';

class MatchSummaryScreen extends StatefulWidget {
  const MatchSummaryScreen({Key? key}) : super(key: key);

  @override
  State<MatchSummaryScreen> createState() => _MatchSummaryScreenState();
}

class _MatchSummaryScreenState extends State<MatchSummaryScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  
  List<Match> _matches = [];
  bool _isLoading = true;
  Team? _team;
  
  @override
  void initState() {
    super.initState();
    _loadTeamAndMatches();
  }
  
  Future<void> _loadTeamAndMatches() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load team info
      await _loadTeamInfo();
      
      // Load matches
      await _loadMatches();
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '데이터를 불러오는 데 실패했습니다.',
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
  
  Future<void> _loadTeamInfo() async {
    try {
      // First check cache
      final cachedTeam = await _storageService.getCachedTeam();
      
      if (cachedTeam != null) {
        setState(() {
          _team = cachedTeam;
        });
      }
      
      // Then load from API
      final teamId = await _authService.getTeamId();
      final token = await _authService.getToken();
      
      if (teamId != null && token != null) {
        final team = await _apiService.getTeam(teamId, token);
        await _storageService.cacheTeam(team);
        
        if (mounted) {
          setState(() {
            _team = team;
          });
        }
      }
    } catch (e) {
      print('Error loading team info: $e');
    }
  }
  
  Future<void> _loadMatches() async {
    try {
      final cachedMatches = await _storageService.getCachedMatches();
      
      if (cachedMatches.isNotEmpty) {
        setState(() {
          _matches = cachedMatches;
        });
      }
      
      final teamId = await _authService.getTeamId();
      final token = await _authService.getToken();
      
      if (teamId != null) {
        final matches = await _apiService.getTeamMatches(teamId, token);
        
        await _storageService.cacheMatches(matches);
        
        if (mounted) {
          setState(() {
            _matches = matches;
          });
        }
      }
    } catch (e) {
      print('Error loading matches: $e');
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '경기 목록을 불러오는 데 실패했습니다.',
          isError: true,
        );
      }
    }
  }
  
  Future<void> _deleteMatch(Match match) async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      '경기 삭제',
      '${match.opponent}와의 경기를 삭제하시겠습니까?\n\n삭제 시 관련 득점, 도움, MOM 통계가 모두 업데이트됩니다.',
    );
    
    if (confirmed) {
      try {
        final token = await _authService.getToken();
        final result = await _apiService.deleteMatch(match.id, token);
        await _loadMatches();
        if (mounted) {
          Helpers.showSnackBar(context, result['message'] ?? '경기가 삭제되었습니다.');
        }
      } catch (e) {
        if (mounted) {
          Helpers.showSnackBar(
            context,
            '경기 삭제에 실패했습니다.',
            isError: true,
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final groupedMatches = Helpers.groupByMonth<Match>(
      _matches,
      (match) => DateFormat('yyyy-MM-dd').parse(match.date),
    );
    final sortedKeys = groupedMatches.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : _matches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sports_soccer,
                        size: 80,
                        color: AppColors.neutral,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '아직 등록된 경기가 없어요!',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.neutral,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: '매치 추가하기',
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.addMatchStep1,
                        ).then((_) => _loadTeamAndMatches()),
                      ),
                    ],
                  ),
                )
              : SizedBox.expand(
                  child: Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadTeamAndMatches,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: sortedKeys.length,
                            itemBuilder: (context, index) {
                              final monthKey = sortedKeys[index];
                              final monthMatches = groupedMatches[monthKey]!;
                              monthMatches.sort((a, b) => b.date.compareTo(a.date));
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Text(
                                      Helpers.getMonthHeader(monthMatches[0].date),
                                      style: AppTextStyles.displaySmall,
                                    ),
                                  ),
                                  ...monthMatches.map((match) => _buildMatchItem(match)).toList(),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: AppButton(
                          text: '매치 추가하기',
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.addMatchStep1,
                          ).then((_) => _loadTeamAndMatches()),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildMatchItem(Match match) {
    return MatchCardItem(
      match: match,
      teamName: _team?.name ?? 'FC UBUNTU',
      teamLogoUrl: _team?.logoUrl,
      onTap: () {
        Navigator.pushNamed(
          context,
          '/match_detail',
          arguments: match.id,
        );
      },
    );
  }

  Color _getResultColor(MatchResult result) {
    switch (result) {
      case MatchResult.win:
        return AppColors.success;
      case MatchResult.draw:
        return AppColors.warning;
      case MatchResult.lose:
        return AppColors.error;
    }
  }
} 
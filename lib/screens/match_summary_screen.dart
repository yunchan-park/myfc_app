import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/models/match.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/widgets/common/app_button.dart';
import 'package:myfc_app/widgets/common/app_card.dart';
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
  
  @override
  void initState() {
    super.initState();
    _loadMatches();
  }
  
  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final cachedMatches = await _storageService.getCachedMatches();
      
      if (cachedMatches.isNotEmpty) {
        setState(() {
          _matches = cachedMatches;
          _isLoading = false;
        });
      }
      
      final teamId = await _authService.getTeamId();
      final token = await _authService.getToken();
      
      if (teamId != null) {
        final matches = await _apiService.getTeamMatches(teamId, token);
        
        await _storageService.cacheMatches(matches);
        
        setState(() {
          _matches = matches;
        });
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '경기 목록을 불러오는 데 실패했습니다.',
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
                        ).then((_) => _loadMatches()),
                      ),
                    ],
                  ),
                )
              : SizedBox.expand(
                  child: Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadMatches,
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
                          ).then((_) => _loadMatches()),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildMatchItem(Match match) {
    final result = match.getResultEnum();
    String onlyDate = match.date.contains('T') ? match.date.split('T').first : match.date;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/match_detail',
            arguments: match.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    onlyDate,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.neutral,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getResultColor(result).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      match.getResult(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _getResultColor(result),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      match.opponent,
                      style: AppTextStyles.bodyLarge,
                    ),
                  ),
                  Text(
                    match.score,
                    style: AppTextStyles.displaySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
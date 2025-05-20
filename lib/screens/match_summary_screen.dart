import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/models/match.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/utils/helpers.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _matches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.sports_soccer,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '아직 등록된 경기가 없어요!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.addMatchStep1,
                        ).then((_) => _loadMatches()),
                        child: const Text('매치 추가하기'),
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
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ...monthMatches.map((match) => _buildMatchItem(match)).toList(),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.addMatchStep1,
                          ).then((_) => _loadMatches()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('매치 추가하기'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildMatchItem(Match match) {
    final result = match.getResultEnum();
    
    return MatchCard(
      id: match.id,
      date: match.date,
      opponent: match.opponent,
      score: match.score,
      result: result,
      onTap: () {
        Navigator.pushNamed(
          context,
          '/match_detail',
          arguments: match.id,
        );
      },
      onDelete: () => _deleteMatch(match),
    );
  }
} 
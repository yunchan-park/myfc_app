import 'package:flutter/material.dart';
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
      // Try to get data from cache first
      final cachedMatches = await _storageService.getCachedMatches();
      
      if (cachedMatches.isNotEmpty) {
        setState(() {
          _matches = cachedMatches;
          _isLoading = false;
        });
      }
      
      // Load from API
      final teamId = await _authService.getTeamId();
      final token = await _authService.getToken();
      
      if (teamId != null) {
        final matches = await _apiService.getTeamMatches(teamId, token);
        
        // Update cache
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
      '${match.opponent}와의 경기를 삭제하시겠습니까?',
    );
    
    if (confirmed) {
      try {
        final token = await _authService.getToken();
        await _apiService.deleteMatch(match.id, token);
        await _loadMatches(); // Reload matches
        if (mounted) {
          Helpers.showSnackBar(context, '경기가 삭제되었습니다.');
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_matches.isEmpty) {
      return Center(
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
      );
    }
    
    // Group matches by month
    final groupedMatches = Helpers.groupByMonth<Match>(
      _matches,
      (match) => match.date,
    );
    
    // Sort keys in descending order (newest first)
    final sortedKeys = groupedMatches.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return SizedBox.expand(
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
                  
                  // Sort matches by date (newest first)
                  monthMatches.sort((a, b) => b.date.compareTo(a.date));
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month header
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
                      
                      // Match list for this month
                      ...monthMatches.map((match) => _buildMatchItem(match)).toList(),
                    ],
                  );
                },
              ),
            ),
          ),
          
          // Add match button
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
    );
  }
  
  Widget _buildMatchItem(Match match) {
    final result = match.getResultEnum();
    
    return MatchCard(
      opponent: match.opponent,
      date: match.date,
      ourScore: match.ourScore,
      opponentScore: match.opponentScore,
      result: result,
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.matchDetail,
        arguments: match.id,
      ),
      onEditTap: () {
        // TODO: Implement edit match
        Helpers.showSnackBar(context, '경기 수정 기능 준비 중입니다.');
      },
      onDeleteTap: () => _deleteMatch(match),
    );
  }
} 
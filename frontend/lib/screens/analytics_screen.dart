import 'package:flutter/material.dart';
import 'package:myfc_app/models/analytics.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/widgets/analytics/analytics_overview_widget.dart';
import 'package:myfc_app/widgets/analytics/goals_analysis_widget.dart';
import 'package:myfc_app/widgets/analytics/conceded_analysis_widget.dart';
import 'package:myfc_app/widgets/analytics/player_contributions_widget.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  // Data models
  TeamAnalyticsOverview? _overview;
  GoalsWinCorrelation? _goalsWinCorrelation;
  ConcededLossCorrelation? _concededLossCorrelation;
  PlayerContributionsResponse? _playerContributions;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _authService.getToken();
      final teamId = await _authService.getTeamId();

      if (token == null || teamId == null) {
        throw Exception('인증 정보가 없습니다.');
      }

      // 모든 분석 데이터를 병렬로 로드
      final results = await Future.wait([
        _apiService.getTeamAnalyticsOverview(teamId, token),
        _apiService.getGoalsWinCorrelation(teamId, token),
        _apiService.getConcededLossCorrelation(teamId, token),
        _apiService.getPlayerContributions(teamId, token),
      ]);

      setState(() {
        _overview = results[0] as TeamAnalyticsOverview;
        _goalsWinCorrelation = results[1] as GoalsWinCorrelation;
        _concededLossCorrelation = results[2] as ConcededLossCorrelation;
        _playerContributions = results[3] as PlayerContributionsResponse;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.darkGray,
        elevation: 0,
        bottom: _isLoading || _error != null
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppTextStyles.bodyMedium,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.neutral,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: '전체 통계'),
                  Tab(text: '득점 분석'),
                  Tab(text: '실점 분석'),
                  Tab(text: '선수 기여도'),
                ],
              ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
            color: AppColors.white,
            child: Text(
              '팀 분석',
              style: AppTextStyles.displayLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildGoalsAnalysisTab(),
        _buildConcededAnalysisTab(),
        _buildPlayerContributionsTab(),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              '데이터를 불러올 수 없습니다',
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadAnalyticsData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('다시 시도'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_overview == null) return const SizedBox.shrink();
    return AnalyticsOverviewWidget(overview: _overview!);
  }

  Widget _buildGoalsAnalysisTab() {
    if (_goalsWinCorrelation == null) return const SizedBox.shrink();
    return GoalsAnalysisWidget(goalsWinCorrelation: _goalsWinCorrelation!);
  }

  Widget _buildConcededAnalysisTab() {
    if (_concededLossCorrelation == null) return const SizedBox.shrink();
    return ConcededAnalysisWidget(concededLossCorrelation: _concededLossCorrelation!);
  }

  Widget _buildPlayerContributionsTab() {
    if (_playerContributions == null) return const SizedBox.shrink();
    return PlayerContributionsWidget(playerContributions: _playerContributions!);
  }
} 
import 'package:flutter/material.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/models/team.dart';
import 'package:myfc_app/screens/team_profile_screen.dart';
import 'package:myfc_app/screens/player_management_screen.dart';
import 'package:myfc_app/screens/match_summary_screen.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/widgets/common/app_button.dart';

final GlobalKey<PlayerManagementScreenState> playerManagementScreenKey =
    GlobalKey<PlayerManagementScreenState>();

final GlobalKey<TeamProfileScreenState> teamProfileScreenKey =
    GlobalKey<TeamProfileScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  final List<String> _titles = [
    '구단 프로필',
    '선수 관리',
    '매치 기록'
  ];
  
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          '로그아웃',
          style: AppTextStyles.displaySmall,
        ),
        content: Text(
          '정말 로그아웃 하시겠습니까?',
          style: AppTextStyles.bodyLarge,
        ),
        actions: [
          TextButton(
            child: Text(
              '취소',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral),
            ),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text(
              '로그아웃',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.splash);
      }
    }
  }
  
  void _showAddPlayerModal() {
    if (playerManagementScreenKey.currentState != null) {
      playerManagementScreenKey.currentState!.showAddPlayerModal();
    }
  }

  Future<void> _navigateToEditTeam() async {
    try {
      setState(() {
        _isLoading = true;
      });

      Team? team = await _storageService.getCachedTeam();
      
      if (team == null) {
        final teamId = await _authService.getTeamId();
        final token = await _authService.getToken();
        
        if (teamId != null && token != null) {
          team = await _apiService.getTeam(teamId, token);
          await _storageService.cacheTeam(team);
        }
      }
      
      if (team != null && mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.editTeam,
          arguments: team,
        );
      } else {
        Helpers.showSnackBar(
          context,
          '구단 정보를 가져올 수 없습니다.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '구단 정보를 가져오는 중 오류가 발생했습니다.',
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
  
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _titles[_currentIndex],
          style: AppTextStyles.displayMedium,
        ),
        actions: [_buildTrailingButton(_currentIndex)],
      ),
      body: Stack(
        children: [
          _buildTabContent(_currentIndex),
          if (_isLoading)
            Container(
              color: AppColors.darkGray.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.neutral,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '구단',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '선수',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: '매치',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
  
  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return TeamProfileScreen(key: teamProfileScreenKey);
      case 1:
        return PlayerManagementScreen(key: playerManagementScreenKey);
      case 2:
        return const MatchSummaryScreen();
      default:
        return TeamProfileScreen(key: teamProfileScreenKey);
    }
  }
  
  Widget _buildTrailingButton(int index) {
    switch (index) {
      case 0:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              color: AppColors.primary,
              onPressed: _navigateToEditTeam,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              color: AppColors.neutral,
              onPressed: _logout,
            ),
          ],
        );
      case 1:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              color: AppColors.primary,
              onPressed: _showAddPlayerModal,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              color: AppColors.neutral,
              onPressed: _logout,
            ),
          ],
        );
      case 2:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              color: AppColors.primary,
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.addMatchStep1,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              color: AppColors.neutral,
              onPressed: _logout,
            ),
          ],
        );
      default:
        return IconButton(
          icon: const Icon(Icons.logout),
          color: AppColors.neutral,
          onPressed: _logout,
        );
    }
  }
}
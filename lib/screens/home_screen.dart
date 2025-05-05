import 'package:flutter/material.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/screens/team_profile_screen.dart';
import 'package:myfc_app/screens/player_management_screen.dart';
import 'package:myfc_app/screens/match_summary_screen.dart';
import 'package:myfc_app/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  
  final List<String> _titles = [
    '구단 프로필',
    '선수 관리',
    '매치 기록'
  ];
  
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('로그아웃'),
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
  
  PreferredSizeWidget _buildAppBar() {
    switch (_currentIndex) {
      case 0: // 구단 프로필
        return AppBar(
          title: Text(_titles[_currentIndex]),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.editTeam,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _logout,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: Colors.grey[300],
              height: 1,
            ),
          ),
        );
      case 1: // 선수 관리
        return AppBar(
          title: Text(_titles[_currentIndex]),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _logout,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: Colors.grey[300],
              height: 1,
            ),
          ),
        );
      case 2: // 매치 기록
        return AppBar(
          title: Text(_titles[_currentIndex]),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.addMatchStep1,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _logout,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: Colors.grey[300],
              height: 1,
            ),
          ),
        );
      default:
        return AppBar(
          title: Text(_titles[_currentIndex]),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _logout,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: Colors.grey[300],
              height: 1,
            ),
          ),
        );
    }
  }
  
  void _showAddPlayerModal() {
    // GlobalKey를 통해 PlayerManagementScreen의 메서드에 접근
    if (playerManagementScreenKey.currentState != null) {
      print('HomeScreen: 선수 추가 모달 호출');
      playerManagementScreenKey.currentState!.showAddPlayerModal();
    } else {
      print('HomeScreen: playerManagementScreenKey.currentState가 null입니다');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _currentIndex == 0
          ? const TeamProfileScreen()
          : _currentIndex == 1
              ? SizedBox.expand(
                  child: Container(
                    color: Colors.white,
                    child: PlayerManagementScreen(key: playerManagementScreenKey),
                  ),
                )
              : const MatchSummaryScreen(),
      // 선수 관리 탭일 때만 FloatingActionButton 표시
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: _showAddPlayerModal,
              backgroundColor: Colors.black,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/widgets/widgets.dart';

class AddMatchStep2Screen extends StatefulWidget {
  final DateTime date;
  final String opponent;
  final int quarters;
  
  const AddMatchStep2Screen({
    Key? key,
    required this.date,
    required this.opponent,
    required this.quarters,
  }) : super(key: key);

  @override
  State<AddMatchStep2Screen> createState() => _AddMatchStep2ScreenState();
}

class _AddMatchStep2ScreenState extends State<AddMatchStep2Screen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  
  List<Player> _players = [];
  Set<int> _selectedPlayerIds = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }
  
  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final teamId = await _authService.getTeamId();
      final token = await _authService.getToken();
      
      if (teamId != null) {
        final players = await _apiService.getTeamPlayers(teamId, token);
        
        if (mounted) {
          setState(() {
            _players = players;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '선수 목록을 불러오는 데 실패했습니다.',
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
  
  void _togglePlayerSelection(Player player) {
    setState(() {
      if (_selectedPlayerIds.contains(player.id)) {
        _selectedPlayerIds.remove(player.id);
      } else {
        _selectedPlayerIds.add(player.id);
      }
    });
  }
  
  void _goToNextStep() {
    if (_selectedPlayerIds.isEmpty) {
      Helpers.showSnackBar(
        context,
        '경기에 참여한 선수를 최소 1명 이상 선택해주세요.',
        isError: true,
      );
      return;
    }
    
    Navigator.pushNamed(
      context,
      AppRoutes.addMatchStep3,
      arguments: {
        'date': widget.date,
        'opponent': widget.opponent,
        'quarters': widget.quarters,
        'playerIds': _selectedPlayerIds.toList(),
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매치 추가'),
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
          : _players.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Step indicator
                            _buildStepIndicator(),
                            const SizedBox(height: 32),
                            
                            // Selection info
                            Text(
                              '경기에 참여하는 팀원을 모두 선택해주세요',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Selected count
                            Text(
                              '${_selectedPlayerIds.length}명 선택됨',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Player grid
                            _buildPlayerGrid(),
                          ],
                        ),
                      ),
                    ),
                    
                    // Next button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: _goToNextStep,
                        child: const Text('다음 단계로'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '아직 선수들이 등록되지 않았어요!',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('돌아가기'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(1, false),
        _buildStepLine(),
        _buildStepCircle(2, true),
        _buildStepLine(),
        _buildStepCircle(3, false),
        _buildStepLine(),
        _buildStepCircle(4, false),
      ],
    );
  }
  
  Widget _buildStepCircle(int step, bool isActive) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.black : Colors.grey[300],
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
  
  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 2,
        color: Colors.grey[300],
      ),
    );
  }
  
  Widget _buildPlayerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: _players.length,
      itemBuilder: (context, index) {
        final player = _players[index];
        final isSelected = _selectedPlayerIds.contains(player.id);
        
        return PlayerCard(
          name: player.name,
          number: player.number,
          isSelected: isSelected,
          onTap: () => _togglePlayerSelection(player),
        );
      },
    );
  }
} 
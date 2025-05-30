import 'package:flutter/material.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/widgets/common/app_button.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '매치 등록',
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : _buildContent(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepDot(1, false, true),  // 완료된 단계
          _buildStepLine(true),
          _buildStepDot(2, true, false),  // 현재 단계
          _buildStepLine(false),
          _buildStepDot(3, false, false),
          _buildStepLine(false),
          _buildStepDot(4, false, false),
        ],
      ),
    );
  }
  
  Widget _buildStepDot(int step, bool isActive, bool isCompleted) {
    Color backgroundColor = AppColors.white;
    Color borderColor = AppColors.neutral;
    Color textColor = AppColors.neutral;
    Widget? child;
    
    if (isCompleted) {
      backgroundColor = AppColors.primary;
      borderColor = AppColors.primary;
      child = Icon(Icons.check, size: 16, color: AppColors.white);
    } else if (isActive) {
      backgroundColor = AppColors.primary;
      borderColor = AppColors.primary;
      textColor = AppColors.white;
      child = Text(
        step.toString(),
        style: AppTextStyles.bodyMedium.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      child = Text(
        step.toString(),
        style: AppTextStyles.bodyMedium.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
        shape: BoxShape.circle,
      ),
      child: Center(child: child),
    );
  }
  
  Widget _buildStepLine(bool isCompleted) {
    return Container(
      width: 32,
      height: 2,
      color: isCompleted ? AppColors.primary : AppColors.neutral,
    );
  }
  
  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildPlayerGrid(),
          ),
        ),
        _buildBottomButton(),
      ],
    );
  }
  
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: AppColors.white,
      child: Column(
        children: [
          Text(
            '경기에 참여하는 팀원을 모두 선택해주세요',
            style: AppTextStyles.displayMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '선택한 팀원: ${_selectedPlayerIds.length}명',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlayerGrid() {
    if (_players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: AppColors.neutral,
            ),
            const SizedBox(height: 16),
            Text(
              '등록된 선수가 없습니다.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.neutral,
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _players.length,
      itemBuilder: (context, index) {
        final player = _players[index];
        final isSelected = _selectedPlayerIds.contains(player.id);
        
        return _buildPlayerCard(player, isSelected);
      },
    );
  }
  
  Widget _buildPlayerCard(Player player, bool isSelected) {
    return InkWell(
      onTap: () => _togglePlayerSelection(player),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.neutral.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 선택 상태 표시
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.white,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.neutral,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.white,
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            
            // 등번호
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  player.number?.toString() ?? '?',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.darkGray,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // 선수 이름
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                player.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.darkGray,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.white,
      child: SafeArea(
        child: AppButton(
          onPressed: _selectedPlayerIds.isNotEmpty ? _goToNextStep : null,
          text: '다음 단계로 (${_selectedPlayerIds.length}명 선택)',
        ),
      ),
    );
  }
} 
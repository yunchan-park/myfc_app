import 'package:flutter/material.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/widgets/common/app_button.dart';
import 'package:myfc_app/widgets/common/app_card.dart';

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
          '매치 추가',
          style: AppTextStyles.displaySmall,
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    return Column(
      children: [
        _buildStepIndicator(),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPlayerSelection(),
                  const SizedBox(height: 24),
                  AppButton(
                    onPressed: _selectedPlayerIds.isEmpty ? null : _goToNextStep,
                    text: '다음',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStep(1, '기본 정보', true),
          _buildStep(2, '선수 선택', false),
          _buildStep(3, '점수 입력', true),
          _buildStep(4, '확인', true),
        ],
      ),
    );
  }
  
  Widget _buildStep(int step, String label, bool isCompleted) {
    final isCurrentStep = step == 2;
    final color = isCurrentStep ? AppColors.primary : AppColors.neutral;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCurrentStep ? AppColors.primary : AppColors.white,
            border: Border.all(
              color: color,
              width: 2,
            ),
            shape: BoxShape.circle,
          ),
          child: isCompleted
              ? Icon(
                  Icons.check,
                  size: 16,
                  color: isCurrentStep ? AppColors.white : color,
                )
              : Text(
                  step.toString(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isCurrentStep ? AppColors.white : color,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: color,
          ),
        ),
        if (step < 4) ...[
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 2,
            color: color,
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
  
  Widget _buildPlayerSelection() {
    if (_players.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 48,
                  color: AppColors.neutral.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  '등록된 선수가 없습니다',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.neutral,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '선수 관리 화면에서 선수를 추가해주세요',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선수 선택',
          style: AppTextStyles.displayLarge.copyWith(
            color: AppColors.neutral,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '매치에 참여할 선수를 선택해주세요',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutral.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _players.length,
          itemBuilder: (context, index) {
            final player = _players[index];
            final isSelected = _selectedPlayerIds.contains(player.id);

            return GestureDetector(
              onTap: () => _togglePlayerSelection(player),
              child: AppCard(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.1),
                        child: Text(
                          player.number.toString(),
                          style: AppTextStyles.displayMedium.copyWith(
                            color: isSelected ? AppColors.white : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        player.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.neutral,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
} 
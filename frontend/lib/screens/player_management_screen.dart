import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/widgets/common/app_button.dart';
import 'package:myfc_app/widgets/common/app_input.dart';
import 'package:myfc_app/widgets/common/app_card.dart';

class PlayerManagementScreen extends StatefulWidget {
  const PlayerManagementScreen({Key? key}) : super(key: key);

  @override
  PlayerManagementScreenState createState() => PlayerManagementScreenState();
}

class PlayerManagementScreenState extends State<PlayerManagementScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _positionController = TextEditingController();
  
  List<Player> _players = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  
  void showAddPlayerModal() {
    _showPlayerModal();
  }

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final teamId = await _authService.getTeamId();
      final token = await _authService.getToken();
      
      if (teamId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _players = [];
          });
        }
        return;
      }
      
      final players = await _apiService.getTeamPlayers(teamId, token);
      
      await _storageService.cachePlayers(players);
      
      players.sort((a, b) => a.number.compareTo(b.number));
      
      if (mounted) {
        setState(() {
          _players = List<Player>.from(players);
          _isLoading = false;
        });
      }
    } catch (e) {
      try {
        final cachedPlayers = await _storageService.getCachedPlayers();
        if (cachedPlayers.isNotEmpty && mounted) {
          cachedPlayers.sort((a, b) => a.number.compareTo(b.number));
          setState(() {
            _players = List<Player>.from(cachedPlayers);
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() {
            _players = [];
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _players = [];
            _isLoading = false;
          });
        }
      }
    }
  }
  
  void _showPlayerModal([Player? player]) {
    _nameController.text = player?.name ?? '';
    _numberController.text = player?.number.toString() ?? '';
    _positionController.text = player?.position ?? '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  player == null ? '선수 추가' : '선수 정보 수정',
                  style: AppTextStyles.displaySmall,
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppInput(
                        controller: _nameController,
                        hint: '이름',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '이름을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        controller: _numberController,
                        hint: '번호',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '번호를 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        controller: _positionController,
                        hint: '포지션 (GK, DF, MF, FW)',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '포지션을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: player == null ? '추가하기' : '수정하기',
                        onPressed: _isSubmitting ? null : () => _savePlayer(player),
                        isLoading: _isSubmitting,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _savePlayer(Player? player) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final teamId = await _authService.getTeamId();
      final token = await _authService.getToken();
      
      if (teamId != null) {
        if (player == null) {
          await _apiService.createPlayer(
            _nameController.text.trim(),
            int.parse(_numberController.text.trim()),
            _positionController.text.trim(),
            teamId,
            token,
          );
        } else {
          await _apiService.updatePlayer(
            player.id,
            {
              'name': _nameController.text.trim(),
              'number': int.parse(_numberController.text.trim()),
              'position': _positionController.text.trim(),
            },
            token,
          );
        }
        
        if (mounted) {
          Navigator.pop(context);
          
          await _loadPlayers();
          
          Helpers.showSnackBar(
            context, 
            player == null ? '선수가 등록되었습니다.' : '선수 정보가 수정되었습니다.'
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '선수 ${player == null ? '등록' : '수정'}에 실패했습니다. 다시 시도해주세요.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  Future<void> _deletePlayer(Player player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선수 삭제'),
        content: Text('${player.name} 선수를 정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final token = await _authService.getToken();
        await _apiService.deletePlayer(player.id, token);
        
        if (mounted) {
          await _loadPlayers();
          Helpers.showSnackBar(context, '선수가 삭제되었습니다.');
        }
      } catch (e) {
        if (mounted) {
          Helpers.showSnackBar(
            context,
            '선수 삭제에 실패했습니다. 다시 시도해주세요.',
            isError: true,
          );
        }
      }
    }
  }
  
  void _confirmDeletePlayer(Player player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선수 삭제'),
        content: Text('${player.name} 선수를 정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePlayer(player);
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: 48,
              color: AppColors.neutral,
            ),
            const SizedBox(height: 16),
            Text(
              '등록된 선수가 없습니다',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.neutral,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: '선수 추가하기',
              onPressed: _showPlayerModal,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _players.length,
      itemBuilder: (context, index) {
        final player = _players[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            onTap: () => _showPlayerModal(player),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      player.number.toString(),
                      style: AppTextStyles.displaySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: AppTextStyles.bodyLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          player.position,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.neutral,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        color: AppColors.primary,
                        tooltip: '수정',
                        onPressed: () => _showPlayerModal(player),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        color: Colors.red,
                        tooltip: '삭제',
                        onPressed: () => _confirmDeletePlayer(player),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/utils/helpers.dart';

// State 클래스를 외부에서 접근할 수 있도록 export
class PlayerManagementScreen extends StatefulWidget {
  const PlayerManagementScreen({Key? key}) : super(key: key);

  @override
  PlayerManagementScreenState createState() => PlayerManagementScreenState();
}

class PlayerManagementScreenState extends State<PlayerManagementScreen> {
  // 서비스 초기화
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  
  // 모달 관련 컨트롤러
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _positionController = TextEditingController();
  
  // 상태 변수
  List<Player> _players = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  
  // 홈 화면에서 플로팅 버튼 클릭 시 호출되는 메서드
  void showAddPlayerModal() {
    _showPlayerModal();
  }

  @override
  void initState() {
    super.initState();
    print('PlayerManagementScreen: initState 호출됨');
    
    // 데이터 로드 전에 로딩 상태 설정
    _isLoading = true;
    
    // 데이터 로드 시작
    _loadPlayers();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  // 선수 목록 로드 메서드
  Future<void> _loadPlayers() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 팀 ID 가져오기
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
      
      // API에서 선수 목록 가져오기
      final players = await _apiService.getTeamPlayers(teamId, token);
      
      // 캐시 업데이트
      await _storageService.cachePlayers(players);
      
      // 정렬 (번호 순)
      players.sort((a, b) => a.number.compareTo(b.number));
      
      if (mounted) {
        setState(() {
          _players = List<Player>.from(players); // 복사본 생성하여 안전하게 할당
          _isLoading = false;
        });
      }
    } catch (e) {
      // 캐시에서 데이터 로드 시도
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
  
  // 선수 등록/수정 모달 표시
  void _showPlayerModal([Player? player]) {
    print('showAddPlayerModal 호출됨');
    
    // 폼 컨트롤러 초기화
    _nameController.text = player?.name ?? '';
    _numberController.text = player?.number.toString() ?? '';
    _positionController.text = player?.position ?? '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        // 모달 내부 UI
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
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '이름',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '이름을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _numberController,
                        decoration: const InputDecoration(
                          labelText: '번호',
                          border: OutlineInputBorder(),
                        ),
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
                      TextFormField(
                        controller: _positionController,
                        decoration: const InputDecoration(
                          labelText: '포지션 (GK, DF, MF, FW)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '포지션을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _isSubmitting
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => _savePlayer(player),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(player == null ? '추가하기' : '수정하기'),
                              ),
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
  
  // 선수 등록/수정 처리
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
          // 신규 선수 등록
          await _apiService.createPlayer(
            _nameController.text.trim(),
            int.parse(_numberController.text.trim()),
            _positionController.text.trim(),
            teamId,
            token,
          );
        } else {
          // 선수 정보 수정
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
        
        // 모달 닫기
        if (mounted) {
          Navigator.pop(context);
          
          // 데이터 다시 로드
          await _loadPlayers();
          
          // 성공 메시지 표시
          Helpers.showSnackBar(
            context, 
            player == null ? '선수가 등록되었습니다.' : '선수 정보가 수정되었습니다.'
          );
        }
      }
    } catch (e) {
      print('선수 ${player == null ? "등록" : "수정"} 오류: $e');
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
  
  // 선수 삭제 처리
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
        print('선수 삭제 오류: $e');
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
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 로딩 및 에러 처리
                if (_isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_players.isEmpty)
                  Expanded(
                    child: _buildEmptyState(),
                  )
                else
                  Expanded(
                    child: _buildPlayerList(),
                  ),
              ],
            );
          }
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sports_soccer,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '등록된 선수가 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showPlayerModal(),
            icon: const Icon(Icons.add),
            label: const Text('선수 추가하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlayerList() {
    return Column(
      children: [
        // 테이블 헤더
        Container(
          height: 40,
          color: Colors.grey[200],
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: const [
              SizedBox(width: 50, child: Text('번호', style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 16),
              Expanded(child: Text('이름', style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 80, child: Text('포지션', style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 50, child: Text('골', style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 50, child: Text('도움', style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 80),
            ],
          ),
        ),
        
        // 선수 목록
        Expanded(
          child: ListView.builder(
            itemCount: _players.length,
            itemBuilder: (context, index) {
              final player = _players[index];
              return Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          player.number.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          player.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(player.position),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(player.goalCount.toString()),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(player.assistCount.toString()),
                      ),
                      SizedBox(
                        width: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showPlayerModal(player),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () => _confirmDeletePlayer(player),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 
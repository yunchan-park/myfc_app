import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/utils/validators.dart';

class PlayerListScreen extends StatefulWidget {
  const PlayerListScreen({Key? key}) : super(key: key);

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  // 서비스 초기화
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  
  // 선수 정보 관련 상태
  List<Player> _players = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // 모달용 컨트롤러와 상태 추가
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _positionController = TextEditingController();
  bool _isSubmitting = false;
  
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

  // 모달을 표시하는 메서드 추가
  void _showAddPlayerModal() {
    // 입력 필드 초기화
    _nameController.clear();
    _numberController.clear();
    _positionController.clear();
    
    // 현재 컨텍스트 저장
    final BuildContext currentContext = context;
    
    showModalBottomSheet(
      context: currentContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '선수 등록',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Player name input
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '선수 이름',
                    hintText: '선수 이름을 적어주세요',
                  ),
                  validator: Validators.validatePlayerName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                
                // Player number input
                TextFormField(
                  controller: _numberController,
                  decoration: const InputDecoration(
                    labelText: '등번호',
                    hintText: '등번호를 적어주세요',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: Validators.validatePlayerNumber,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                
                // Player position input
                TextFormField(
                  controller: _positionController,
                  decoration: const InputDecoration(
                    labelText: '포지션',
                    hintText: '포지션을 적어주세요 (예: FW, MF, DF, GK)',
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _registerPlayer(),
                ),
                const SizedBox(height: 24),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _registerPlayer,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('선수 등록하기'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 선수 등록 처리 메서드 추가
  Future<void> _registerPlayer() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    final BuildContext currentContext = context; // 비동기 갭 전에 BuildContext 저장
    
    try {
      final teamId = await _authService.getTeamId();
      final token = await _authService.getToken();
      
      if (teamId != null) {
        // 신규 선수 등록
        await _apiService.createPlayer(
          _nameController.text.trim(),
          int.parse(_numberController.text.trim()),
          _positionController.text.trim(),
          teamId,
          token,
        );
        
        // 모달 닫기
        if (mounted) {
          Navigator.pop(currentContext);
          
          // 즉시 데이터 다시 로드
          setState(() {
            _isLoading = true;
          });
          
          await _loadPlayers();
          
          // 성공 메시지 표시
          Helpers.showSnackBar(
            currentContext, 
            '선수가 등록되었습니다.'
          );
        }
      }
    } catch (e) {
      assert(false, "선수 등록 오류: $e");
      if (mounted) {
        Helpers.showSnackBar(
          currentContext,
          '선수 등록에 실패했습니다. 다시 시도해주세요.',
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

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // 먼저 캐시된 플레이어 데이터 확인
      final cachedPlayers = await _storageService.getCachedPlayers();
      if (cachedPlayers.isNotEmpty) {
        setState(() {
          _players = cachedPlayers;
        });
      }
      
      final teamId = await _authService.getTeamId();
      final token = await _authService.getToken();
      
      if (teamId != null) {
        final players = await _apiService.getTeamPlayers(teamId, token);
        
        // 새로 가져온 데이터 캐싱
        await _storageService.cachePlayers(players);
        
        setState(() {
          _players = players;
        });
      } else {
        setState(() {
          _errorMessage = '팀 정보를 찾을 수 없습니다.';
          if (_players.isEmpty) {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '데이터를 불러오는데 실패했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '오류가 발생했습니다.',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPlayers,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList() {
    // Sort players by number
    _players.sort((a, b) => a.number.compareTo(b.number));
    
    return RefreshIndicator(
      onRefresh: _loadPlayers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _players.length,
        itemBuilder: (context, index) {
          final player = _players[index];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: Text(
                  '${player.number}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              title: Text(player.name),
              subtitle: Text(
                '${player.position} · 득점: ${player.goalCount} · 도움: ${player.assistCount}',
              ),
              onTap: () {
                // 선수 상세 정보 페이지로 이동 기능 추가 가능
              },
            ),
          );
        },
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
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: _showAddPlayerModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('선수 등록하기'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('선수 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddPlayerModal,
            tooltip: '선수 등록',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _players.isEmpty
                  ? _buildEmptyState()
                  : _buildPlayerList(),
    );
  }
} 
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/models/team.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/utils/helpers.dart';

class TeamProfileScreen extends StatefulWidget {
  const TeamProfileScreen({Key? key}) : super(key: key);

  @override
  State<TeamProfileScreen> createState() => TeamProfileScreenState();
}

class TeamProfileScreenState extends State<TeamProfileScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  Team? _team;
  List<Player> _players = [];
  bool _isLoading = true;
  bool _isImageLoading = false;
  bool _hasError = false;
  
  // 외부에서 접근 가능한 메서드들
  Team? get team => _team;
  List<Player> get players => _players;
  
  @override
  void initState() {
    super.initState();
    _loadTeam();
  }
  
  Future<void> _loadTeam() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      // Try to get data from cache first
      final cachedTeam = await _storageService.getCachedTeam();
      final cachedPlayers = await _storageService.getCachedPlayers();
      
      if (cachedTeam != null) {
        setState(() {
          _team = cachedTeam;
        });
      }
      
      if (cachedPlayers.isNotEmpty) {
        setState(() {
          _players = cachedPlayers;
        });
      }
      
      // Load from API
      final teamId = await _authService.getTeamId();
      final token = await _authService.getToken();
      
      if (teamId != null && token != null) {
        try {
          final team = await _apiService.getTeam(teamId, token);
          final players = await _apiService.getTeamPlayers(teamId, token);
          
          // Update cache
          _storageService.cacheTeam(team);
          _storageService.cachePlayers(players);
          
          if (mounted) {
            setState(() {
              _team = team;
              _players = players;
              _isLoading = false;
            });
          }
        } catch (e) {
          print('Error loading team profile: $e');
          if (mounted) {
            Helpers.showSnackBar(
              context,
              '데이터를 불러오는 데 실패했습니다.',
              isError: true,
            );
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '데이터를 불러오는 데 실패했습니다.',
          isError: true,
        );
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }
  
  // 외부에서 Team 데이터를 강제로 다시 로드하는 메서드
  Future<void> refreshTeamData() async {
    await _loadTeam();
  }
  
  // 외부에서 접근 가능한 Team 데이터 가져오기 메서드
  Future<Team?> getTeam() async {
    if (_team == null) {
      await _loadTeam();
    }
    return _team;
  }
  
  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null && _team != null) {
      setState(() {
        _isImageLoading = true;
      });
      
      try {
        final token = await _authService.getToken();
        final imageFile = File(pickedFile.path);
        await _apiService.uploadTeamImage(_team!.id, imageFile, token);
        await _loadTeam(); // Reload team to get new image URL
      } catch (e) {
        if (mounted) {
          Helpers.showSnackBar(
            context,
            '이미지 업로드에 실패했습니다.',
            isError: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isImageLoading = false;
          });
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
    
    if (_team == null || _hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('구단 정보를 불러올 수 없습니다.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTeam,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    
    return SizedBox.expand(
      child: CustomScrollView(
        slivers: [
          // Team header
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Background image
                  Positioned.fill(
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        image: _team!.imageUrl != null
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(
                                  ApiService.baseUrl + _team!.imageUrl!,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _isImageLoading
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  
                  // Edit button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.editTeam,
                        arguments: _team,
                      ),
                      icon: const Icon(Icons.edit),
                      label: const Text('정보 수정'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.7),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  // Team info overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                              image: _team!.logoUrl != null
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        ApiService.baseUrl + _team!.logoUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _team!.logoUrl == null
                                ? const Icon(
                                    Icons.sports_soccer,
                                    size: 40,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          
                          // Team name
                          Text(
                            _team!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          
                          // Team description
                          Text(
                            _team!.description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Gallery section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '갤러리',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('사진 추가'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: DottedBorder(
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(12),
                      color: Colors.grey,
                      strokeWidth: 1,
                      dashPattern: const [6, 3],
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: _team!.imageUrl != null
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(
                                    ApiService.baseUrl + _team!.imageUrl!,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _team!.imageUrl == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '구단의 추억사진을 공유해주세요',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Players section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '선수단',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.registerPlayer,
                        ),
                        icon: const Icon(Icons.person_add),
                        label: const Text('선수 등록'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Player list
                  _players.isEmpty
                      ? Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                              const Icon(
                                Icons.people,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '아직 등록된 선수가 없습니다',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.registerPlayer,
                                ),
                                child: const Text('선수 등록하기'),
                              ),
                            ],
                          ),
                        )
                      : _buildPlayerTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlayerTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      height: 300, // 명확한 높이 지정
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 32, // 화면 너비에서 패딩 제외한 크기
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('순위')),
                DataColumn(label: Text('이름')),
                DataColumn(label: Text('번호')),
                DataColumn(label: Text('MOM')),
                DataColumn(label: Text('도움')),
                DataColumn(label: Text('득점')),
              ],
              rows: _players.asMap().entries.map((entry) {
                final index = entry.key;
                final player = entry.value;
                return DataRow(
                  color: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      return index % 2 == 0
                          ? Colors.white
                          : Colors.grey[100]!;
                    },
                  ),
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(player.name)),
                    DataCell(Text('${player.number}')),
                    DataCell(Text('${player.momCount}')),
                    DataCell(Text('${player.assistCount}')),
                    DataCell(Text('${player.goalCount}')),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
} 
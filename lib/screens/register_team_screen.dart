import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/utils/validators.dart';
import 'package:myfc_app/utils/helpers.dart';

class RegisterTeamScreen extends StatefulWidget {
  const RegisterTeamScreen({Key? key}) : super(key: key);

  @override
  State<RegisterTeamScreen> createState() => _RegisterTeamScreenState();
}

class _RegisterTeamScreenState extends State<RegisterTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();
  
  String _selectedType = '축구'; // Default type
  File? _logoFile;
  File? _imageFile;
  bool _isLoading = false;
  
  Future<void> _pickLogo() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _registerTeam() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create team
      final team = await _apiService.createTeam(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
        _selectedType,
        _passwordController.text.trim(),
      );
      
      // Login with the newly created team
      final loginResponse = await _apiService.loginTeam(
        _nameController.text.trim(),
        _passwordController.text.trim(),
      );
      
      final token = loginResponse['access_token'] as String;
      int teamId = team.id; // 생성된 팀 객체에서 ID 사용
      
      // API에서 반환된 team_id가 있다면 그것을 사용
      if (loginResponse.containsKey('team_id')) {
        teamId = loginResponse['team_id'] as int;
      }
      
      await _authService.saveAuthData(token, teamId);
      
      // Upload logo if selected
      if (_logoFile != null) {
        await _apiService.uploadTeamLogo(teamId, _logoFile!);
      }
      
      // Upload image if selected
      if (_imageFile != null) {
        await _apiService.uploadTeamImage(teamId, _imageFile!);
      }
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '구단 등록에 실패했습니다. 다시 시도해주세요.',
          isError: true,
        );
        print('Registration error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('구단 등록'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[300],
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '구단의 기본정보를 입력해주세요',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickLogo,
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: _logoFile != null
                                  ? FileImage(_logoFile!)
                                  : null,
                              child: _logoFile == null
                                  ? const Icon(
                                      Icons.sports_soccer,
                                      size: 40,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Team type selection
                const Text(
                  '구단 유형',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTypeButton('축구'),
                    const SizedBox(width: 8),
                    _buildTypeButton('풋살'),
                    const SizedBox(width: 8),
                    _buildTypeButton('축구/풋살'),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Team name input
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '구단 이름',
                    hintText: '구단 이름을 입력해주세요 (최대 10자)',
                  ),
                  validator: Validators.validateTeamName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                
                // Team description input
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: '구단 소개글',
                    hintText: '구단 소개글을 작성해주세요 (최대 20자)',
                  ),
                  validator: Validators.validateTeamDescription,
                  textInputAction: TextInputAction.next,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                
                // Password input
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    hintText: '구단의 비밀번호를 입력해주세요',
                  ),
                  obscureText: true,
                  validator: Validators.validatePassword,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 32),
                
                // Team image upload
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
                        image: _imageFile != null
                            ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _imageFile == null
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
                const SizedBox(height: 32),
                
                // Register button
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerTeam,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('구단 등록하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTypeButton(String type) {
    final isSelected = _selectedType == type;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 
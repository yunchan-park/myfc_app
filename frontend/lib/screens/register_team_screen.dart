import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/utils/validators.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/widgets/common/app_button.dart';
import 'package:myfc_app/widgets/common/app_input.dart';

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
      
      final accessToken = loginResponse['access_token'] as String;
      int teamId = team.id;
      
      // TeamID를 문자열로 변환
      final teamIdStr = teamId.toString();
      await _authService.saveAuthData(accessToken, teamIdStr);
      
      // Upload logo if selected
      if (_logoFile != null) {
        await _apiService.uploadTeamLogo(teamId, _logoFile!, accessToken);
      }
      
      // Upload image if selected
      if (_imageFile != null) {
        await _apiService.uploadTeamImage(teamId, _imageFile!, accessToken);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '구단 등록',
          style: AppTextStyles.displaySmall,
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
                    Text(
                      '구단의 기본정보를 입력해주세요',
                      style: AppTextStyles.bodyLarge,
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
                              backgroundColor: AppColors.neutral.withOpacity(0.1),
                              backgroundImage: _logoFile != null
                                  ? FileImage(_logoFile!)
                                  : null,
                              child: _logoFile == null
                                  ? Icon(
                                      Icons.sports_soccer,
                                      size: 40,
                                      color: AppColors.neutral,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.neutral.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: AppColors.primary,
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
                Text(
                  '구단 유형',
                  style: AppTextStyles.bodyLarge,
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
                AppInput(
                  controller: _nameController,
                  hint: '구단 이름을 입력해주세요 (최대 10자)',
                  validator: Validators.validateTeamName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                
                // Team description input
                AppInput(
                  controller: _descriptionController,
                  hint: '구단 소개를 입력해주세요',
                  maxLines: 3,
                  validator: Validators.validateTeamDescription,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                
                // Password input
                AppInput(
                  controller: _passwordController,
                  hint: '구단 비밀번호를 입력해주세요',
                  obscureText: true,
                  validator: Validators.validatePassword,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 32),
                
                // Register button
                AppButton(
                  text: '구단 등록하기',
                  onPressed: _isLoading ? null : _registerTeam,
                  isLoading: _isLoading,
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
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.neutral.withOpacity(0.2),
            ),
          ),
          child: Center(
            child: Text(
              type,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.white : AppColors.neutral,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 
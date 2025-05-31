import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/models/team.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/utils/validators.dart';
import 'package:myfc_app/utils/helpers.dart';
import 'package:myfc_app/widgets/common/app_button.dart';
import 'package:myfc_app/widgets/common/app_input.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EditTeamScreen extends StatefulWidget {
  final Team team;
  
  const EditTeamScreen({Key? key, required this.team}) : super(key: key);

  @override
  State<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends State<EditTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _passwordController;
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  
  String _selectedType = '축구';
  File? _logoFile;
  File? _imageFile;
  bool _isLoading = false;
  bool _isPasswordChanged = false;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.team.name);
    _descriptionController = TextEditingController(text: widget.team.description);
    _passwordController = TextEditingController();
    _selectedType = widget.team.type;
  }
  
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
  
  Future<void> _updateTeam() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create update data
      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
      };
      
      // Add password if changed
      if (_isPasswordChanged) {
        updateData['password'] = _passwordController.text.trim();
      }
      
      // Get token for API calls
      final token = await _getToken();
      
      // Update team
      await _apiService.updateTeam(widget.team.id, updateData, token);
      
      // Upload logo if selected
      if (_logoFile != null) {
        await _apiService.uploadTeamLogo(widget.team.id, _logoFile!, token);
      }
      
      // Upload image if selected
      if (_imageFile != null) {
        await _apiService.uploadTeamImage(widget.team.id, _imageFile!, token);
      }
      
      if (mounted) {
        Helpers.showSnackBar(context, '구단 정보가 수정되었습니다.');
        // Pop back to profile screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          '구단 정보 수정에 실패했습니다. 다시 시도해주세요.',
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
  
  // Get token from secure storage
  Future<String?> _getToken() async {
    try {
      const storage = FlutterSecureStorage();
      return await storage.read(key: 'auth_token');
    } catch (e) {
      return null;
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
          '구단 정보 수정',
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
                // Logo section
                Center(
                  child: GestureDetector(
                    onTap: _pickLogo,
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.neutral.withOpacity(0.1),
                            backgroundImage: _logoFile != null
                                ? FileImage(_logoFile!)
                                : widget.team.logoUrl != null
                                    ? CachedNetworkImageProvider(
                                        ApiService.baseUrl + widget.team.logoUrl!,
                                      ) as ImageProvider
                                    : null,
                            child: (_logoFile == null && widget.team.logoUrl == null)
                                ? Icon(
                                    Icons.sports_soccer,
                                    size: 60,
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
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                
                // Password input
                AppInput(
                  controller: _passwordController,
                  hint: '새 비밀번호 (변경하지 않으려면 비워두세요)',
                  obscureText: true,
                  onChanged: (value) {
                    setState(() {
                      _isPasswordChanged = value.isNotEmpty;
                    });
                  },
                ),
                const SizedBox(height: 32),
                
                // Update button
                AppButton(
                  text: '구단 정보 수정하기',
                  onPressed: _isLoading ? null : _updateTeam,
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
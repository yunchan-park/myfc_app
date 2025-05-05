import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myfc_app/models/team.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/utils/validators.dart';
import 'package:myfc_app/utils/helpers.dart';

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
      
      // Update team
      await _apiService.updateTeam(widget.team.id, updateData);
      
      // Upload logo if selected
      if (_logoFile != null) {
        await _apiService.uploadTeamLogo(widget.team.id, _logoFile!);
      }
      
      // Upload image if selected
      if (_imageFile != null) {
        await _apiService.uploadTeamImage(widget.team.id, _imageFile!);
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
        title: const Text('구단 정보 수정'),
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
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _logoFile != null
                                ? FileImage(_logoFile!)
                                : widget.team.logoUrl != null
                                    ? CachedNetworkImageProvider(
                                        ApiService.baseUrl + widget.team.logoUrl!,
                                      ) as ImageProvider
                                    : null,
                            child: (_logoFile == null && widget.team.logoUrl == null)
                                ? const Icon(
                                    Icons.sports_soccer,
                                    size: 60,
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
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    hintText: '변경할 비밀번호를 입력해주세요',
                    helperText: '변경할 경우에만 입력하세요',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _passwordController.clear(),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null; // Password is optional when editing
                    }
                    return Validators.validatePassword(value);
                  },
                  textInputAction: TextInputAction.done,
                  onChanged: (value) {
                    setState(() {
                      _isPasswordChanged = value.isNotEmpty;
                    });
                  },
                ),
                const SizedBox(height: 32),
                
                // Team image section
                const Text(
                  '구단 대표 이미지',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : widget.team.imageUrl != null
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(
                                    ApiService.baseUrl + widget.team.imageUrl!,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: (_imageFile == null && widget.team.imageUrl == null)
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
                                '구단의 추억사진을 업로드해주세요',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Update button
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateTeam,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('정보 수정하기'),
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
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/models/team.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/auth_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/utils/helpers.dart';

class TeamHeaderWidget extends StatefulWidget {
  final Team team;
  final VoidCallback? onTeamUpdated;

  const TeamHeaderWidget({
    super.key,
    required this.team,
    this.onTeamUpdated,
  });

  @override
  State<TeamHeaderWidget> createState() => _TeamHeaderWidgetState();
}

class _TeamHeaderWidgetState extends State<TeamHeaderWidget> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isImageLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _navigateToEditTeam(),
                    icon: const Icon(
                      Icons.edit,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTeamLogo(),
              const SizedBox(height: 16),
              Text(
                widget.team.name,
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.white,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.team.type,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white.withOpacity(0.8),
                ),
              ),
              if (widget.team.founded != null) ...[
                const SizedBox(height: 4),
                Text(
                  '창단 ${widget.team.founded}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamLogo() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isImageLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : ClipOval(
                    child: widget.team.logoUrl != null && widget.team.logoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.team.logoUrl!,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                            placeholder: (context, url) => Container(
                              color: AppColors.lightGray,
                              child: const Icon(
                                Icons.sports_soccer,
                                size: 40,
                                color: AppColors.neutral,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.lightGray,
                              child: const Icon(
                                Icons.sports_soccer,
                                size: 40,
                                color: AppColors.neutral,
                              ),
                            ),
                          )
                        : DottedBorder(
                            borderType: BorderType.Circle,
                            color: AppColors.neutral,
                            strokeWidth: 2,
                            dashPattern: const [8, 4],
                            child: Container(
                              width: 116,
                              height: 116,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.lightGray,
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 24,
                                      color: AppColors.neutral,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '로고 추가',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.neutral,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
          ),
          if (!_isImageLoading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: AppColors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _isImageLoading = true;
        });

        final token = await _authService.getToken();
        if (token != null) {
          final url = await _storageService.uploadTeamLogo(
            File(image.path),
            widget.team.id,
          );

          await _apiService.updateTeamLogo(widget.team.id, url, token);

          if (mounted) {
            Helpers.showSnackBar(
              context,
              '팀 로고가 성공적으로 업데이트되었습니다.',
            );
            widget.onTeamUpdated?.call();
          }
        }
      }
    } catch (e) {
      print('Image upload error: $e');
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

  void _navigateToEditTeam() {
    Navigator.pushNamed(
      context,
      '/edit-team',
      arguments: widget.team,
    ).then((result) {
      if (result == true) {
        widget.onTeamUpdated?.call();
      }
    });
  }
} 
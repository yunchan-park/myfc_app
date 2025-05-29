import 'package:flutter/material.dart';
import 'package:myfc_app/config/theme.dart';

class PlayerCard extends StatelessWidget {
  final String name;
  final int number;
  final bool isSelected;
  final bool isSelectable;
  final VoidCallback? onTap;

  const PlayerCard({
    Key? key,
    required this.name,
    required this.number,
    this.isSelected = false,
    this.isSelectable = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelectable ? onTap : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 100,
          minHeight: 120,
          maxWidth: 100,
          maxHeight: 120,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primary 
                      : AppColors.lightGray,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number.toString(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected 
                          ? AppColors.white 
                          : AppColors.darkGray,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected 
                      ? AppColors.primary 
                      : AppColors.darkGray,
                  fontWeight: isSelected 
                      ? FontWeight.w600 
                      : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
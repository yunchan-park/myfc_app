import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfc_app/config/theme.dart';

class Helpers {
  // Format date to YYYY-MM-DD
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Format date to user-friendly format (YYYY년 MM월 DD일)
  static String formatDateKorean(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일').format(date);
  }

  // Format date to month and day only (MM월 DD일)
  static String formatMonthDay(DateTime date) {
    return DateFormat('MM월 dd일').format(date);
  }

  // Date String에서 월별 헤더 반환 (YYYY년 MM월)
  static String getMonthHeader(dynamic date) {
    DateTime dateTime;
    if (date is String) {
      dateTime = DateFormat('yyyy-MM-dd').parse(date);
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return '';
    }
    return DateFormat('yyyy년 MM월').format(dateTime);
  }

  // Group matches by month
  static Map<String, List<T>> groupByMonth<T>(List<T> items, DateTime Function(T) getDate) {
    final Map<String, List<T>> grouped = {};
    
    for (var item in items) {
      final date = getDate(item);
      final monthKey = DateFormat('yyyy-MM').format(date);
      
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      
      grouped[monthKey]!.add(item);
    }
    
    return grouped;
  }

  // Show a snackbar with consistent design
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.white,
          ),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.darkGray,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show confirmation dialog with consistent design
  static Future<bool> showConfirmationDialog(
    BuildContext context, 
    String title, 
    String content,
    {String confirmLabel = '네', String cancelLabel = '아니오'}
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          title,
          style: AppTextStyles.displayMedium,
        ),
        content: Text(
          content,
          style: AppTextStyles.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.neutral,
            ),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  // Get color based on match result using app colors
  static Color getResultColor(String result) {
    switch (result) {
      case '승':
        return AppColors.success;
      case '패':
        return AppColors.error;
      case '무':
      default:
        return AppColors.warning;
    }
  }

  // 요일 구하기 (ex: 월요일)
  static String getDayOfWeek(DateTime date) {
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    return '${days[date.weekday - 1]}요일';
  }
  
  // 시간 포맷 함수 (ex: 오후 3:30)
  static String formatTime(DateTime date) {
    final hour = date.hour;
    final period = hour < 12 ? '오전' : '오후';
    final formattedHour = hour <= 12 ? hour : hour - 12;
    final formattedMinute = date.minute.toString().padLeft(2, '0');
    return '$period $formattedHour:$formattedMinute';
  }
  
  // 쿼터 번호와 쿼터 텍스트 매핑
  static String getQuarterText(int quarter) {
    switch (quarter) {
      case 1:
        return '1쿼터';
      case 2:
        return '2쿼터';
      case 3:
        return '3쿼터';
      case 4:
        return '4쿼터';
      default:
        return '';
    }
  }
} 
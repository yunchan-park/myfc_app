import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  // Get month header (YYYY년 MM월)
  static String getMonthHeader(DateTime date) {
    return DateFormat('yyyy년 MM월').format(date);
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

  // Show a snackbar
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    // Material 스타일의 스낵바
    if (Theme.of(context).platform == TargetPlatform.android) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.black,
          duration: const Duration(seconds: 2),
        ),
      );
    } 
    // Cupertino 스타일의 알림 (iOS)
    else {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          message: Text(
            message,
            style: TextStyle(
              color: isError ? CupertinoColors.destructiveRed : CupertinoColors.black,
              fontSize: 16,
            ),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  // Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, 
    String title, 
    String content,
    {String confirmLabel = '네', String cancelLabel = '아니오'}
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[800],
            ),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  // Get color based on match result
  static Color getResultColor(String result) {
    switch (result) {
      case '승':
        return Colors.blue;
      case '패':
        return Colors.red;
      case '무':
      default:
        return Colors.grey;
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
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.black,
        duration: const Duration(seconds: 2),
      ),
    );
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
} 
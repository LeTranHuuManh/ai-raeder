import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  // Format date
  static String formatDate(DateTime date, {String format = 'dd/MM/yyyy'}) {
    return DateFormat(format).format(date);
  }

  // Format date time
  static String formatDateTime(
    DateTime date, {
    String format = 'dd/MM/yyyy HH:mm',
  }) {
    return DateFormat(format).format(date);
  }

  // Time ago (relative time)
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks tuần trước';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months tháng trước';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years năm trước';
    }
  }

  // Format currency
  static String formatCurrency(double amount, {String symbol = 'đ'}) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)}$symbol';
  }

  // Format number
  static String formatNumber(num number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  // Truncate string
  static String truncateString(
    String text,
    int maxLength, {
    String suffix = '...',
  }) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + suffix;
  }

  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Capitalize each word
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  // Remove accents (Vietnamese)
  static String removeVietnameseAccents(String text) {
    text = text.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    text = text.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    text = text.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    text = text.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    text = text.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    text = text.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    text = text.replaceAll(RegExp(r'[đ]'), 'd');
    text = text.replaceAll(RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'), 'A');
    text = text.replaceAll(RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]'), 'E');
    text = text.replaceAll(RegExp(r'[ÌÍỊỈĨ]'), 'I');
    text = text.replaceAll(RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'), 'O');
    text = text.replaceAll(RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]'), 'U');
    text = text.replaceAll(RegExp(r'[ỲÝỴỶỸ]'), 'Y');
    text = text.replaceAll(RegExp(r'[Đ]'), 'D');
    return text;
  }

  // Generate slug
  static String generateSlug(String text) {
    text = removeVietnameseAccents(text);
    text = text.toLowerCase();
    text = text.replaceAll(RegExp(r'[^\w\s-]'), '');
    text = text.replaceAll(RegExp(r'[\s_-]+'), '-');
    text = text.replaceAll(RegExp(r'^-+|-+$'), '');
    return text;
  }

  // Is valid email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Is valid phone
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[0-9]{10,11}$');
    return phoneRegex.hasMatch(phone);
  }

  // Generate random string
  static String generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      length,
      (index) => chars[DateTime.now().microsecondsSinceEpoch % chars.length],
    ).join();
  }

  // Parse enum
  static T? parseEnum<T>(List<T> values, String? value) {
    if (value == null) return null;
    try {
      return values.firstWhere((e) => e.toString().split('.').last == value);
    } catch (e) {
      return null;
    }
  }

  // Delay execution
  static Future<void> delay(int milliseconds) {
    return Future.delayed(Duration(milliseconds: milliseconds));
  }

  // Check if dark mode
  static bool isDarkMode(context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.dark;
  }

  // Get reading time estimate
  static String getReadingTime(int wordCount, {int wordsPerMinute = 200}) {
    final minutes = (wordCount / wordsPerMinute).ceil();
    if (minutes < 60) {
      return '$minutes phút đọc';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours giờ đọc';
      }
      return '$hours giờ $remainingMinutes phút đọc';
    }
  }

  // Count words in text
  static int countWords(String text) {
    return text.trim().split(RegExp(r'\s+')).length;
  }

  // Private constructor to prevent instantiation
  Helpers._();
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:myfc_app/config/routes.dart';

void main() {
  // 플러터 오류 핸들링 설정
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // 릴리즈 모드일 때 오류 처리
      // 오류 로깅 서비스나 분석 도구로 전송할 수 있음
    } else {
      // 디버그 모드일 때 상세 오류 출력
      print('==== Flutter Error ====');
      print(details.exception);
      print(details.stack);
      print('=======================');
    }
  };

  runApp(const MyFCApp());
}

class MyFCApp extends StatelessWidget {
  const MyFCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MY FC',
      theme: ThemeData(
        primarySwatch: const MaterialColor(0xFF3B82F6, {
          50: Color(0xFFEFF6FF),
          100: Color(0xFFDBEAFE),
          200: Color(0xFFBFDBFE),
          300: Color(0xFF93C5FD),
          400: Color(0xFF60A5FA),
          500: Color(0xFF3B82F6),
          600: Color(0xFF2563EB),
          700: Color(0xFF1D4ED8),
          800: Color(0xFF1E40AF),
          900: Color(0xFF1E3A8A),
        }),
        scaffoldBackgroundColor: Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0.5,
          foregroundColor: Colors.black87,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.black87),
          actionsIconTheme: IconThemeData(color: Colors.black87),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF3B82F6),
          unselectedItemColor: Color(0xFF9CA3AF),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 14, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
          bodySmall: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Color(0xFF3B82F6),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      onGenerateRoute: AppRoutes.generateRoute,
      initialRoute: AppRoutes.splash,
      debugShowCheckedModeBanner: false,
    );
  }
}

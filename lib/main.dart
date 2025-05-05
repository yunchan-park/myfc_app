import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/screens/splash_screen.dart';

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
  const MyFCApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Football Club',
      theme: AppTheme.getTheme(),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
      // 디버그 배너 활성화 (개발 중 화면 식별을 위함)
      debugShowCheckedModeBanner: true,
    );
  }
}

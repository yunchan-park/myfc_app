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
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
      ),
      onGenerateRoute: AppRoutes.generateRoute,
      initialRoute: AppRoutes.splash,
      debugShowCheckedModeBanner: false,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/config/theme.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
    } else {
      print('==== Flutter Error ====');
      print(details.exception);
      print(details.stack);
      print('=======================');
    }
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyFC',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}

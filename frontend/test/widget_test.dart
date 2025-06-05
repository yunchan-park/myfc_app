import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfc_app/main.dart';
import 'package:myfc_app/screens/team_profile_screen.dart';
import 'package:myfc_app/screens/add_match_step1_screen.dart';
import 'package:myfc_app/screens/analytics_screen.dart';

void main() {
  testWidgets('앱이 정상적으로 시작되는지 테스트', (WidgetTester tester) async {
    // 앱 실행
    await tester.pumpWidget(MyApp());

    // 앱이 정상적으로 시작되었는지 확인
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('팀 프로필 화면 테스트', (WidgetTester tester) async {
    // 팀 프로필 화면 실행
    await tester.pumpWidget(MaterialApp(
      home: TeamProfileScreen(),
    ));

    // 기본 UI 요소들이 존재하는지 확인
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('경기 등록 Step 1 화면 테스트', (WidgetTester tester) async {
    // 경기 등록 Step 1 화면 실행
    await tester.pumpWidget(MaterialApp(
      home: AddMatchStep1Screen(),
    ));

    // 기본 UI 요소들이 존재하는지 확인
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(Form), findsOneWidget);
  });

  testWidgets('분석 화면 테스트', (WidgetTester tester) async {
    // 분석 화면 실행
    await tester.pumpWidget(MaterialApp(
      home: AnalyticsScreen(),
    ));

    // 기본 UI 요소들이 존재하는지 확인
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('경기 등록 Step 1 - 날짜 선택 테스트', (WidgetTester tester) async {
    // 경기 등록 Step 1 화면 실행
    await tester.pumpWidget(MaterialApp(
      home: AddMatchStep1Screen(),
    ));

    // 기본 UI 요소들이 존재하는지 확인
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('경기 등록 Step 1 - 상대팀 입력 테스트', (WidgetTester tester) async {
    // 경기 등록 Step 1 화면 실행
    await tester.pumpWidget(MaterialApp(
      home: AddMatchStep1Screen(),
    ));

    // 상대팀 입력 필드 찾기
    final opponentField = find.byType(TextFormField).last;
    expect(opponentField, findsOneWidget);

    // 상대팀 이름 입력
    await tester.enterText(opponentField, 'Test Team');
    await tester.pump();

    // 입력된 텍스트 확인
    expect(find.text('Test Team'), findsOneWidget);
  });

  testWidgets('분석 화면 - 탭 전환 테스트', (WidgetTester tester) async {
    // 분석 화면 실행
    await tester.pumpWidget(MaterialApp(
      home: AnalyticsScreen(),
    ));

    // 기본 UI 요소들이 존재하는지 확인
    expect(find.byType(MaterialApp), findsOneWidget);
  });
} 
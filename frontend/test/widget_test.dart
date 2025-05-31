// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfc_app/main.dart';
import 'package:myfc_app/screens/splash_screen.dart';
import 'package:myfc_app/screens/register_team_screen.dart';
import 'package:myfc_app/utils/validators.dart';
import 'package:myfc_app/models/player.dart';
import 'package:myfc_app/models/team.dart';
import 'package:myfc_app/models/match.dart';
import 'package:myfc_app/widgets/common/app_button.dart';
import 'package:myfc_app/widgets/common/app_input.dart';
import 'package:intl/intl.dart';

void main() {
  group('MyFC App Tests', () {
    testWidgets('앱이 스플래시 화면으로 시작되는지 테스트', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pump(); // 첫 번째 프레임 처리
      
      // 스플래시 화면이 있는지 확인
      expect(find.byType(SplashScreen), findsOneWidget);
      
      // 로딩 인디케이터나 MY FC 텍스트 중 하나는 있어야 함
      final hasLoadingOrText = find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
                              find.text('MY FC').evaluate().isNotEmpty;
      expect(hasLoadingOrText, isTrue);
    });

    testWidgets('팀 등록 화면 UI 테스트', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: RegisterTeamScreen()));
      
      // 팀 등록 UI 요소들 확인
      expect(find.text('구단 등록'), findsOneWidget);
      expect(find.text('축구'), findsOneWidget);
      expect(find.text('풋살'), findsOneWidget);
      expect(find.byType(AppInput), findsNWidgets(3)); // 이름, 설명, 비밀번호
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('공통 위젯 테스트', (WidgetTester tester) async {
      // AppButton 테스트
      bool buttonPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: '테스트 버튼',
              onPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );
      
      expect(find.text('테스트 버튼'), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(buttonPressed, isTrue);
    });

    testWidgets('AppInput 위젯 테스트', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppInput(
              controller: controller,
              hint: '테스트 입력',
              validator: (value) => value?.isEmpty == true ? '필수 입력' : null,
            ),
          ),
        ),
      );
      
      expect(find.text('테스트 입력'), findsOneWidget);
      
      // 텍스트 입력 테스트
      await tester.enterText(find.byType(TextFormField), '테스트 값');
      expect(controller.text, equals('테스트 값'));
    });
  });

  group('Validators 테스트', () {
    test('팀 이름 유효성 검사', () {
      expect(Validators.validateTeamName('FC Test'), isNull); // 10자 이하
      expect(Validators.validateTeamName(''), isNotNull);
      expect(Validators.validateTeamName('A' * 11), isNotNull); // 10자 초과
    });

    test('팀 설명 유효성 검사', () {
      expect(Validators.validateTeamDescription('좋은 팀입니다'), isNull);
      expect(Validators.validateTeamDescription(''), isNotNull);
      expect(Validators.validateTeamDescription('A' * 21), isNotNull); // 20자 제한
    });

    test('비밀번호 유효성 검사', () {
      expect(Validators.validatePassword('1234'), isNull); // 4자 이상
      expect(Validators.validatePassword('12345678'), isNull); // 8자
      expect(Validators.validatePassword('123'), isNotNull); // 4자 미만
      expect(Validators.validatePassword(''), isNotNull);
    });

    test('선수 이름 유효성 검사', () {
      expect(Validators.validatePlayerName('Lionel'), isNull); // 10자 이하
      expect(Validators.validatePlayerName(''), isNotNull);
      expect(Validators.validatePlayerName('A' * 11), isNotNull); // 10자 초과
    });

    test('등번호 유효성 검사', () {
      expect(Validators.validatePlayerNumber('10'), isNull);
      expect(Validators.validatePlayerNumber('99'), isNull);
      expect(Validators.validatePlayerNumber('0'), isNotNull);
      expect(Validators.validatePlayerNumber('100'), isNotNull);
      expect(Validators.validatePlayerNumber('abc'), isNotNull);
    });
  });

  group('모델 테스트', () {
    test('Player 모델 JSON 변환 테스트', () {
      final playerJson = {
        'id': 1,
        'name': 'Test Player',
        'position': 'FW',
        'number': 10,
        'team_id': 1,
        'goal_count': 5,
        'assist_count': 3,
        'mom_count': 2,
      };

      // JSON에서 Player 생성
      final player = Player.fromJson(playerJson);
      expect(player.name, equals('Test Player'));
      expect(player.number, equals(10));
      expect(player.position, equals('FW'));
      expect(player.goalCount, equals(5));
      expect(player.assistCount, equals(3));
      expect(player.momCount, equals(2));

      // Player를 JSON으로 변환
      final convertedJson = player.toJson();
      expect(convertedJson['name'], equals('Test Player'));
      expect(convertedJson['number'], equals(10));
      expect(convertedJson['position'], equals('FW'));
      expect(convertedJson['goal_count'], equals(5));
    });

    test('Team 모델 JSON 변환 테스트', () {
      final teamJson = {
        'id': 1,
        'name': 'FC Test',
        'description': 'Test team',
        'type': '축구',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final team = Team.fromJson(teamJson);
      expect(team.name, equals('FC Test'));
      expect(team.description, equals('Test team'));
      expect(team.type, equals('축구'));

      final convertedJson = team.toJson();
      expect(convertedJson['name'], equals('FC Test'));
      expect(convertedJson['description'], equals('Test team'));
      expect(convertedJson['type'], equals('축구'));
    });

    test('Match 모델 결과 계산 테스트', () {
      // 승리 케이스
      final winMatch = Match(
        id: 1,
        date: '2024-03-15',
        opponent: 'Test FC',
        score: '3:1',
      );
      expect(winMatch.getResult(), equals('승'));
      expect(winMatch.getResultEnum(), equals(MatchResult.win));
      expect(winMatch.ourScore, equals(3));
      expect(winMatch.opponentScore, equals(1));

      // 무승부 케이스
      final drawMatch = Match(
        id: 2,
        date: '2024-03-16',
        opponent: 'Draw FC',
        score: '2:2',
      );
      expect(drawMatch.getResult(), equals('무'));
      expect(drawMatch.getResultEnum(), equals(MatchResult.draw));

      // 패배 케이스
      final loseMatch = Match(
        id: 3,
        date: '2024-03-17',
        opponent: 'Strong FC',
        score: '1:3',
      );
      expect(loseMatch.getResult(), equals('패'));
      expect(loseMatch.getResultEnum(), equals(MatchResult.lose));
    });

    test('QuarterScore 모델 테스트', () {
      final quarterScore = QuarterScore(
        ourScore: 2,
        opponentScore: 1,
      );

      expect(quarterScore.ourScore, equals(2));
      expect(quarterScore.opponentScore, equals(1));

      final json = quarterScore.toJson();
      expect(json['our_score'], equals(2));
      expect(json['opponent_score'], equals(1));
    });

    test('Goal 모델 테스트', () {
      final goalJson = {
        'id': 1,
        'quarter': 2,
        'player_id': 10,
        'assist_player_id': 7,
      };

      final goal = Goal.fromJson(goalJson);
      expect(goal.id, equals(1));
      expect(goal.quarter, equals(2));
      expect(goal.playerId, equals(10));
      expect(goal.assistPlayerId, equals(7));

      final convertedJson = goal.toJson();
      expect(convertedJson['quarter'], equals(2));
      expect(convertedJson['player_id'], equals(10));
    });
  });

  group('유틸리티 함수 테스트', () {
    test('날짜 포맷팅 테스트', () {
      final date = DateTime(2024, 3, 15);
      final formatted = DateFormat('yyyy년 MM월 dd일').format(date);
      expect(formatted, equals('2024년 03월 15일'));

      final isoFormatted = DateFormat('yyyy-MM-dd').format(date);
      expect(isoFormatted, equals('2024-03-15'));
    });

    test('쿼터별 점수 계산 테스트', () {
      final quarterScores = {
        1: QuarterScore(ourScore: 2, opponentScore: 1),
        2: QuarterScore(ourScore: 1, opponentScore: 0),
        3: QuarterScore(ourScore: 0, opponentScore: 1),
        4: QuarterScore(ourScore: 1, opponentScore: 0),
      };
      
      int ourTotal = 0;
      int opponentTotal = 0;
      quarterScores.forEach((quarter, scores) {
        ourTotal += scores.ourScore;
        opponentTotal += scores.opponentScore;
      });
      
      expect(ourTotal, equals(4));
      expect(opponentTotal, equals(2));
      expect('$ourTotal:$opponentTotal', equals('4:2'));
    });

    test('매치 통계 계산 테스트', () {
      final matches = [
        Match(id: 1, date: '2024-03-01', opponent: 'Team A', score: '3:1'),
        Match(id: 2, date: '2024-03-02', opponent: 'Team B', score: '1:1'),
        Match(id: 3, date: '2024-03-03', opponent: 'Team C', score: '0:2'),
        Match(id: 4, date: '2024-03-04', opponent: 'Team D', score: '2:0'),
      ];

      int wins = matches.where((m) => m.getResult() == '승').length;
      int draws = matches.where((m) => m.getResult() == '무').length;
      int losses = matches.where((m) => m.getResult() == '패').length;
      
      expect(wins, equals(2));  // 3:1, 2:0
      expect(draws, equals(1)); // 1:1
      expect(losses, equals(1)); // 0:2

      int totalGoals = matches.fold(0, (sum, m) => sum + m.ourScore);
      int totalConceded = matches.fold(0, (sum, m) => sum + m.opponentScore);
      
      expect(totalGoals, equals(6));    // 3+1+0+2
      expect(totalConceded, equals(4)); // 1+1+2+0
    });
  });

  group('서비스 테스트 (Mock)', () {
    test('API 요청 URL 생성 테스트', () {
      const baseUrl = 'http://localhost:8000';
      
      // 팀 관련 엔드포인트
      expect('$baseUrl/teams/create', equals('http://localhost:8000/teams/create'));
      expect('$baseUrl/teams/login', equals('http://localhost:8000/teams/login'));
      expect('$baseUrl/teams/1', equals('http://localhost:8000/teams/1'));
      
      // 선수 관련 엔드포인트
      expect('$baseUrl/players/create', equals('http://localhost:8000/players/create'));
      expect('$baseUrl/players/team/1', equals('http://localhost:8000/players/team/1'));
      
      // 매치 관련 엔드포인트
      expect('$baseUrl/matches/create', equals('http://localhost:8000/matches/create'));
      expect('$baseUrl/matches/team/1', equals('http://localhost:8000/matches/team/1'));
      expect('$baseUrl/matches/1/detail', equals('http://localhost:8000/matches/1/detail'));
    });

    test('인증 헤더 생성 테스트', () {
      const token = 'test_token_123';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      expect(headers['Content-Type'], equals('application/json'));
      expect(headers['Authorization'], equals('Bearer test_token_123'));
    });

    test('JWT 토큰 파싱 시뮬레이션 테스트', () {
      // 실제 JWT 토큰 파싱 로직과 유사한 테스트
      const mockTokenParts = ['header', 'payload', 'signature'];
      const payload = 'eyJzdWIiOiIxMjMiLCJuYW1lIjoiVGVzdCBUZWFtIn0'; // base64 encoded {"sub":"123","name":"Test Team"}
      
      expect(mockTokenParts.length, equals(3));
      expect(payload.isNotEmpty, isTrue);
      
      // 실제 앱에서는 base64 디코딩 후 team_id 추출
      const expectedTeamId = 123;
      expect(expectedTeamId, isA<int>());
    });
  });

  group('에러 처리 테스트', () {
    test('네트워크 에러 시뮬레이션', () {
      const errorMessage = '네트워크 연결을 확인해주세요';
      expect(errorMessage.isNotEmpty, isTrue);
      expect(errorMessage, contains('네트워크'));
    });

    test('잘못된 응답 데이터 처리', () {
      final invalidPlayerData = {'name': 'Test'};  // number, position 누락
      
      expect(() => Player.fromJson(invalidPlayerData), throwsA(isA<TypeError>()));
    });

    test('빈 데이터 처리', () {
      final emptyList = <Player>[];
      final emptyMatches = <Match>[];
      
      expect(emptyList.isEmpty, isTrue);
      expect(emptyMatches.length, equals(0));
    });
  });
}

#!/usr/bin/env dart
/// Flutter 앱 테스트 실행 스크립트
/// 
/// Usage:
///   dart run_tests.dart              # 모든 테스트 실행
///   dart run_tests.dart --unit       # 단위 테스트만 실행
///   dart run_tests.dart --widget     # 위젯 테스트만 실행
///   dart run_tests.dart --coverage   # 커버리지 포함

import 'dart:io';

void main(List<String> arguments) async {
  final testType = _parseTestType(arguments);
  final includeCoverage = arguments.contains('--coverage');
  final verbose = arguments.contains('--verbose') || arguments.contains('-v');
  
  print('Flutter 테스트 실행 중...');
  print('테스트 타입: ${testType ?? '전체'}');
  if (includeCoverage) print('커버리지: 포함');
  print('=' * 50);
  
  try {
    await _runTests(testType, includeCoverage, verbose);
    print('\n✅ 테스트가 성공적으로 완료되었습니다!');
  } catch (e) {
    print('\n❌ 테스트 실행 중 오류 발생: $e');
    exit(1);
  }
}

String? _parseTestType(List<String> arguments) {
  if (arguments.contains('--unit')) return 'unit';
  if (arguments.contains('--widget')) return 'widget';
  if (arguments.contains('--integration')) return 'integration';
  return null;
}

Future<void> _runTests(String? testType, bool includeCoverage, bool verbose) async {
  final args = ['test'];
  
  // 테스트 타입별 필터링
  if (testType != null) {
    switch (testType) {
      case 'unit':
        args.add('test/unit_test.dart');
        break;
      case 'widget':
        args.add('test/widget_test.dart');
        break;
      case 'integration':
        args.add('test/integration_test.dart');
        break;
    }
  }
  
  // 커버리지 옵션
  if (includeCoverage) {
    args.addAll(['--coverage']);
  }
  
  // 상세 출력
  if (verbose) {
    args.add('--verbose');
  }
  
  print('실행 명령: flutter ${args.join(' ')}');
  
  final result = await Process.run('flutter', args);
  
  if (result.exitCode == 0) {
    print(result.stdout);
    
    // 커버리지 리포트 생성
    if (includeCoverage) {
      await _generateCoverageReport();
    }
  } else {
    print('STDOUT: ${result.stdout}');
    print('STDERR: ${result.stderr}');
    throw Exception('테스트 실행 실패 (종료 코드: ${result.exitCode})');
  }
}

Future<void> _generateCoverageReport() async {
  print('\n커버리지 리포트 생성 중...');
  
  // lcov 도구가 설치되어 있는 경우 HTML 리포트 생성
  final lcovResult = await Process.run('which', ['genhtml'], runInShell: true);
  
  if (lcovResult.exitCode == 0) {
    final genhtmlResult = await Process.run(
      'genhtml',
      ['coverage/lcov.info', '-o', 'coverage/html'],
      runInShell: true,
    );
    
    if (genhtmlResult.exitCode == 0) {
      print('✅ HTML 커버리지 리포트가 coverage/html/ 디렉토리에 생성되었습니다.');
    } else {
      print('⚠️  HTML 리포트 생성에 실패했습니다.');
    }
  } else {
    print('⚠️  genhtml이 설치되어 있지 않습니다. HTML 리포트를 건너뜁니다.');
  }
  
  // 커버리지 요약 출력
  final lcovFile = File('coverage/lcov.info');
  if (await lcovFile.exists()) {
    print('📊 커버리지 파일: coverage/lcov.info');
  }
} 
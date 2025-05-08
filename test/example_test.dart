import 'package:flutter_test/flutter_test.dart';
import 'package:myfc_app/helpers/validators.dart';

void main() {
  test('이메일 검증', () {
    expect(validateEmail('test@test.com'), null);
    expect(validateEmail('invalid'), isNotNull);
  });

  test('비밀번호 검증', () {
    expect(validatePassword('123456'), null);
    expect(validatePassword('123'), isNotNull);
  });
} 
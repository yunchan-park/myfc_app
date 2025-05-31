String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return '이메일을 입력하세요';
  if (!value.contains('@')) return '유효한 이메일을 입력하세요';
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.length < 6) return '비밀번호는 6자 이상이어야 합니다';
  return null;
} 
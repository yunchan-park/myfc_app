class Validators {
  // Validate team name
  static String? validateTeamName(String? value) {
    if (value == null || value.isEmpty) {
      return '구단 이름을 입력해주세요';
    }
    if (value.length > 10) {
      return '구단 이름은 최대 10자까지 입력할 수 있습니다';
    }
    return null;
  }

  // Validate team description
  static String? validateTeamDescription(String? value) {
    if (value == null || value.isEmpty) {
      return '구단 소개글을 입력해주세요';
    }
    if (value.length > 20) {
      return '구단 소개글은 최대 20자까지 입력할 수 있습니다';
    }
    return null;
  }

  // Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    if (value.length < 4) {
      return '비밀번호는 최소 4자 이상이어야 합니다';
    }
    return null;
  }

  // Validate player name
  static String? validatePlayerName(String? value) {
    if (value == null || value.isEmpty) {
      return '선수 이름을 입력해주세요';
    }
    if (value.length > 10) {
      return '선수 이름은 최대 10자까지 입력할 수 있습니다';
    }
    return null;
  }

  // Validate player number
  static String? validatePlayerNumber(String? value) {
    if (value == null || value.isEmpty) {
      return '등번호를 입력해주세요';
    }
    
    final number = int.tryParse(value);
    if (number == null) {
      return '유효한 숫자를 입력해주세요';
    }
    
    if (number < 1 || number > 99) {
      return '등번호는 1-99 사이의 숫자여야 합니다';
    }
    
    return null;
  }

  // Validate opponent team name
  static String? validateOpponentName(String? value) {
    if (value == null || value.isEmpty) {
      return '상대 구단 이름을 입력해주세요';
    }
    return null;
  }
} 
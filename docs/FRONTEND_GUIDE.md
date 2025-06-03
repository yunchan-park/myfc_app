# MyFC 프론트엔드 가이드 📱

## 📖 개요

MyFC 프론트엔드는 Flutter로 구축된 크로스 플랫폼 애플리케이션으로, 웹과 모바일에서 동일한 사용자 경험을 제공합니다. 깔끔한 아키텍처와 재사용 가능한 컴포넌트를 통해 유지보수가 용이하고 확장 가능한 구조로 설계되었습니다.

## 🏗️ 디렉토리 구조

```
frontend/lib/
├── main.dart                    # 앱 엔트리 포인트
├── config/                      # 설정 관리
│   └── app_config.dart         # 앱 전역 설정
├── models/                      # 데이터 모델
│   ├── team.dart               # 팀 모델
│   ├── player.dart             # 선수 모델
│   ├── match.dart              # 매치 모델
│   └── analytics.dart          # 분석 데이터 모델
├── services/                    # 비즈니스 로직 서비스
│   ├── api_service.dart        # API 통신 서비스
│   ├── auth_service.dart       # 인증 관리 서비스
│   └── storage_service.dart    # 로컬 저장소 서비스
├── screens/                     # UI 화면들
│   ├── splash_screen.dart      # 스플래시 화면
│   ├── login_screen.dart       # 로그인 화면
│   ├── register_team_screen.dart # 팀 등록 화면
│   ├── home_screen.dart        # 홈 화면
│   ├── player_management_screen.dart # 선수 관리
│   ├── match_detail_screen.dart # 매치 상세
│   ├── match_summary_screen.dart # 매치 요약
│   ├── team_profile_screen.dart # 팀 프로필
│   ├── analytics_screen.dart   # 분석 화면
│   └── add_match_step*.dart    # 매치 등록 4단계
├── widgets/                     # 재사용 UI 컴포넌트
│   ├── common/                 # 공통 위젯
│   │   ├── app_button.dart     # 커스텀 버튼
│   │   ├── app_input.dart      # 커스텀 입력 필드
│   │   └── app_card.dart       # 커스텀 카드
│   ├── team/                   # 팀 관련 위젯
│   ├── analytics/              # 분석 관련 위젯
│   ├── match_card.dart         # 매치 카드
│   ├── player_card.dart        # 선수 카드
│   ├── goal_list_widget.dart   # 골 목록 위젯
│   └── quarter_score_widget.dart # 쿼터 점수 위젯
├── utils/                       # 유틸리티 함수
│   ├── validators.dart         # 입력 유효성 검증
│   ├── helpers.dart            # 헬퍼 함수들
│   └── async_helpers.dart      # 비동기 헬퍼
├── helpers/                     # 추가 도우미 클래스
├── viewmodels/                  # 상태 관리 (MVVM)
└── routers/                     # 라우팅 설정
```

## 📊 Models - 데이터 모델

### 🎯 역할
- 서버와 클라이언트 간 데이터 구조 정의
- JSON 직렬화/역직렬화 처리
- 비즈니스 로직 메서드 포함

### 📄 주요 파일들

#### `team.dart` - 팀 모델
```dart
class Team {
  final int? id;
  final String name;
  final String description;
  final String type;
  final DateTime? createdAt;

  // JSON 변환 메서드
  factory Team.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  
  // 팀 타입 검증
  bool get isFootball => type == '축구';
  bool get isFutsal => type == '풋살';
}
```

#### `player.dart` - 선수 모델
```dart
class Player {
  final int? id;
  final String name;
  final String position;
  final int number;
  final int? teamId;
  final int goalCount;
  final int assistCount;
  final int momCount;

  // 포지션별 색상 반환
  Color get positionColor {
    switch (position) {
      case 'GK': return Colors.yellow;
      case 'DF': return Colors.blue;
      case 'MF': return Colors.green;
      case 'FW': return Colors.red;
      default: return Colors.grey;
    }
  }
  
  // 통계 계산
  double get averageGoalsPerMatch => ...;
}
```

#### `match.dart` - 매치 모델
```dart
class Match {
  final int? id;
  final String date;
  final String opponent;
  final String score;
  final int? teamId;
  final List<Goal>? goals;
  final Map<int, QuarterScore>? quarterScores;

  // 경기 결과 계산
  String getResult() {
    final scores = score.split(':');
    int ourScore = int.parse(scores[0]);
    int opponentScore = int.parse(scores[1]);
    
    if (ourScore > opponentScore) return '승';
    if (ourScore < opponentScore) return '패';
    return '무';
  }
  
  // 결과별 색상
  Color get resultColor {
    switch (getResult()) {
      case '승': return Colors.green;
      case '패': return Colors.red;
      case '무': return Colors.orange;
      default: return Colors.grey;
    }
  }
}

// 골 기록 모델
class Goal {
  final int? id;
  final int quarter;
  final int playerId;
  final int? assistPlayerId;
}

// 쿼터 점수 모델
class QuarterScore {
  final int ourScore;
  final int opponentScore;
  
  Map<String, dynamic> toJson() => {
    'our_score': ourScore,
    'opponent_score': opponentScore,
  };
}
```

#### `analytics.dart` - 분석 데이터 모델
```dart
class TeamAnalytics {
  final int totalMatches;
  final int wins;
  final int draws;
  final int losses;
  final int totalGoals;
  final int totalConceded;
  
  // 승률 계산
  double get winRate => totalMatches > 0 ? wins / totalMatches : 0.0;
  
  // 득실차
  int get goalDifference => totalGoals - totalConceded;
}

class PlayerAnalytics {
  final int playerId;
  final String playerName;
  final int goals;
  final int assists;
  final int momCount;
  final double averageRating;
}
```

## 🔧 Services - 비즈니스 로직 서비스

### 🎯 역할
- API 통신 관리
- 데이터 캐싱 및 상태 관리
- 비즈니스 로직 처리
- 외부 서비스 연동

### 📄 주요 파일들

#### `api_service.dart` - API 통신 서비스
```dart
class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  
  // 팀 관련 API
  Future<Team> createTeam(Map<String, dynamic> teamData);
  Future<Map<String, dynamic>> loginTeam(Map<String, dynamic> loginData);
  Future<Team> getTeam(int teamId);
  
  // 선수 관련 API
  Future<Player> createPlayer(Map<String, dynamic> playerData);
  Future<List<Player>> getTeamPlayers(int teamId);
  Future<Player> updatePlayer(int playerId, Map<String, dynamic> playerData);
  Future<void> deletePlayer(int playerId);
  
  // 매치 관련 API
  Future<Match> createMatch(Map<String, dynamic> matchData);
  Future<List<Match>> getTeamMatches(int teamId);
  Future<Match> getMatchDetail(int matchId);
  Future<Goal> addGoal(int matchId, Map<String, dynamic> goalData);
  
  // HTTP 요청 헬퍼
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  });
  
  // 인증 헤더 생성
  Map<String, String> _getAuthHeaders() {
    final token = StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
```

#### `auth_service.dart` - 인증 관리 서비스
```dart
class AuthService {
  // 로그인 상태 확인
  static bool get isLoggedIn => StorageService.getToken() != null;
  
  // 현재 팀 ID 반환
  static int? get currentTeamId => StorageService.getTeamId();
  
  // 로그인 처리
  Future<void> login(String teamName, String password) async {
      final response = await ApiService().loginTeam({
      'team_name': teamName,
        'password': password,
      });
      
    // 토큰 저장
    await StorageService.setToken(response['token']);
    await StorageService.setTeamId(response['team_id']);
  }
  
  // 로그아웃
  Future<void> logout() async {
    await StorageService.clearAll();
  }
}
```

#### `storage_service.dart` - 로컬 저장소 서비스
```dart
class StorageService {
  static const String tokenKey = 'auth_token';
  static const String teamIdKey = 'team_id';
  
  // 토큰 관리
  static Future<void> setToken(String token) async {
    await SharedPreferences.getInstance()
      .then((prefs) => prefs.setString(tokenKey, token));
  }
  
  static String? getToken() {
    return SharedPreferences.getInstance()
      .then((prefs) => prefs.getString(tokenKey));
  }
  
  // 팀 ID 관리
  static Future<void> setTeamId(int teamId) async {
    await SharedPreferences.getInstance()
      .then((prefs) => prefs.setInt(teamIdKey, teamId));
  }
  
  static int? getTeamId() {
    return SharedPreferences.getInstance()
      .then((prefs) => prefs.getInt(teamIdKey));
  }
  
  // 모든 데이터 삭제
  static Future<void> clearAll() async {
    await SharedPreferences.getInstance()
      .then((prefs) => prefs.clear());
  }
}
```

## 🖥️ Screens - UI 화면들

### 🎯 역할
- 사용자 인터페이스 구성
- 사용자 상호작용 처리
- 화면별 상태 관리
- 네비게이션 관리

### 📄 주요 화면들

#### `home_screen.dart` - 홈 화면
```dart
class HomeScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        children: [
          MatchesTab(),      // 매치 목록
          PlayersTab(),      // 선수 목록
          AnalyticsTab(),    // 통계 분석
          TeamTab(),         // 팀 정보
        ],
      ),
      bottomNavigationBar: TabBar(...),
    );
  }
}
```

#### `player_management_screen.dart` - 선수 관리
```dart
class PlayerManagementScreen extends StatefulWidget {
  // 선수 목록 표시
  // 선수 추가/편집/삭제 기능
  // 검색 및 필터링
  // 통계 요약 표시
  
  Future<void> _loadPlayers() async {
    final teamId = AuthService.currentTeamId;
    if (teamId != null) {
      final players = await ApiService().getTeamPlayers(teamId);
      setState(() {
        this.players = players;
      });
    }
  }
  
  void _showAddPlayerDialog() {
    // 선수 추가 다이얼로그 표시
  }
}
```

#### `add_match_step1_screen.dart` ~ `step4_screen.dart` - 매치 등록 4단계
```dart
// Step 1: 기본 정보 입력
class AddMatchStep1Screen extends StatefulWidget {
  // 날짜, 상대팀, 최종 스코어 입력
}

// Step 2: 출전 선수 선택
class AddMatchStep2Screen extends StatefulWidget {
  // 등록된 선수 목록에서 출전 선수 선택
}

// Step 3: 쿼터별 점수 입력
class AddMatchStep3Screen extends StatefulWidget {
  // 1~4쿼터별 세부 점수 입력
}

// Step 4: 골 기록 입력
class AddMatchStep4Screen extends StatefulWidget {
  // 득점자, 어시스트, 쿼터 정보 입력
  // 최종 매치 데이터 서버 전송
}
```

#### `analytics_screen.dart` - 통계 분석 화면
```dart
class AnalyticsScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            TeamOverviewWidget(),        // 팀 전체 통계 개요
            GoalsAnalysisWidget(),       // 득점/실점 패턴 분석
            PlayerContributionsWidget(), // 선수별 기여도
            TrendAnalysisWidget(),       // 추세 분석
          ],
        ),
      ),
    );
  }
  
  // API 호출 메서드들
  Future<void> _loadTeamOverview() async {
    final teamId = AuthService.currentTeamId;
    final overview = await ApiService().getTeamAnalyticsOverview(teamId);
    // 데이터 처리 및 상태 업데이트
  }
  
  Future<void> _loadGoalsAnalysis() async {
    final teamId = AuthService.currentTeamId;
    final goalsWinCorrelation = await ApiService().getGoalsWinCorrelation(teamId);
    final concededLossCorrelation = await ApiService().getConcededLossCorrelation(teamId);
    // 데이터 처리 및 상태 업데이트
  }
  
  Future<void> _loadPlayerContributions() async {
    final teamId = AuthService.currentTeamId;
    final contributions = await ApiService().getPlayerContributions(teamId);
    // 데이터 처리 및 상태 업데이트
  }
}

// 분석 위젯들
class TeamOverviewWidget extends StatelessWidget {
  // 팀 전체 통계 표시
  // - 총 경기 수, 승/무/패
  // - 평균 득점/실점
  // - 최다 득점/실점 경기
}

class GoalsAnalysisWidget extends StatelessWidget {
  // 득점/실점 패턴 분석
  // - 득점-승률 상관관계 그래프
  // - 실점-패배율 상관관계 그래프
}

class PlayerContributionsWidget extends StatelessWidget {
  // 선수별 기여도 분석
  // - 승리 기여도 순위
  // - 득점/어시스트 효율성
}

class TrendAnalysisWidget extends StatelessWidget {
  // 팀 성과 추세 분석
  // - 최근 경기 성과 추이
  // - 득점/실점 추세
}
```

## 🧩 Widgets - 재사용 UI 컴포넌트

### 🎯 역할
- 일관된 UI 제공
- 코드 재사용성 증대
- 유지보수 편의성
- 디자인 시스템 구현

### 📄 Common 위젯들

#### `app_button.dart` - 커스텀 버튼
```dart
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final ButtonType type;
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: _getButtonStyle(),
      child: isLoading 
        ? CircularProgressIndicator()
        : Text(text),
    );
  }
  
  ButtonStyle _getButtonStyle() {
    switch (type) {
      case ButtonType.primary:
        return ElevatedButton.styleFrom(primary: Colors.blue);
      case ButtonType.secondary:
        return ElevatedButton.styleFrom(primary: Colors.grey);
      case ButtonType.danger:
        return ElevatedButton.styleFrom(primary: Colors.red);
    }
  }
}
```

#### `app_input.dart` - 커스텀 입력 필드
```dart
class AppInput extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(),
      ),
    );
  }
}
```

### 📄 특화 위젯들

#### `match_card.dart` - 매치 카드
```dart
class MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback? onTap;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: match.resultColor,
          child: Text(match.getResult()),
        ),
        title: Text(match.opponent),
        subtitle: Text(match.date),
        trailing: Text(
          match.score,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
```

#### `player_card.dart` - 선수 카드
```dart
class PlayerCard extends StatelessWidget {
  final Player player;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: player.positionColor,
                  child: Text('${player.number}'),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(player.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(player.position),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text('수정')),
                    PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem('골', player.goalCount),
                _StatItem('도움', player.assistCount),
                _StatItem('MOM', player.momCount),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

#### `quarter_score_widget.dart` - 쿼터 점수 위젯
```dart
class QuarterScoreWidget extends StatelessWidget {
  final int quarter;
  final int ourScore;
  final int opponentScore;
  final Function(int, int)? onScoreChanged;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8.0),
      child: Column(
          children: [
            Text('${quarter}쿼터'),
            Row(
        children: [
                _buildScoreInput(
                  label: '우리 팀',
                  value: ourScore,
                  onChanged: (value) => onScoreChanged?.call(value, opponentScore),
                ),
                Text(':'),
                _buildScoreInput(
                  label: '상대 팀',
                  value: opponentScore,
                  onChanged: (value) => onScoreChanged?.call(ourScore, value),
                ),
        ],
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🛠️ Utils - 유틸리티 함수

### 🎯 역할
- 공통 로직 모듈화
- 입력 유효성 검증
- 데이터 포맷팅 및 변환
- 비동기 작업 헬퍼

### 📄 주요 파일들

#### `validators.dart` - 입력 유효성 검증
```dart
class Validators {
  // 팀 이름 검증
  static String? validateTeamName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '팀 이름을 입력해주세요';
    }
    if (value.length > 20) {
      return '팀 이름은 20자 이하로 입력해주세요';
    }
    return null;
  }
  
  // 선수 이름 검증
  static String? validatePlayerName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '선수 이름을 입력해주세요';
    }
    if (value.length > 20) {
      return '선수 이름은 20자 이하로 입력해주세요';
    }
    return null;
  }
  
  // 등번호 검증
  static String? validatePlayerNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '등번호를 입력해주세요';
    }
    final number = int.tryParse(value);
    if (number == null || number < 1 || number > 99) {
      return '등번호는 1~99 사이의 숫자여야 합니다';
    }
    return null;
  }
  
  // 포지션 검증
  static String? validatePosition(String? value) {
    const validPositions = ['GK', 'DF', 'MF', 'FW'];
    if (value == null || !validPositions.contains(value)) {
      return '올바른 포지션을 선택해주세요';
    }
    return null;
  }
  
  // 비밀번호 검증
  static String? validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return '비밀번호는 6자 이상이어야 합니다';
    }
    return null;
  }
}
```

#### `helpers.dart` - 헬퍼 함수들
```dart
class Helpers {
  // 날짜 포맷팅
  static String formatDate(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일').format(date);
  }
  
  static String formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  
  // 시간 포맷팅
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }
  
  // 점수 문자열을 개별 점수로 분리
  static List<int> parseScore(String score) {
    final parts = score.split(':');
    return [int.parse(parts[0]), int.parse(parts[1])];
  }
  
  // 개별 점수를 점수 문자열로 결합
  static String combineScore(int ourScore, int opponentScore) {
    return '$ourScore:$opponentScore';
  }
  
  // 스낵바 표시
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  // 확인 다이얼로그
  static Future<bool> showConfirmDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('확인'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
```

#### `async_helpers.dart` - 비동기 헬퍼
```dart
class AsyncHelpers {
  // 안전한 API 호출
  static Future<T?> safeApiCall<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } catch (e) {
      print('API 호출 오류: $e');
      return null;
    }
  }
  
  // 로딩 상태와 함께 작업 실행
  static Future<void> withLoading(
    VoidCallback setLoading,
    VoidCallback clearLoading,
    Future<void> Function() task,
  ) async {
    setLoading();
    try {
      await task();
    } finally {
      clearLoading();
    }
  }
}
```

## 🎨 디자인 시스템

### 색상 체계
```dart
// 주요 색상
static const Color primaryColor = Color(0xFF2196F3);
static const Color secondaryColor = Color(0xFF4CAF50);
static const Color errorColor = Color(0xFFF44336);
static const Color warningColor = Color(0xFFFF9800);

// 포지션별 색상
static const Map<String, Color> positionColors = {
  'GK': Colors.yellow,
  'DF': Colors.blue,
  'MF': Colors.green,
  'FW': Colors.red,
};
```

### 텍스트 스타일
```dart
// 헤딩 스타일
static const TextStyle heading1 = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
);

static const TextStyle heading2 = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
);

// 본문 스타일
static const TextStyle body1 = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.normal,
);
```

---

**이 프론트엔드 구조는 확장 가능하고 유지보수가 용이하며, 사용자 경험을 최우선으로 하는 축구 클럽 관리 애플리케이션을 구현하기 위해 설계되었습니다.** 
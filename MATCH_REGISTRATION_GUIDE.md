# 📊 매치 등록 시스템 상세 가이드

MyFC 앱의 매치 등록은 4단계로 구성되어 있으며, 각 단계별로 체계적인 데이터 수집과 검증을 통해 완전한 경기 기록을 생성합니다.

---

## 📋 1단계: 기본 정보 입력
**파일:** `lib/screens/add_match_step1_screen.dart`

### 🔹 입력 값
- **경기 날짜** (`DateTime`): DatePicker로 선택
- **상대 팀명** (`String`): 텍스트 입력 (필수)
- **쿼터 수** (`int`): 2쿼터/4쿼터 선택 (기본값: 2쿼터)

### 🔹 UI/UX 구성
```
📱 화면 구성:
├── AppBar: "매치 추가" 타이틀
├── Step Indicator: [1] - 2 - 3 - 4 진행도 표시
├── AppCard 형태의 입력 폼
│   ├── 📅 날짜 선택 버튼 (현재 날짜가 기본값)
│   ├── ⚽ 상대팀명 입력 필드 (validation 적용)
│   └── 🏃 쿼터 수 선택 (라디오 버튼)
└── "다음" 버튼
```

### 🔹 데이터 검증
- 상대팀명: 필수 입력, 공백 제거
- 날짜: 2020년 ~ 2030년 범위 내
- 쿼터 수: 2 또는 4만 선택 가능

### 🔹 다음 단계 전달 데이터
```dart
{
  'date': DateTime,
  'opponent': String,
  'quarters': int,
}
```

---

## 📋 2단계: 선수 선택
**파일:** `lib/screens/add_match_step2_screen.dart`

### 🔹 입력 값
- **참여 선수** (`List<int>`): 다중 선택 (최소 1명 필수)

### 🔹 데이터 로딩
```dart
// API 호출
getTeamPlayers(teamId, token)
```

### 🔹 UI/UX 구성
```
📱 화면 구성:
├── Step Indicator: 1 - [2] - 3 - 4
├── 로딩 상태 표시
├── 선수 목록 (API에서 로드)
│   ├── ✅ 체크박스 + 선수명
│   ├── 실시간 선택 카운트
│   └── 스크롤 가능한 리스트
├── 선택 상태 표시
└── "다음" 버튼 (validation 적용)
```

### 🔹 데이터 검증
- 최소 1명 이상 선수 선택 필수
- 중복 선택 방지

### 🔹 다음 단계 전달 데이터
```dart
{
  'date': DateTime,
  'opponent': String,
  'quarters': int,
  'playerIds': List<int>,
}
```

---

## 📋 3단계: 점수 입력
**파일:** `lib/screens/add_match_step3_screen.dart`

### 🔹 입력 값
- **쿼터별 점수** (`Map<int, Map<String, int>>`)
  - 우리팀 점수
  - 상대팀 점수
- **골 기록** (`List<Map>`) - 선택사항
  - 득점자 ID
  - 어시스트 ID (선택사항)
  - 해당 쿼터

### 🔹 UI/UX 구성
```
📱 화면 구성:
├── Step Indicator: 1 - 2 - [3] - 4
├── 쿼터별 점수 입력 섹션
│   ├── 1쿼터: [우리팀] vs [상대팀]
│   ├── 2쿼터: [우리팀] vs [상대팀]
│   ├── (3쿼터, 4쿼터 - 선택에 따라)
│   └── 📊 실시간 총점 계산
├── 골 기록 섹션 (선택사항)
│   ├── "골 추가" 버튼
│   ├── 등록된 골 목록
│   └── 골 정보: 득점자, 어시스트, 쿼터
└── "다음" 버튼
```

### 🔹 골 등록 프로세스
1. "골 추가" 버튼 클릭
2. 모달 다이얼로그 표시
3. 쿼터 선택
4. 득점자 선택 (필수)
5. 어시스트 선택 (선택사항)
6. 확인 시 해당 쿼터 우리팀 점수 +1

### 🔹 데이터 계산
```dart
// 총점 자동 계산
int ourTotalScore = 0;
int opponentTotalScore = 0;

for (final quarterScore in _quarterScores.values) {
  ourTotalScore += quarterScore['our_score']!;
  opponentTotalScore += quarterScore['opponent_score']!;
}

final score = '$ourTotalScore:$opponentTotalScore';
```

### 🔹 다음 단계 전달 데이터
```dart
{
  'date': DateTime,
  'opponent': String,
  'score': String,
  'playerIds': List<int>,
  'quarterScores': Map<int, Map<String, int>>,
  'goals': List<Map>,
}
```

---

## 📋 4단계: 확인 및 등록
**파일:** `lib/screens/add_match_step4_screen.dart`

### 🔹 표시 정보
- **매치 요약**: 날짜, 상대팀, 최종 점수
- **쿼터별 점수**: 상세 점수표
- **골 기록**: 득점자, 어시스트, 쿼터 정보 (있는 경우)

### 🔹 UI/UX 구성
```
📱 화면 구성:
├── Step Indicator: 1 - 2 - 3 - [4] ✅
├── 📊 경기 요약 카드
│   ├── 📅 날짜
│   ├── ⚽ 상대팀
│   └── 🏆 최종 점수
├── 📋 쿼터별 점수 테이블
├── ⚽ 골 기록 리스트 (있는 경우)
│   ├── 득점자 이름
│   ├── 어시스트 이름
│   └── 쿼터 정보
└── "매치 등록 완료하기" 버튼
    └── 로딩 상태 표시
```

---

## 🗄️ 서버 저장 프로세스

### 🔹 API 호출 순서
```dart
1. createMatch() 호출
   ├── 기본 매치 정보 저장
   ├── 참여 선수들과 연결 (Many-to-Many)
   └── 쿼터별 점수 저장

2. addGoal() 반복 호출 (골이 있는 경우)
   ├── 각 골 기록마다 개별 API 호출
   ├── 득점자/어시스트 통계 자동 업데이트
   └── MOM(Man of the Match) 자동 선정
```

### 🔹 서버 데이터베이스 구조

#### **Match 테이블**
```python
- id: int (Primary Key)
- date: datetime
- opponent: string
- score: string (예: "3:1")
- team_id: int (Foreign Key)
- players: Many-to-Many 관계
```

#### **QuarterScore 테이블**
```python
- id: int (Primary Key)
- match_id: int (Foreign Key)
- quarter: int (1, 2, 3, 4)
- our_score: int
- opponent_score: int
```

#### **Goal 테이블**
```python
- id: int (Primary Key)
- match_id: int (Foreign Key)
- player_id: int (Foreign Key)
- assist_player_id: int (Foreign Key, nullable)
- quarter: int
- scorer_name: string (자동 설정)
- assist_name: string (자동 설정)
```

### 🔹 자동 통계 업데이트

#### **선수 통계 업데이트**
```python
# 득점자 통계
Player.goal_count += 1

# 어시스트 통계  
Player.assist_count += 1 (어시스트가 있는 경우)
```

#### **MOM 자동 선정 로직**
```python
# 점수 계산 시스템
player_scores = {}

for player_id, goal_count in goal_scorers.items():
    player_scores[player_id] = goal_count * 2  # 득점: 2점

for player_id, assist_count in assist_providers.items():
    player_scores[player_id] += assist_count   # 어시스트: 1점

# 최고 점수 선수를 MOM으로 선정
mom_player_id = max(player_scores, key=player_scores.get)
mom_player.mom_count += 1
```

---

## 🔄 완료 후 처리

### 🔹 성공 시
- ✅ "매치가 등록되었습니다" 메시지 표시
- 🏠 홈 화면으로 이동 (`Navigator.pushNamedAndRemoveUntil`)
- 📊 모든 통계 실시간 업데이트 완료

### 🔹 실패 시
- ❌ "매치 등록에 실패했습니다" 에러 메시지
- 🔄 재시도 가능 (데이터 유지)
- 📝 에러 로그 기록

---

## 📊 데이터 흐름도

```
[1단계] 기본정보 입력
    ↓
[2단계] 선수 선택 (API 호출: getTeamPlayers)
    ↓  
[3단계] 점수 입력 + 골 기록
    ↓
[4단계] 확인 및 등록
    ↓
[서버] createMatch + addGoal 호출
    ↓
[통계] 자동 업데이트 + MOM 선정
    ↓
[완료] 홈 화면 이동
```

---

## 🎯 주요 특징

- **단계별 검증**: 각 단계마다 필수 데이터 검증
- **데이터 일관성**: 서버에서 모든 통계 자동 계산
- **사용자 경험**: 직관적인 UI와 실시간 피드백
- **에러 처리**: 각 단계별 에러 상황 대응
- **성능 최적화**: 필요한 데이터만 API 호출

이 시스템을 통해 사용자는 간단하고 체계적으로 경기 정보를 등록할 수 있으며, 서버에서는 복잡한 통계 계산을 자동으로 처리합니다. 
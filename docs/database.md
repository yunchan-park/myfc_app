# 데이터베이스 문서

이 문서는 My FC App의 데이터베이스 스키마, 테이블 구조, 관계에 대한 상세 정보를 제공합니다.

## 개요

My FC App은 SQLite 데이터베이스를 사용하며, SQLAlchemy ORM을 통해 관리됩니다. 데이터베이스 파일은 프로젝트 루트 디렉토리에 `myfc.db`로 위치해 있습니다.

## 테이블 구조

### teams (팀)

팀 정보를 저장하는 테이블입니다.

| 필드명 | 데이터 타입 | 설명 | 제약 조건 |
|--------|------------|------|-----------|
| id | Integer | 팀 고유 식별자 | Primary Key, Auto Increment |
| name | String | 팀 이름 | Unique, Index |
| description | String | 팀 설명 | |
| type | String | 팀 유형 | |
| password | String | 해시된 비밀번호 | |
| logo_url | String | 팀 로고 이미지 URL | Nullable |
| image_url | String | 팀 이미지 URL | Nullable |
| created_at | DateTime | 생성 일시 | Default: 현재 시간 |
| updated_at | DateTime | 수정 일시 | Update시 자동 갱신 |

### players (선수)

선수 정보를 저장하는 테이블입니다.

| 필드명 | 데이터 타입 | 설명 | 제약 조건 |
|--------|------------|------|-----------|
| id | Integer | 선수 고유 식별자 | Primary Key, Auto Increment |
| name | String | 선수 이름 | Index |
| number | Integer | 선수 번호 | |
| position | String | 선수 포지션 (FW, MF, DF, GK) | |
| team_id | Integer | 소속 팀 ID | Foreign Key(teams.id) |
| goal_count | Integer | 골 득점 수 | Default: 0 |
| assist_count | Integer | 어시스트 수 | Default: 0 |
| mom_count | Integer | MOM(Man of the Match) 횟수 | Default: 0 |
| created_at | DateTime | 생성 일시 | Default: 현재 시간 |
| updated_at | DateTime | 수정 일시 | Update시 자동 갱신 |

### matches (경기)

경기 정보를 저장하는 테이블입니다.

| 필드명 | 데이터 타입 | 설명 | 제약 조건 |
|--------|------------|------|-----------|
| id | Integer | 경기 고유 식별자 | Primary Key, Auto Increment |
| date | DateTime | 경기 일시 | |
| opponent | String | 상대팀 이름 | |
| score | String | 경기 결과 (예: "2:1") | |
| team_id | Integer | 소속 팀 ID | Foreign Key(teams.id) |
| created_at | DateTime | 생성 일시 | Default: 현재 시간 |
| updated_at | DateTime | 수정 일시 | Update시 자동 갱신 |

### match_player (경기-선수 관계)

경기와 선수 간의 다대다 관계를 저장하는 연결 테이블입니다.

| 필드명 | 데이터 타입 | 설명 | 제약 조건 |
|--------|------------|------|-----------|
| match_id | Integer | 경기 ID | Foreign Key(matches.id) |
| player_id | Integer | 선수 ID | Foreign Key(players.id) |

### goals (골)

득점 정보를 저장하는 테이블입니다.

| 필드명 | 데이터 타입 | 설명 | 제약 조건 |
|--------|------------|------|-----------|
| id | Integer | 골 고유 식별자 | Primary Key, Auto Increment |
| match_id | Integer | 경기 ID | Foreign Key(matches.id) |
| player_id | Integer | 득점 선수 ID | Foreign Key(players.id) |
| assist_player_id | Integer | 어시스트 선수 ID | Foreign Key(players.id), Nullable |
| quarter | Integer | 득점이 발생한 쿼터 | |
| created_at | DateTime | 생성 일시 | Default: 현재 시간 |
| updated_at | DateTime | 수정 일시 | Update시 자동 갱신 |

### quarter_scores (쿼터별 점수)

경기의 쿼터별 점수를 저장하는 테이블입니다.

| 필드명 | 데이터 타입 | 설명 | 제약 조건 |
|--------|------------|------|-----------|
| id | Integer | 쿼터 점수 고유 식별자 | Primary Key, Auto Increment |
| match_id | Integer | 경기 ID | Foreign Key(matches.id) |
| quarter | Integer | 쿼터 번호 | |
| our_score | Integer | 우리 팀 점수 | |
| opponent_score | Integer | 상대 팀 점수 | |
| created_at | DateTime | 생성 일시 | Default: 현재 시간 |
| updated_at | DateTime | 수정 일시 | Update시 자동 갱신 |

## 관계 구조

### 팀과 선수 (일대다)

- 한 팀은 여러 선수를 가질 수 있습니다. (1:N)
- `players.team_id` 필드가 `teams.id`를 참조합니다.

### 팀과 경기 (일대다)

- 한 팀은 여러 경기를 가질 수 있습니다. (1:N)
- `matches.team_id` 필드가 `teams.id`를 참조합니다.

### 경기와 선수 (다대다)

- 한 경기에 여러 선수가 참여할 수 있고, 한 선수는 여러 경기에 참여할 수 있습니다. (N:M)
- `match_player` 연결 테이블을 통해 관계가 설정됩니다.

### 경기와 골 (일대다)

- 한 경기에서 여러 골이 발생할 수 있습니다. (1:N)
- `goals.match_id` 필드가 `matches.id`를 참조합니다.

### 선수와 골 (일대다)

- 한 선수는 여러 골을 득점할 수 있습니다. (1:N)
- `goals.player_id` 필드가 `players.id`를 참조합니다.

### 선수와, 어시스트 (일대다)

- 한 선수는 여러 어시스트를 제공할 수 있습니다. (1:N)
- `goals.assist_player_id` 필드가 `players.id`를 참조합니다.

### 경기와 쿼터 점수 (일대다)

- 한 경기는 여러 쿼터의 점수를 가질 수 있습니다. (1:N)
- `quarter_scores.match_id` 필드가 `matches.id`를 참조합니다.

## ER 다이어그램

```
+--------+     +------------+     +---------+
|        |     |            |     |         |
| teams  +-----+ players    +-----+ goals   |
|        |     |            |     |         |
+----+---+     +------+-----+     +---------+
     |                |
     |                |
+----v----+     +-----v----+
|         |     |          |
| matches +-----+ quarter_ |
|         |     | scores   |
+---------+     +----------+
```

## 데이터베이스 관리

### 데이터베이스 초기화

데이터베이스는 애플리케이션 첫 실행 시 자동으로 초기화됩니다. 모델에 정의된 테이블이 생성되며, 기존에 데이터베이스가 없다면 새로 생성됩니다.

```python
# app/main.py
from .database import engine
from . import models

models.Base.metadata.create_all(bind=engine)
```

### 데이터베이스 세션 관리

데이터베이스 세션은 API 요청마다 생성되고 종료됩니다.

```python
# app/database.py
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

### 데이터베이스 마이그레이션

현재는 별도의 마이그레이션 도구를 사용하지 않으며, 스키마 변경 시 데이터베이스 파일을 삭제하고 다시 생성하는 방식을 사용합니다.

## 인덱스

성능 최적화를 위해 다음과 같은 인덱스가 생성되어 있습니다:

- `teams.id`
- `teams.name`
- `players.id`
- `players.name`
- `matches.id`
- `goals.id`
- `quarter_scores.id` 
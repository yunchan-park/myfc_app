# MyFC 프로젝트 문서 📚

이 디렉토리는 MyFC 축구 클럽 관리 애플리케이션의 모든 프로젝트 문서를 포함합니다.

## 📖 문서 목차

### 🏗️ **아키텍처 & 구조**
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - 시스템 아키텍처 및 설계 원칙
- **[DIRECTORY_STRUCTURE.md](DIRECTORY_STRUCTURE.md)** - 프로젝트 디렉토리 구조 상세 가이드
- **[DATA_FLOW.md](DATA_FLOW.md)** - 데이터 플로우 및 API 명세서

### 💻 **개발 가이드**
- **[BACKEND_GUIDE.md](BACKEND_GUIDE.md)** - 백엔드 서버 코드 구조 및 API 가이드
- **[FRONTEND_GUIDE.md](FRONTEND_GUIDE.md)** - 프론트엔드 Flutter 코드 구조 가이드

### 🧪 **테스트 & 품질**
- **[TESTING.md](TESTING.md)** - 테스트 실행 및 작성 가이드

## 🎯 문서 사용 가이드

### **개발자용**
1. **시작하기**: [DIRECTORY_STRUCTURE.md](DIRECTORY_STRUCTURE.md)로 프로젝트 구조 파악
2. **아키텍처 이해**: [ARCHITECTURE.md](ARCHITECTURE.md)로 시스템 설계 학습
3. **데이터 흐름 이해**: [DATA_FLOW.md](DATA_FLOW.md)로 클라이언트-서버 통신 구조 파악
4. **백엔드 개발**: [BACKEND_GUIDE.md](BACKEND_GUIDE.md)로 서버 코드 이해
5. **프론트엔드 개발**: [FRONTEND_GUIDE.md](FRONTEND_GUIDE.md)로 클라이언트 코드 이해
6. **테스트 실행**: [TESTING.md](TESTING.md)로 테스트 방법 학습

### **기획자/디자이너용**
- **전체 구조 이해**: [ARCHITECTURE.md](ARCHITECTURE.md)의 UI/UX 섹션 참조
- **프론트엔드 구조**: [FRONTEND_GUIDE.md](FRONTEND_GUIDE.md)의 Screens 및 Widgets 섹션
- **데이터 구조**: [DATA_FLOW.md](DATA_FLOW.md)의 클라이언트 데이터 관리 구조

### **API 개발자용**
- **API 명세 확인**: [DATA_FLOW.md](DATA_FLOW.md)의 REST API 명세서 섹션
- **서버 구조**: [BACKEND_GUIDE.md](BACKEND_GUIDE.md)의 API 엔드포인트 구조
- **데이터 모델**: [DATA_FLOW.md](DATA_FLOW.md)의 서버 데이터 관리 구조

### **사용자용**
- 메인 [README.md](../README.md)에서 설치 및 사용법 확인

## 📋 문서 작성 규칙

### **파일 명명 규칙**
- 모든 문서는 `UPPER_CASE.md` 형식
- 영어 대문자와 언더스코어(`_`) 사용
- 확장자는 `.md` (Markdown)

### **내용 구성**
1. **제목**: 이모지 + 명확한 제목
2. **목차**: 복잡한 문서는 TOC 포함
3. **코드 블록**: 언어 명시 (```dart, ```python, ```http)
4. **다이어그램**: Mermaid 문법 활용
5. **이미지**: 필요시 별도 `images/` 디렉토리 생성
6. **링크**: 상대 경로 사용

### **업데이트 정책**
- 새로운 기능 추가 시 관련 문서 업데이트
- 아키텍처 변경 시 ARCHITECTURE.md 수정
- API 변경 시 DATA_FLOW.md 업데이트
- UI/UX 변경 시 해당 가이드 문서 업데이트
- 코드 정리 및 최적화 시 관련 문서 갱신

## 📈 최근 업데이트 내용

### **2024 코드베이스 최적화**
- **58% 미사용 코드 제거**: 33개 → 14개 항목으로 감소
- **성능 개선**: 불필요한 임포트 및 메서드 제거
- **타입 안정성 강화**: 강화된 타입 검사 및 오류 수정
- **UI 최적화**: QuarterScoreWidget의 불필요한 편집 기능 제거

### **문서 업데이트 사항**
- **새로운 문서 추가**: [DATA_FLOW.md](DATA_FLOW.md) - 데이터 플로우 및 API 명세서
- **코드 품질 관리** 가이드라인 추가
- **`flutter analyze` 사용법** 문서화
- **성능 최적화 전략** 문서 추가
- **미사용 코드 탐지 및 제거 프로세스** 문서화

## 🔗 관련 링크

- **메인 프로젝트**: [../README.md](../README.md)
- **API 문서**: http://localhost:8000/docs (서버 실행 시)
- **GitHub Repository**: https://github.com/your-username/myfc_app
- **라이선스**: [../LICENSE](../LICENSE)

## 🛠️ 코드 품질 관리

### **정적 분석 도구**
- **Flutter**: `flutter analyze` - 코드 품질 및 미사용 코드 탐지
- **Python**: `flake8 app/` - 백엔드 코드 린팅
- **자동 최적화**: 정기적인 미사용 코드 제거

### **개발 워크플로우**
1. 코드 작성 후 `flutter analyze` 실행
2. 미사용 코드 및 임포트 제거
3. 타입 안정성 확인
4. 테스트 실행 및 커버리지 확인
5. API 문서 업데이트 ([DATA_FLOW.md](DATA_FLOW.md))
6. 관련 문서 업데이트

## 📝 기여 방법

문서 개선 사항이 있으시면:

1. 해당 문서 파일 수정
2. 명확하고 이해하기 쉬운 설명 작성
3. 스크린샷이나 다이어그램 추가 (필요시)
4. 커밋 메시지에 `docs:` 접두사 사용
5. 코드 변경 시 관련 문서도 함께 업데이트

**예시**: 
- `docs: 백엔드 가이드에 새 API 엔드포인트 추가`
- `docs: 코드 최적화 가이드라인 추가`
- `docs: 미사용 코드 제거 프로세스 문서화`
- `docs: API 명세서에 새로운 엔드포인트 추가`

### **문서 품질 기준**
- 명확하고 실행 가능한 가이드 제공
- 최신 코드베이스 상태 반영
- 개발자 경험을 고려한 구성
- 정기적인 정확성 검토
- API 변경사항 즉시 반영

---

💡 **좋은 문서는 좋은 소프트웨어의 시작입니다!** 
⚡ **최적화된 코드베이스로 더 나은 개발 경험을 제공합니다!**
📊 **상세한 API 명세서로 효율적인 개발을 지원합니다!** 
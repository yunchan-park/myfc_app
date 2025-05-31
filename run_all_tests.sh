#!/bin/bash

# MyFC App 전체 테스트 실행 스크립트

set -e  # 에러 발생 시 스크립트 중단

echo "🚀 MyFC App 전체 테스트 실행 시작"
echo "=================================="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 함수: 에러 메시지 출력
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 함수: 성공 메시지 출력
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# 함수: 정보 메시지 출력
print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# 백엔드 테스트 실행
run_backend_tests() {
    echo ""
    print_info "백엔드 API 테스트 실행 중..."
    echo "=============================="
    
    cd backend
    
    # Python 가상환경 확인
    if [ ! -d "venv" ]; then
        print_error "Python 가상환경이 없습니다. 먼저 설정해주세요."
        echo "python -m venv venv"
        echo "source venv/bin/activate  # Linux/Mac"
        echo "pip install -r requirements.txt"
        exit 1
    fi
    
    # 가상환경 활성화
    source venv/bin/activate
    
    # 의존성 설치 확인
    if ! pip show pytest > /dev/null 2>&1; then
        print_info "테스트 의존성 설치 중..."
        pip install -r requirements.txt
    fi
    
    # pytest 실행
    if python -m pytest app/tests/ -v; then
        print_success "백엔드 테스트 통과!"
    else
        print_error "백엔드 테스트 실패!"
        cd ..
        exit 1
    fi
    
    cd ..
}

# 프론트엔드 테스트 실행
run_frontend_tests() {
    echo ""
    print_info "프론트엔드 Flutter 테스트 실행 중..."
    echo "====================================="
    
    cd frontend
    
    # Flutter 프로젝트 확인
    if [ ! -f "pubspec.yaml" ]; then
        print_error "Flutter 프로젝트가 아닙니다."
        cd ..
        exit 1
    fi
    
    # Flutter 의존성 설치
    print_info "Flutter 의존성 설치 중..."
    flutter pub get
    
    # Flutter 테스트 실행
    if flutter test; then
        print_success "프론트엔드 테스트 통과!"
    else
        print_error "프론트엔드 테스트 실패!"
        cd ..
        exit 1
    fi
    
    cd ..
}

# 테스트 커버리지 생성 (선택적)
generate_coverage() {
    if [ "$1" = "--coverage" ]; then
        echo ""
        print_info "테스트 커버리지 리포트 생성 중..."
        echo "==============================="
        
        # 백엔드 커버리지
        cd backend
        source venv/bin/activate
        if command -v pytest-cov &> /dev/null; then
            python -m pytest app/tests/ --cov=app --cov-report=html:coverage_html
            print_success "백엔드 커버리지: backend/coverage_html/index.html"
        else
            print_info "pytest-cov가 설치되지 않았습니다. 백엔드 커버리지를 건너뜁니다."
        fi
        cd ..
        
        # 프론트엔드 커버리지
        cd frontend
        flutter test --coverage
        if command -v genhtml &> /dev/null; then
            genhtml coverage/lcov.info -o coverage/html
            print_success "프론트엔드 커버리지: frontend/coverage/html/index.html"
        else
            print_info "genhtml이 설치되지 않았습니다. HTML 커버리지를 건너뜁니다."
            print_success "프론트엔드 커버리지: frontend/coverage/lcov.info"
        fi
        cd ..
    fi
}

# 메인 실행
main() {
    # 명령행 인자 처리
    COVERAGE=false
    BACKEND_ONLY=false
    FRONTEND_ONLY=false
    
    for arg in "$@"; do
        case $arg in
            --coverage)
                COVERAGE=true
                shift
                ;;
            --backend-only)
                BACKEND_ONLY=true
                shift
                ;;
            --frontend-only)
                FRONTEND_ONLY=true
                shift
                ;;
            --help|-h)
                echo "사용법: $0 [옵션]"
                echo ""
                echo "옵션:"
                echo "  --coverage        테스트 커버리지 리포트 생성"
                echo "  --backend-only    백엔드 테스트만 실행"
                echo "  --frontend-only   프론트엔드 테스트만 실행"
                echo "  --help, -h        이 도움말 표시"
                exit 0
                ;;
        esac
    done
    
    # 시작 시간 기록
    start_time=$(date +%s)
    
    # 테스트 실행
    if [ "$FRONTEND_ONLY" = true ]; then
        run_frontend_tests
    elif [ "$BACKEND_ONLY" = true ]; then
        run_backend_tests
    else
        run_backend_tests
        run_frontend_tests
    fi
    
    # 커버리지 생성
    if [ "$COVERAGE" = true ]; then
        generate_coverage --coverage
    fi
    
    # 완료 시간 계산
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    echo ""
    echo "==============================="
    print_success "모든 테스트가 성공적으로 완료되었습니다! 🎉"
    print_info "실행 시간: ${duration}초"
    
    if [ "$COVERAGE" = true ]; then
        echo ""
        print_info "커버리지 리포트가 생성되었습니다:"
        echo "  - 백엔드: backend/coverage_html/index.html"
        echo "  - 프론트엔드: frontend/coverage/html/index.html"
    fi
}

# 스크립트 실행
main "$@" 
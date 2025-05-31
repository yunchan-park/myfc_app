#!/usr/bin/env python3
"""
백엔드 API 테스트 실행 스크립트

Usage:
    python run_tests.py              # 모든 테스트 실행
    python run_tests.py --unit       # 단위 테스트만 실행
    python run_tests.py --verbose    # 상세 출력
"""

import subprocess
import sys
import os
from pathlib import Path

def run_tests(test_type=None, verbose=False):
    """테스트 실행"""
    
    # 현재 디렉토리를 backend로 변경
    backend_dir = Path(__file__).parent
    os.chdir(backend_dir)
    
    # pytest 명령 구성
    cmd = ["python", "-m", "pytest"]
    
    if verbose:
        cmd.extend(["-v", "-s"])
    
    if test_type == "unit":
        cmd.extend(["-m", "not integration"])
    elif test_type == "integration":
        cmd.extend(["-m", "integration"])
    
    # 테스트 실행
    print(f"Running command: {' '.join(cmd)}")
    print("=" * 50)
    
    try:
        result = subprocess.run(cmd, check=False)
        return result.returncode
    except KeyboardInterrupt:
        print("\n테스트가 사용자에 의해 중단되었습니다.")
        return 1
    except Exception as e:
        print(f"테스트 실행 중 오류 발생: {e}")
        return 1

def main():
    """메인 함수"""
    import argparse
    
    parser = argparse.ArgumentParser(description="백엔드 API 테스트 실행")
    parser.add_argument("--unit", action="store_true", help="단위 테스트만 실행")
    parser.add_argument("--integration", action="store_true", help="통합 테스트만 실행")
    parser.add_argument("--verbose", "-v", action="store_true", help="상세 출력")
    
    args = parser.parse_args()
    
    test_type = None
    if args.unit:
        test_type = "unit"
    elif args.integration:
        test_type = "integration"
    
    # 테스트 실행
    exit_code = run_tests(test_type=test_type, verbose=args.verbose)
    sys.exit(exit_code)

if __name__ == "__main__":
    main() 
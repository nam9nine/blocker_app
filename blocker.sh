#!/bin/bash

# 정확한 디렉토리와 파일 경로 설정
SCRIPT_DIR="blocker_service"
SCRIPT_PATH="$PWD/$SCRIPT_DIR/blocker.py"
LOG_PATH="$PWD/blocker/blocker.log"
PID_PATH="$PWD/blocker/blocker.pid"
PASSWORD="secure_password"  # 비밀번호 설정

# 디렉토리와 파일 확인 및 생성
if [ ! -d "$(dirname "$LOG_PATH")" ]; then
    mkdir -p "$(dirname "$LOG_PATH")"
fi
if [ ! -f "$LOG_PATH" ]; then
    touch "$LOG_PATH"
fi
if [ ! -f "$PID_PATH" ]; then
    touch "$PID_PATH"
fi

authenticate() {
    read -sp "Enter the password to stop the service: " input_password
    echo
    if [[ "$input_password" != "$PASSWORD" ]]; then
        echo "Incorrect password. Access denied."
        exit 1
    fi
}

kill_existing_process() {
    # 실행 중인 모든 blocker.py 프로세스 검색 및 종료
    RUNNING_PIDS=$(ps aux | grep '[b]locker.py' | awk '{print $2}')
    if [[ ! -z "$RUNNING_PIDS" ]]; then
        echo "Stopping existing processes: $RUNNING_PIDS"
        # 강제 종료 시도
        echo "$RUNNING_PIDS" | xargs -r kill -9 2>/dev/null
        sleep 1  # 종료 대기

        # 남아있는 프로세스 확인 및 반복 종료
        REMAINING_PIDS=$(ps aux | grep '[b]locker.py' | awk '{print $2}')
        if [[ ! -z "$REMAINING_PIDS" ]]; then
            echo "Failed to stop some processes: $REMAINING_PIDS. Retrying..."
            echo "$REMAINING_PIDS" | xargs -r kill -9 2>/dev/null
        fi
    else
        echo "No existing blocker.py processes found."
    fi

    # PID 파일 삭제
    if [ -f "$PID_PATH" ]; then
        rm -f "$PID_PATH"
    fi
}

case "$1" in
    start)
        # 기존 PID 파일이 있으면 확인 후 중복 실행 방지
        if [ -f "$PID_PATH" ]; then
            EXISTING_PID=$(cat "$PID_PATH")
            if ps -p "$EXISTING_PID" > /dev/null 2>&1; then
                echo "Blocker is already running with PID $EXISTING_PID."
                exit 1
            else
                echo "PID file exists, but process is not running. Cleaning up."
                rm -f "$PID_PATH"
            fi
        fi
        kill_existing_process  # 기존 프로세스 종료
        echo "Starting blocker..."
        python3 "$SCRIPT_PATH" > "$LOG_PATH" 2>&1 &  # sudo 제거
        NEW_PID=$!
        echo "$NEW_PID" > "$PID_PATH"
        echo "Blocker started with PID $NEW_PID"
        ;;
    stop)
        authenticate
        kill_existing_process
        echo "Blocker stopped."
        ;;
    status)
        if [ -f "$PID_PATH" ]; then
            EXISTING_PID=$(cat "$PID_PATH")
            if ps -p "$EXISTING_PID" > /dev/null 2>&1; then
                echo "Blocker is running with PID $EXISTING_PID"
            else
                echo "PID file exists, but process is not running. Cleaning up."
                rm -f "$PID_PATH"
            fi
        else
            echo "Blocker is not running."
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        ;;
esac

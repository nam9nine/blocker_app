import os
import sys
import time
import getpass
import fcntl

PASSWORD = "secure_password"  # 비밀번호 설정
LOCK_FILE = "/tmp/blocker.lock"

def authenticate():
    """사용자에게 비밀번호를 입력받아 인증."""
    user_input = getpass.getpass("Enter the password to stop the service: ")
    if user_input != PASSWORD:
        print("Incorrect password. Access denied.")
        return False
    return True

def block_sites():
    """유튜브를 차단하는 함수."""
    with open("/etc/hosts", "a") as file:
        file.write("127.0.0.1 youtube.com\n")
        file.write("127.0.0.1 www.youtube.com\n")

def unblock_sites():
    """유튜브 차단을 해제하는 함수."""
    with open("/etc/hosts", "r") as file:
        lines = file.readlines()
    with open("/etc/hosts", "w") as file:
        for line in lines:
            if not ("youtube.com" in line or "www.youtube.com" in line):
                file.write(line)

def main_loop():
    try:
        while True:
            current_hour = time.localtime().tm_hour
            if 0 <= current_hour < 18:  # 오전 9시 ~ 오후 6시 차단
                block_sites()
            else:
                unblock_sites()
            time.sleep(300)  # 5분마다 실행
    except KeyboardInterrupt:
        if authenticate():
            print("Exiting gracefully...")
            unblock_sites()
            sys.exit(0)
        else:
            print("Unauthorized exit attempt.")
            main_loop()

if __name__ == "__main__":
    # 파일 기반 락 생성
    lock_fd = open(LOCK_FILE, 'w')
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        print("Another instance is already running.")
        sys.exit(1)
    
    main_loop()

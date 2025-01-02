import getpass

PASSWORD = "secure_password"  # 비밀번호 설정

def authenticate():
    """사용자에게 비밀번호를 입력받아 인증."""
    user_input = getpass.getpass("Enter the password to stop the service: ")
    if user_input != PASSWORD:
        print("Incorrect password. Access denied.")
        return False
    return True

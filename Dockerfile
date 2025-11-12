# 공식 Python 이미지 사용
FROM python:3.11-slim

# 작업 디렉토리 설정
WORKDIR /app

# 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 애플리케이션 코드 복사
COPY . .

# Cloud Run이 사용할 포트 (기본 8080) 명시
EXPOSE 8080

# 애플리케이션 시작 명령어
CMD ["python", "main.py"]
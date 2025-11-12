네, 현재까지 GCP Vertex AI Workbench 환경에서 성공적으로 수행하신 Docker 기반의 "Hello World" 웹 애플리케이션 프로젝트에 대한 **README.md** 파일을 정리해 드립니다.

이 문서는 프로젝트 개요, 환경 설정, 개발 및 배포 지침을 포함하여 다른 사용자가 프로젝트를 쉽게 이해하고 재현할 수 있도록 구성되었습니다.

---

# **🌐 Hello World Web App (Cloud Run on GCP)**

##  **1. 프로젝트 개요**

이 프로젝트는 **Python Flask** 웹 애플리케이션을 **Docker 컨테이너**로 패키징하여, Google Cloud Platform (GCP)의 **Vertex AI Workbench**에서 개발하고 **Cloud Run** 서버리스 환경에 배포하는 기본 예제입니다.

* **애플리케이션:** Flask 기반의 단순 "Hello World" 출력 서버.  
* **플랫폼:** GCP Vertex AI Workbench (JupyterLab) 및 Cloud Run.  
* **목표:** 클라우드 환경에서 컨테이너 기반 웹 서비스의 빌드, 배포, 접근 권한 설정 과정을 학습합니다.

---

## **2. 개발 환경 설정 및 준비**

### **2.1. GCP 환경 설정**

1. **GCP 프로젝트:** 활성화된 프로젝트 ID가 필요합니다. (gen-lang-client-0936807374)  
2. **개발 환경:** **Vertex AI Workbench 인스턴스** (관리형 JupyterLab 환경)를 사용합니다.  
3. **API 활성화:** 다음 필수 API가 활성화되어 있어야 합니다.  
   * **Artifact Registry API** (artifactregistry.googleapis.com)  
   * **Cloud Run API** (run.googleapis.com)

### **2.2. 로컬 파일 구조**

프로젝트 폴더 (~/helloworld) 내에 다음 세 파일이 존재해야 합니다.

helloworld/  
├── main.py             # Flask 애플리케이션 코드  
├── requirements.txt    # Python 의존성 목록  
└── Dockerfile          # Docker 이미지 빌드 명령어

---

## **3. 애플리케이션 소스 코드**

### **3.1. main.py (Flask App)**

  Python

from flask import Flask
import os

app = Flask(__name__)

# Cloud Run은 환경 변수 PORT를 사용하며, 기본값은 8080입니다.
PORT = int(os.environ.get("PORT", 8080))

@app.route("/")
def hello_world():
    return "Hello World! from GCP Cloud Run"

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=PORT)

### **3.2. requirements.txt**

      Plaintext

   flask

### **3.3. Dockerfile**

    Dockerfile

# 공식 Python 이미지 사용  
FROM python:3.11-slim

# 작업 디렉토리 설정  
WORKDIR /app

# 의존성 설치  
COPY requirements.txt .  
RUN pip install --no-cache-dir -r requirements.txt

# 애플리케이션 코드 복사  
COPY . .

# Cloud Run이 사용할 포트 (기본 8080\) 명시  
EXPOSE 8080

# 애플리케이션 시작 명령어  
CMD ["python", "main.py"]

---

## **4. 빌드 및 배포 지침**

다음 명령어는 Vertex AI Workbench 터미널에서 ~/helloworld 디렉토리 내에서 실행해야 합니다.

### **4.1. 환경 변수 설정**

Bash

PROJECT_ID=$(gcloud config get-value project)  
REGION="us-central1" # 배포 리전  
IMAGE_NAME=$REGION-docker.pkg.dev/$PROJECT_ID/cloud-run-source-deploy/helloworld:latest

echo "Project ID: $PROJECT_ID"
echo "Image Name: $IMAGE_NAME"

### **4.2. API 활성화: (Service Usage API와 Artifact Registry API를 활성화)**

Bash

gcloud services enable serviceusage.googleapis.com
gcloud services enable artifactregistry.googleapis.com

### **4.3. Docker 이미지 빌드 및 푸시**

1. **Artifact Registry 저장소 생성 (최초 1회):**  
   Bash  
   gcloud artifacts repositories create cloud-run-source-deploy \  
       --repository-format=docker \  
       --location=$REGION \  
       --description="Repository for Cloud Run deployments"

2. **이미지 빌드 및 인증/푸시:**  
   Bash  
   
   # Docker Image 빌드 
   docker build -t $IMAGE_NAME . 
   # Artifact Registry 인증: (Docker가 GCP에 로그인하여 푸시할 수 있도록 설정)
   gcloud auth configure-docker $REGION-docker.pkg.dev  
   # Docker 이미지 푸시 (업로드) 
   docker push $IMAGE_NAME

3. 로컬 컨테이너 실행 및 상태 확인 
 1) 기존 컨테이너 정리
   # (선택 사항) 이상한  컨테이너 ID를 찾아서 삭제합니다.
   # docker rm [CONTAINer_ID_1] [CONTAINer_ID_2] ...
 2) 컨테이너 실행: (포트 충돌을 피하기 위해 8088 포트로 실행합니다.) 
   docker run -d -p 8088:8080 $IMAGE_NAME 
 3) 실행 상태 확인 
   docker ps # STATUS가 'Up'인지 확인
 4) 로컬 접속 확인 : 웹 브라우저에서 다음 주소로 접속하여 "Hello World!" 메시지가 출력되는지 확인   
    https://[JupyterLab 호스트 주소]/proxy/8088/ 
 
 
### **4.4. Cloud Run 배포**
로컬 테스트에 성공했으므로, 이제 Artifact Registry에 푸시된 이미지를 사용하여 Cloud Run에 배포만 남았습니다.
다음 명령을 실행하여 서비스를 인터넷에 공개적으로 배포할 수 있습니다.
Bash

# Cloud Run 서비스 배포 (공개 접근 허용)
gcloud run deploy helloworld-service \
    --image $IMAGE_NAME \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --project $PROJECT_ID

---상기 실행후에 출력되는 터미널의 마지막에 출력되는 "Service URL"이 최종 웹 주소입니다. 이 주소로 접속하면 GCP 클라우드에서 실행되는 "Hello World" 앱을 볼 수 있습니다.
  . 예시: Service URL: https://helloworld-service-469683173389.us-central1.run.app


## **5. 배포 후 문제 해결 및 최종 확인**

배포 후 웹 접근 시 Error: Forbidden 오류가 발생하면, 다음 단계를 통해 공개 접근 권한을 수동으로 설정해야 합니다.
"Error: Forbidden
Your client does not have permission to get URL / from this server." 


### **5.1. IAM 권한 설정 오류 해결**

Cloud Run 서비스의 IAM 정책을 수정할 권한이 있는 계정(일반적으로 GCP Console의 사용자 계정)으로 **GCP Console**에 접속하여 다음 조치를 수행합니다.

1. **서비스 계정에 권한 부여:**  
   * "IAM 및 관리자"로 이동합니다.  
   * Workbench의 서비스 계정 ([PROJECT_NUMBER]-compute@developer.gserviceaccount.com)에 Cloud Run 관리자 (roles/run.admin) 역할을 부여합니다.  
   
2. 공개 접근 권한 수동 설정 (터미널에서 재시도):  
   권한 부여 후 터미널로 돌아와 다음 명령을 실행합니다.  
   Bash  
   gcloud beta run services add-iam-policy-binding helloworld-service \
    --region=$REGION \
    --member=allUsers \
    --role=roles/run.invoker

### **5.2. 최종 서비스 접속 확인**

위 명령이 성공적으로 완료되면, Cloud Run 배포 시 출력된 "Service URL"에 접속하여 **"Hello World! from GCP Cloud Run"** 메시지를 최종적으로 확인할 수 있습니다. 
  Service URL: https://helloworld-service-469683173389.us-central1.run.app





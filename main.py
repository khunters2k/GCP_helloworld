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
    
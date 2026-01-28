from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route("/")
def health():
    return jsonify(
        status="ok",
        service="python-eks-app",
        env=os.getenv("ENV", "dev")
    )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)


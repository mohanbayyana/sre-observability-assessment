from flask import Flask, jsonify
import logging
import time

app = Flask(__name__)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s"
)


@app.route("/")
def home():
    app.logger.info("Home endpoint called")
    return jsonify(
        application="sre-observability-app",
        status="running"
    )


@app.route("/health")
def health():
    return jsonify(status="healthy"), 200


@app.route("/ready")
def ready():
    return jsonify(status="ready"), 200


@app.route("/slow")
def slow():
    app.logger.info("Slow endpoint called")
    time.sleep(2)
    return jsonify(status="completed", delay_seconds=2), 200


@app.route("/error")
def error():
    app.logger.error("Intentional error endpoint called")
    return jsonify(error="intentional test error"), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)

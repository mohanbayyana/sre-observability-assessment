from flask import Flask, jsonify, request
import logging
import time

from prometheus_client import (
    CONTENT_TYPE_LATEST,
    Counter,
    Histogram,
    generate_latest,
)

app = Flask(__name__)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s"
)

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"]
)

REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "endpoint"]
)


@app.before_request
def start_timer():
    request.start_time = time.time()


@app.after_request
def record_metrics(response):
    if request.path != "/metrics":
        duration = time.time() - request.start_time

        REQUEST_COUNT.labels(
            method=request.method,
            endpoint=request.path,
            status=response.status_code
        ).inc()

        REQUEST_LATENCY.labels(
            method=request.method,
            endpoint=request.path
        ).observe(duration)

    return response


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


@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {
        "Content-Type": CONTENT_TYPE_LATEST
    }


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
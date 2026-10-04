FROM python:3.13-slim AS builder

WORKDIR /app

COPY requirements.txt .

RUN python -m pip install \
    --no-cache-dir \
    --prefix=/install \
    -r requirements.txt


FROM python:3.13-slim

WORKDIR /app

RUN apt-get update \
    && apt-get upgrade -y \
    && python -m pip uninstall -y pip setuptools wheel \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /install /usr/local

COPY app.py .

RUN groupadd --gid 10001 appgroup \
    && useradd \
       --uid 10001 \
       --gid 10001 \
       --create-home \
       appuser

USER 10001:10001

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]

FROM python:3.13-slim

WORKDIR /app

RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN python -m pip install --no-cache-dir --upgrade \
      pip \
      "setuptools>=78.1.1" \
    && python -m pip install --no-cache-dir -r requirements.txt \
    && python -m pip install --no-cache-dir \
      "msgpack>=1.2.1" \
      "urllib3>=2.8.0"

COPY app.py .

RUN groupadd --gid 10001 appgroup \
    && useradd --uid 10001 \
       --gid 10001 \
       --create-home \
       appuser

USER 10001:10001

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
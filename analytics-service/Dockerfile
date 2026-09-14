# Stage 1 (BUILD)
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2 (RUN)
FROM python:3.12-slim

# Patch OS packages at build time rather than trusting the upstream base
# image tag to already be freshly rebuilt (Debian security fixes land
# ahead of Docker Hub's next scheduled image rebuild).
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos "" appuser
WORKDIR /app

COPY --from=builder /install /usr/local
COPY --chown=appuser:appuser app.py .

USER appuser

EXPOSE 8005

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8005/health')"

CMD ["gunicorn", "--bind", "0.0.0.0:8005", "app:app"]

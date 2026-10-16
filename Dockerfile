FROM python:3.11-alpine AS builder

RUN apk update && apk upgrade --no-cache libcrypto3 libssl3
RUN apk add --no-cache alpine-sdk linux-headers
RUN pip install poetry==1.8.5

WORKDIR /app

COPY pyproject.toml poetry.toml poetry.lock README.md ./
RUN poetry install --no-interaction --no-ansi --no-cache --no-root --no-directory --only main --compile

COPY ./aidial_code_interpreter ./aidial_code_interpreter
RUN poetry install --no-interaction --no-ansi --no-cache --only main --compile
# fix CVEs in pip and setuptools (incl. vendored jaraco.context and wheel) bundled into the venv
RUN /app/.venv/bin/python -m pip install --no-cache-dir --upgrade pip==26.2.1 setuptools==83.0.0

FROM python:3.11-alpine AS server

RUN apk update && apk upgrade --no-cache libcrypto3 libssl3
# fix CVE-2026-85091
RUN apk upgrade --no-cache zlib

# fix CVE-2023-52425
RUN apk upgrade --no-cache libexpat
# fix CVE-2025-6965
RUN apk upgrade --no-cache sqlite-libs
# OpenMP runtime required by scikit-learn (import fails without libgomp.so.1)
RUN apk add --no-cache libgomp
# fix CVE-2025-47273, CVE-2026-59890 and CVEs in pip, vendored jaraco.context and wheel
RUN pip install --no-cache-dir --upgrade pip==26.2.1 setuptools==83.0.0

RUN adduser -u 1001 --disabled-password --gecos "" appuser
COPY --chown=appuser --from=builder /app /app

COPY ./entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

RUN mkdir /mnt/data && chown appuser /mnt/data
WORKDIR /mnt/data

USER appuser
EXPOSE 8080

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYDEVD_DISABLE_FILE_VALIDATION=1

ENTRYPOINT ["/app/entrypoint.sh"]
CMD uvicorn aidial_code_interpreter.app:app --app-dir /app --host 0.0.0.0 --port 8080 --timeout-keep-alive ${TIMEOUT_KEEP_ALIVE:-60}
FROM python:3.11-alpine AS builder

RUN apk update && apk upgrade --no-cache libcrypto3 libssl3
RUN apk add --no-cache alpine-sdk linux-headers
RUN pip install poetry==1.8.5

WORKDIR /app

# app venv is shipped to runtime: do not seed pip/setuptools into it
ENV VIRTUALENV_NO_PIP=1 VIRTUALENV_NO_SETUPTOOLS=1

COPY pyproject.toml poetry.toml poetry.lock README.md ./
RUN poetry install --no-interaction --no-ansi --no-cache --no-root --no-directory --only main --compile

COPY ./aidial_code_interpreter ./aidial_code_interpreter
RUN poetry install --no-interaction --no-ansi --no-cache --only main --compile

FROM python:3.11-alpine AS server

RUN apk update && apk upgrade --no-cache libcrypto3 libssl3
# fix CVE-2026-85091
RUN apk upgrade --no-cache zlib

# fix CVE-2023-52425
RUN apk upgrade --no-cache libexpat
# fix CVE-2025-6965
RUN apk upgrade --no-cache sqlite-libs
# C++/OpenMP runtimes required by scikit-learn (imports fail without libgomp.so.1 / libstdc++.so.6)
RUN apk add --no-cache libgomp libstdc++
# pip and setuptools are not needed at runtime (the service and kernel use /app/.venv, which has none)
RUN python -m pip uninstall -y pip setuptools

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
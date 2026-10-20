FROM python:3.11-alpine AS builder

RUN apk update && apk upgrade --no-cache libcrypto3 libssl3
RUN apk add --no-cache alpine-sdk linux-headers
RUN pip install poetry==1.8.5

WORKDIR /app

# app venv is shipped to runtime: keep pip and setuptools out of it (CVE-2025-47273,
# CVE-2026-59890 and the vendored urllib3/msgpack CVEs CVE-2026-97687/97688/97689, GHSA-6v7p-g79w-8964)
ENV VIRTUALENV_NO_PIP=1 VIRTUALENV_NO_SETUPTOOLS=1

COPY pyproject.toml poetry.toml poetry.lock README.md ./
RUN poetry install --no-interaction --no-ansi --no-cache --no-root --no-directory --only main --compile

COPY ./aidial_code_interpreter ./aidial_code_interpreter
RUN poetry install --no-interaction --no-ansi --no-cache --only main --compile
# fail the build if pip or setuptools end up in the app venv (they are not needed at runtime)
RUN /app/.venv/bin/python -c "import importlib.util as u, sys; sys.exit(any(u.find_spec(m) for m in ('pip', 'setuptools')))"

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
# remove pip and setuptools from the system interpreter: clears CVE-2025-47273 and CVE-2026-59890,
# and the vendored urllib3/msgpack copies (CVE-2026-97687/97688/97689, GHSA-6v7p-g79w-8964).
# Not needed at runtime: the service and kernel use /app/.venv.
# ensurepip is removed too: its bundled pip/setuptools wheels would let `python -m ensurepip` restore them
RUN python -m pip uninstall -y pip setuptools && \
    rm -r /usr/local/lib/python3.11/ensurepip

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
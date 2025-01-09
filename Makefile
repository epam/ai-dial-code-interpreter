IMAGE_NAME ?= ai-dial-code-interpreter
VENV ?= .venv
PYTHON_VERSION ?= 3.11
POETRY ?= ${VENV}/bin/poetry
POETRY_VERSION ?= 1.8.5

.PHONY: all init_env install build test clean lint format

all: build

init_env:
	python$(PYTHON_VERSION) -m venv ${VENV}
	${VENV}/bin/pip install poetry==${POETRY_VERSION} --quiet

install: init_env
	${POETRY} env use python$(PYTHON_VERSION)
	${POETRY} install

build: install
	${POETRY} build

test:
	@echo "No tests yet"

clean:
	${POETRY} env remove --all

lint: install
	${POETRY} run nox -s lint

format: install
	${POETRY} run nox -s format

help:
	@echo "===================="
	@echo "build                        - build the source and wheels archives"
	@echo "clean                        - clean virtual env and build artifacts"
	@echo "-- LINTING --"
	@echo "format                       - run code formatters"
	@echo "lint                         - run linters"
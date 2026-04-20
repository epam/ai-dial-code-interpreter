ARGS ?=
POETRY ?= poetry
POETRY_PYTHON ?= python
VENV_DIR ?= .venv

-include .env.dev
export

.PHONY: all init_env install build test clean lint format

all: build

init_env:
	$(POETRY) env use $(POETRY_PYTHON)

install: init_env
	$(POETRY) install

build: install
	$(POETRY) build

lint: install
	$(POETRY) run nox -s lint

format: install
	${POETRY} run nox -s format

test: install
	echo "No tests yet"

clean:
	${POETRY} env remove --all

help:
	@echo '===================='
	@echo 'build                        - build the source and wheels archives'
	@echo 'clean                        - clean virtual env and build artifacts'
	@echo '-- LINTING --'
	@echo 'format                       - run code formatters'
	@echo 'lint                         - run linters'
	@echo '-- TESTS --'
	@echo 'test                         - run tests'
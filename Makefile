default: help

PROJECT_NAME=$(shell basename "$(PWD)")
OUTPUT_FOLDER=out

BLUE=\033[1;30;44m
YELLOW=\033[1;30;43m
RED=\033[1;30;41m
NC=\033[0m

## test: Run all tests
test:
	@echo "${BLUE} I ${NC} Running tests..."
	@busted --pattern=_spec spec/

## test: Run tests with verbose output
test-verbose:
	@echo "${BLUE} I ${NC} Running tests (verbose)..."
	@busted --verbose --pattern=_spec spec/

## watch: Run tests in watch mode
watch:
	@if ! command -v entr &> /dev/null; then \
		echo "${RED} E ${NC} 'entr' command not found. Please install it to use watch mode."; \
		exit 1; \
	fi
	@echo "Running tests in watch mode (press Ctrl+C to stop)..."
	@find lua/ spec/ -name "*.lua" | entr -c make test

.PHONY: help test
all: help
help: Makefile
	@echo
	@echo " Choose a command run in "${PROJECT_NAME}":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo

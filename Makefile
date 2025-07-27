# Claudetainer Makefile
# Provides build, test, and lint targets for the Claudetainer project

# Shell to use for commands
SHELL := /bin/bash

.PHONY: help build test lint fmt clean install uninstall dev check prereqs all test-cli test-feature test-lifecycle smoke-test dist

# Default target
.DEFAULT_GOAL := help

# Colors for output (macOS compatible)
RED    := \033[31m
GREEN  := \033[32m
YELLOW := \033[33m
BLUE   := \033[34m
RESET  := \033[0m

# Project configuration
NAME := claudetainer
PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin

BUILD_DIR := dist
CLI_OUTPUT := $(BUILD_DIR)/$(NAME)
BIN_DIR := bin
LIB_DIR := $(BIN_DIR)/lib
CMD_DIR := $(BIN_DIR)/commands
SRC_DIR := src/claudetainer
TEST_DIR := test/claudetainer

# Get version from devcontainer-feature.json
VERSION := $(shell node -e "console.log(JSON.parse(require('fs').readFileSync('$(SRC_DIR)/devcontainer-feature.json', 'utf8')).version)" 2>/dev/null || echo "unknown")

## help: Show this help message
help:
	@echo -e "$(BLUE)Claudetainer Development Commands$(RESET)"
	@echo "================================="
	@echo ""
	@echo -e "$(GREEN)Main Targets:$(RESET)"
	@echo -e "  $(YELLOW)build$(RESET)     - Build single-file CLI distribution"
	@echo -e "  $(YELLOW)test$(RESET)      - Run all tests (CLI + DevContainer feature)"
	@echo -e "  $(YELLOW)lint$(RESET)      - Run all linting checks"
	@echo -e "  $(YELLOW)fmt$(RESET)       - Format shell scripts"
	@echo -e "  $(YELLOW)clean$(RESET)     - Clean build artifacts"
	@echo ""
	@echo -e "$(GREEN)Development:$(RESET)"
	@echo -e "  $(YELLOW)dev$(RESET)       - Quick development check (lint + test-cli)"
	@echo -e "  $(YELLOW)check$(RESET)     - Comprehensive check (lint + test + build)"
	@echo -e "  $(YELLOW)all$(RESET)       - Complete build, test, and validation cycle"
	@echo -e "  $(YELLOW)prereqs$(RESET)   - Check development prerequisites"
	@echo ""
	@echo -e "$(GREEN)Testing:$(RESET)"
	@echo -e "  $(YELLOW)test-cli$(RESET)      - Test CLI functionality (modular + built)"
	@echo -e "  $(YELLOW)test-feature$(RESET)  - Test DevContainer feature"
	@echo -e "  $(YELLOW)test-lifecycle$(RESET) - Test CLI full lifecycle (external)"
	@echo -e "  $(YELLOW)smoke-test$(RESET)    - Quick smoke test of CLI"
	@echo ""
	@echo -e "$(GREEN)Installation:$(RESET)"
	@echo -e "  $(YELLOW)install$(RESET)   - Install CLI to $(BINDIR)"
	@echo -e "  $(YELLOW)uninstall$(RESET) - Remove CLI from $(BINDIR)"
	@echo -e "  $(YELLOW)dist$(RESET)      - Create distribution package"
	@echo ""
	@echo -e "$(GREEN)Current version:$(RESET) $(VERSION)"
	@echo ""

## prereqs: Check development prerequisites
prereqs:
	@echo -e "$(BLUE)🔍 Checking development prerequisites...$(RESET)"
	@command -v node >/dev/null 2>&1 || (echo -e "$(RED)❌ Node.js not found$(RESET)" && exit 1)
	@command -v shellcheck >/dev/null 2>&1 || echo -e "$(YELLOW)⚠️  shellcheck not found (install with: brew install shellcheck)$(RESET)"
	@command -v shfmt >/dev/null 2>&1 || echo -e "$(YELLOW)⚠️  shfmt not found (install with: brew install shfmt)$(RESET)"
	@test -f "$(SRC_DIR)/devcontainer-feature.json" || (echo -e "$(RED)❌ devcontainer-feature.json not found$(RESET)" && exit 1)
	@echo -e "$(GREEN)✅ Core prerequisites met$(RESET)"
	@echo -e "$(BLUE)ℹ️  Optional tools: shellcheck, shfmt for enhanced linting$(RESET)"

## build: Build single-file CLI distribution
build: prereqs
	@echo -e "$(BLUE)🔨 Building claudetainer v$(VERSION)...$(RESET)"
	@./build.sh
	@echo -e "$(GREEN)✅ Build complete: $(CLI_OUTPUT)$(RESET)"

## test-cli: Test CLI functionality (both modular and built versions)
test-cli:
	@echo -e "$(BLUE)🧪 Testing CLI functionality...$(RESET)"
	@echo -e "$(YELLOW)Testing modular version...$(RESET)"
	@./$(BIN_DIR)/claudetainer --version >/dev/null || (echo -e "$(RED)❌ Modular CLI test failed$(RESET)" && exit 1)
	@./$(BIN_DIR)/claudetainer --help >/dev/null || (echo -e "$(RED)❌ Modular CLI help failed$(RESET)" && exit 1)
	@echo -e "$(GREEN)✅ Modular CLI tests passed$(RESET)"
	
	@if [ -f "$(CLI_OUTPUT)" ]; then \
		echo -e "$(YELLOW)Testing built version...$(RESET)"; \
		./$(CLI_OUTPUT) --version >/dev/null || (echo -e "$(RED)❌ Built CLI test failed$(RESET)" && exit 1); \
		./$(CLI_OUTPUT) --help >/dev/null || (echo -e "$(RED)❌ Built CLI help failed$(RESET)" && exit 1); \
		echo -e "$(GREEN)✅ Built CLI tests passed$(RESET)"; \
	else \
		echo -e "$(YELLOW)⚠️  Built CLI not found, run 'make build' first$(RESET)"; \
	fi

## test-feature: Test DevContainer feature using DevContainer CLI
test-feature:
	@echo -e "$(BLUE)🧪 Testing DevContainer feature...$(RESET)"
	@if command -v devcontainer >/dev/null 2>&1; then \
		echo -e "$(YELLOW)Running DevContainer feature tests...$(RESET)"; \
		devcontainer features test .; \
		echo -e "$(GREEN)✅ DevContainer feature tests passed$(RESET)"; \
	else \
		echo -e "$(YELLOW)⚠️  DevContainer CLI not found$(RESET)"; \
		echo -e "$(BLUE)ℹ️  Install with: npm install -g @devcontainers/cli$(RESET)"; \
		echo -e "$(BLUE)ℹ️  Running basic test script instead...$(RESET)"; \
		cd $(TEST_DIR) && bash test.sh; \
	fi

## test-lifecycle: Test CLI full lifecycle (external test)
test-lifecycle:
	@echo -e "$(BLUE)🧪 Testing CLI full lifecycle...$(RESET)"
	@./cli_test/lifecycle.sh ./$(BIN_DIR)/claudetainer
	@echo -e "$(GREEN)✅ CLI lifecycle test completed$(RESET)"

## test: Run all tests
test: test-cli test-feature test-lifecycle
	@echo -e "$(GREEN)✅ All tests completed$(RESET)"

## smoke-test: Quick smoke test of CLI
smoke-test:
	@echo -e "$(BLUE)🚀 Running smoke test...$(RESET)"
	@./$(BIN_DIR)/claudetainer --version
	@./$(BIN_DIR)/claudetainer --help | head -5
	@./$(BIN_DIR)/claudetainer prereqs || true
	@echo -e "$(GREEN)✅ Smoke test complete$(RESET)"

## lint: Run all linting checks
lint:
	@echo -e "$(BLUE)🔍 Running linting checks...$(RESET)"
	@$(MAKE) lint-shellcheck
	@$(MAKE) lint-shfmt
	@$(MAKE) lint-scripts
	@$(MAKE) lint-json
	@echo -e "$(GREEN)✅ All linting checks passed$(RESET)"

# Internal lint targets
lint-shellcheck:
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo -e "$(YELLOW)Running shellcheck...$(RESET)"; \
		find . -name "*.sh" -not -path "./dist/*" -not -path "./node_modules/*" | xargs shellcheck -e SC1091,SC2034; \
		echo -e "$(GREEN)✅ shellcheck passed$(RESET)"; \
	else \
		echo -e "$(YELLOW)⚠️  shellcheck not available, skipping$(RESET)"; \
	fi

lint-shfmt:
	@if command -v shfmt >/dev/null 2>&1; then \
		echo -e "$(YELLOW)Checking shell script formatting...$(RESET)"; \
		if ! find . -name "*.sh" -not -path "./dist/*" -not -path "./node_modules/*" | xargs shfmt -d >/dev/null 2>&1; then \
			echo -e "$(RED)❌ Shell scripts need formatting$(RESET)"; \
			echo -e "$(BLUE)ℹ️  Run 'make fmt' to fix formatting$(RESET)"; \
			exit 1; \
		fi; \
		echo -e "$(GREEN)✅ Shell script formatting is correct$(RESET)"; \
	else \
		echo -e "$(YELLOW)⚠️  shfmt not available, skipping format check$(RESET)"; \
	fi

lint-scripts:
	@echo -e "$(YELLOW)Checking script permissions...$(RESET)"
	@find . -name "*.sh" -not -path "./dist/*" -not -path "./node_modules/*" -exec test ! -x {} \; -print | while read -r file; do \
		echo -e "$(YELLOW)⚠️  Script not executable: $$file$(RESET)"; \
	done || true
	@echo -e "$(GREEN)✅ Script permissions checked$(RESET)"

lint-json:
	@echo -e "$(YELLOW)Validating JSON files...$(RESET)"
	@find . -name "*.json" -not -path "./dist/*" -not -path "./node_modules/*" | while read -r file; do \
		if ! node -e "JSON.parse(require('fs').readFileSync('$$file', 'utf8'))" 2>/dev/null; then \
			echo -e "$(RED)❌ Invalid JSON: $$file$(RESET)"; \
			exit 1; \
		fi; \
	done
	@echo -e "$(GREEN)✅ JSON validation passed$(RESET)"

## fmt: Format shell scripts using EditorConfig
fmt:
	@if command -v shfmt >/dev/null 2>&1; then \
		echo -e "$(BLUE)🎨 Formatting shell scripts with EditorConfig...$(RESET)"; \
		find . -name "*.sh" -not -path "./dist/*" -not -path "./node_modules/*" | xargs shfmt -w; \
		echo -e "$(GREEN)✅ Formatting complete$(RESET)"; \
	else \
		echo -e "$(YELLOW)⚠️  shfmt not available$(RESET)"; \
		echo -e "$(BLUE)ℹ️  Install with: brew install shfmt$(RESET)"; \
	fi

## clean: Clean build artifacts
clean:
	@echo -e "$(BLUE)🧹 Cleaning build artifacts...$(RESET)"
	@rm -rf $(BUILD_DIR)
	@rm -f *.log
	@echo -e "$(GREEN)✅ Clean complete$(RESET)"

## install: Install built CLI to system
install: build
	@echo -e "$(BLUE)📦 Installing $(NAME) to $(BINDIR)...$(RESET)"
	@if [ ! -f "$(CLI_OUTPUT)" ]; then \
		echo -e "$(RED)❌ Built CLI not found, run 'make build' first$(RESET)"; \
		exit 1; \
	fi
	@install -d "$(BINDIR)"
	@install -m 755 "$(CLI_OUTPUT)" "$(BINDIR)/$(NAME)"
	@echo -e "$(GREEN)✅ Installed: $(BINDIR)/$(NAME)$(RESET)"
	@echo -e "$(BLUE)ℹ️  Test with: $(NAME) --version$(RESET)"

## uninstall: Remove installed CLI
uninstall:
	@echo -e "$(BLUE)🗑️  Removing $(NAME) from $(BINDIR)...$(RESET)"
	@if [ -f "$(BINDIR)/$(NAME)" ]; then \
		rm -f "$(BINDIR)/$(NAME)"; \
		echo -e "$(GREEN)✅ Uninstalled: $(BINDIR)/$(NAME)$(RESET)"; \
	else \
		echo -e "$(YELLOW)⚠️  $(NAME) not found in $(BINDIR)$(RESET)"; \
	fi

## dev: Quick development check (lint + test-cli)
dev: lint test-cli
	@echo -e "$(GREEN)✅ Development check complete$(RESET)"

## check: Comprehensive check (lint + test + build)
check: prereqs lint test build
	@echo -e "$(GREEN)🎉 All checks passed! Ready for commit.$(RESET)"

## dist: Create distribution package
dist: build
	@echo -e "$(BLUE)📦 Creating distribution package...$(RESET)"
	@cp "$(CLI_OUTPUT)" "$(BUILD_DIR)/$(NAME)-$(VERSION)"
	@echo -e "$(GREEN)✅ Distribution created: $(BUILD_DIR)/$(NAME)-$(VERSION)$(RESET)"

## all: Complete build, test, and validation
all: clean prereqs lint test build
	@echo -e "$(GREEN)🎉 Complete build and test cycle finished!$(RESET)"

# Development utilities
.PHONY: version info debug

## version: Show version information
version:
	@echo -e "Claudetainer version: $(VERSION)"
	@echo -e "Node.js: $(shell node --version 2>/dev/null || echo 'not found')"
	@echo -e "Build dir: $(BUILD_DIR)"
	@echo -e "CLI output: $(CLI_OUTPUT)"

## info: Show project information
info:
	@echo -e "$(BLUE)Claudetainer Project Information$(RESET)"
	@echo "==============================="
	@echo -e "Version: $(VERSION)"
	@echo -e "Modular CLI: $(BIN_DIR)/claudetainer"
	@echo -e "Built CLI: $(CLI_OUTPUT)"
	@echo -e "Libraries: $(shell find $(LIB_DIR) -name "*.sh" 2>/dev/null | wc -l || echo 0) files"
	@echo -e "Commands: $(shell find $(CMD_DIR) -name "*.sh" 2>/dev/null | wc -l || echo 0) files"
	@echo -e "Presets: $(shell find $(SRC_DIR)/presets -name "metadata.json" 2>/dev/null | wc -l || echo 0) available"
	@echo -e "DevContainer Tests: $(shell find $(TEST_DIR) -name "*.sh" 2>/dev/null | wc -l || echo 0) scripts"
	@echo -e "CLI Tests: $(shell find cli_test -name "*.sh" 2>/dev/null | wc -l || echo 0) scripts"

## debug: Show debug information for troubleshooting
debug:
	@echo -e "$(BLUE)Debug Information$(RESET)"
	@echo "==================="
	@echo -e "Working directory: $(PWD)"
	@echo -e "Make version: $(MAKE_VERSION)"
	@echo -e "Shell: $(SHELL)"
	@echo ""
	@echo -e "$(BLUE)File structure:$(RESET)"
	@find . -maxdepth 3 -type f -name "*.sh" -o -name "*.json" | head -20
	@echo ""
	@echo -e "$(BLUE)Key files:$(RESET)"
	@ls -la $(BIN_DIR)/claudetainer $(SRC_DIR)/devcontainer-feature.json 2>/dev/null || echo "Some files missing"
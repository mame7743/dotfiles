.PHONY: install update deps deps-core deps-core-dry deps-check deps-update deps-windows bin-tools lint help

DOTFILES := $(shell pwd)

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*##"}{printf "  \033[36m%-12s\033[0m %s\n",$$1,$$2}'

install: ## Create symlinks and install dotfiles
	bash $(DOTFILES)/scripts/install.sh

install-windows: ## Create symlinks on Windows (PowerShell)
	powershell -ExecutionPolicy Bypass -File $(DOTFILES)/scripts/install.ps1

deps: ## Install dependencies (auto-detects OS: brew / apt)
	bash $(DOTFILES)/scripts/install-deps.sh

deps-core: ## Install daily terminal dev environment from deps/core.txt (macOS only)
	bash $(DOTFILES)/scripts/install-deps.sh --core

deps-core-dry: ## Show what deps-core would install (no changes)
	bash $(DOTFILES)/scripts/install-deps.sh --core --dry-run

deps-check: ## Check declared vs installed dependencies (drift detection)
	bash $(DOTFILES)/deps/check.sh

deps-update: ## Update pinned versions (deps/versions.env) and lock files
	bash $(DOTFILES)/deps/update.sh

deps-windows: ## Install dependencies on Windows (winget)
	powershell -ExecutionPolicy Bypass -File $(DOTFILES)/scripts/install-deps.ps1

bin-tools: ## Build/install directory-based bin tools (Go/Python) to ~/.local/bin
	python3 $(DOTFILES)/scripts/bin-tools.py

update: ## Pull latest changes and re-link
	git pull --rebase
	bash $(DOTFILES)/scripts/install.sh

lint: ## Check shell scripts with shellcheck (requires shellcheck)
	shellcheck scripts/*.sh bin/*.sh deps/*.sh 2>/dev/null || true

.PHONY: install update deps deps-check deps-update deps-windows lint help

DOTFILES := $(shell pwd)

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*##"}{printf "  \033[36m%-12s\033[0m %s\n",$$1,$$2}'

install: ## Create symlinks and install dotfiles
	bash $(DOTFILES)/install.sh

install-windows: ## Create symlinks on Windows (PowerShell)
	powershell -ExecutionPolicy Bypass -File $(DOTFILES)/install.ps1

deps: ## Install dependencies (auto-detects OS: brew / apt)
	bash $(DOTFILES)/install-deps.sh

deps-check: ## Check declared vs installed dependencies (drift detection)
	bash $(DOTFILES)/deps/check.sh

deps-update: ## Update pinned versions (deps/versions.env) and lock files
	bash $(DOTFILES)/deps/update.sh

deps-windows: ## Install dependencies on Windows (winget)
	powershell -ExecutionPolicy Bypass -File $(DOTFILES)/install-deps.ps1

update: ## Pull latest changes and re-link
	git pull --rebase
	bash $(DOTFILES)/install.sh

lint: ## Check shell scripts with shellcheck (requires shellcheck)
	shellcheck install.sh lib/*.sh bin/*.sh deps/*.sh 2>/dev/null || true

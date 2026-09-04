.PHONY: install update deps deps-windows lint help

DOTFILES := $(shell pwd)

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*##"}{printf "  \033[36m%-12s\033[0m %s\n",$$1,$$2}'

install: ## Create symlinks and install dotfiles
	bash $(DOTFILES)/install.sh

deps: ## Install dependencies (auto-detects OS: brew / apt)
	bash $(DOTFILES)/install-deps.sh

deps-windows: ## Install dependencies on Windows (winget)
	powershell -ExecutionPolicy Bypass -File $(DOTFILES)/install-deps.ps1

update: ## Pull latest changes and re-link
	git pull --rebase
	bash $(DOTFILES)/install.sh

lint: ## Check shell scripts with shellcheck (requires shellcheck)
	shellcheck install.sh lib/*.sh bin/*.sh 2>/dev/null || true

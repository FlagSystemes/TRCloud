# TRCloud Makefile
# Modern build system for the TRCloud infrastructure bundle

# Variables
ROOT_DIR := $(shell pwd)
DIST_DIR := $(ROOT_DIR)/dist
NPROC := $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
BUILD_JOBS ?= $(NPROC)

# Color output
COLOR_RESET := \033[0m
COLOR_BOLD := \033[1m
COLOR_RED := \033[31m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m
COLOR_BLUE := \033[34m
COLOR_MAGENTA := \033[35m
COLOR_CYAN := \033[36m

# Version information
INFLUXDB_VERSION := 3.3.0
TELEGRAF_VERSION := 1.35.3
DOTNET_FRAMEWORK := net9.0

# Helper functions
define print_header
	@printf "$(COLOR_BOLD)$(COLOR_CYAN)▶ %s$(COLOR_RESET)\n" $(1)
endef

define print_success
	@printf "$(COLOR_BOLD)$(COLOR_GREEN)✓ %s$(COLOR_RESET)\n" $(1)
endef

define print_error
	@printf "$(COLOR_BOLD)$(COLOR_RED)✗ %s$(COLOR_RESET)\n" $(1)
endef

define print_info
	@printf "$(COLOR_BLUE)ℹ %s$(COLOR_RESET)\n" $(1)
endef

# Default target
.DEFAULT_GOAL := help

##@ General

.PHONY: help
help: ## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\n$(COLOR_BOLD)$(COLOR_CYAN)Usage:$(COLOR_RESET)\n  make $(COLOR_YELLOW)<target>$(COLOR_RESET)\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(COLOR_YELLOW)%-20s$(COLOR_RESET) %s\n", $$1, $$2 } /^##@/ { printf "\n$(COLOR_BOLD)$(COLOR_MAGENTA)%s$(COLOR_RESET)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: version
version: ## Display version information
	$(call print_header,"TRCloud Version Information")
	@echo "InfluxDB:    $(INFLUXDB_VERSION)"
	@echo "Telegraf:    $(TELEGRAF_VERSION)"
	@echo ".NET:        $(DOTNET_FRAMEWORK)"
	@echo "Build Jobs:  $(BUILD_JOBS)"

##@ Dependencies

.PHONY: dep
dep: dep-check dep-install ## Install all dependencies

.PHONY: dep-check
dep-check: ## Check for required build tools
	$(call print_header,"Checking build dependencies")
	@command -v git >/dev/null 2>&1 || { printf "$(COLOR_BOLD)$(COLOR_RED)✗ git not found$(COLOR_RESET)\n"; exit 1; }
	@command -v make >/dev/null 2>&1 || { printf "$(COLOR_BOLD)$(COLOR_RED)✗ make not found$(COLOR_RESET)\n"; exit 1; }
	@command -v gcc >/dev/null 2>&1 || command -v clang >/dev/null 2>&1 || { printf "$(COLOR_BOLD)$(COLOR_RED)✗ C compiler not found$(COLOR_RESET)\n"; exit 1; }
	@command -v g++ >/dev/null 2>&1 || command -v clang++ >/dev/null 2>&1 || { printf "$(COLOR_BOLD)$(COLOR_RED)✗ C++ compiler not found$(COLOR_RESET)\n"; exit 1; }
	@command -v go >/dev/null 2>&1 || { printf "$(COLOR_BOLD)$(COLOR_RED)✗ go not found$(COLOR_RESET)\n"; exit 1; }
	@command -v dotnet >/dev/null 2>&1 || { printf "$(COLOR_BOLD)$(COLOR_RED)✗ dotnet not found$(COLOR_RESET)\n"; exit 1; }
	@command -v python3 >/dev/null 2>&1 || { printf "$(COLOR_BOLD)$(COLOR_RED)✗ python3 not found$(COLOR_RESET)\n"; exit 1; }
	$(call print_success,"All required tools found")

.PHONY: dep-install
dep-install: ## Install system dependencies (requires sudo)
	$(call print_header,"Installing system dependencies")
	@if [ -f /etc/debian_version ]; then \
		printf "$(COLOR_BLUE)ℹ Detected Debian/Ubuntu system$(COLOR_RESET)\n"; \
		sudo apt-get update && \
		sudo apt-get install -y build-essential automake libtool pkg-config \
			python3 g++ libssl-dev golang dotnet-sdk-9.0; \
	elif [ -f /etc/redhat-release ]; then \
		printf "$(COLOR_BLUE)ℹ Detected RedHat/CentOS system$(COLOR_RESET)\n"; \
		sudo yum groupinstall -y "Development Tools" && \
		sudo yum install -y automake libtool pkg-config python3 gcc-c++ openssl-devel golang dotnet-sdk-9.0; \
	elif [ "$$(uname)" = "Darwin" ]; then \
		printf "$(COLOR_BLUE)ℹ Detected macOS system$(COLOR_RESET)\n"; \
		command -v brew >/dev/null 2>&1 || { printf "$(COLOR_BOLD)$(COLOR_RED)✗ Homebrew not found. Install from https://brew.sh$(COLOR_RESET)\n"; exit 1; }; \
		brew install autoconf automake libtool pkg-config go dotnet; \
	else \
		printf "$(COLOR_BOLD)$(COLOR_RED)✗ Unsupported platform. Please install dependencies manually.$(COLOR_RESET)\n"; \
		exit 1; \
	fi
	$(call print_success,"Dependencies installed")

.PHONY: submodules
submodules: ## Initialize and update git submodules
	$(call print_header,"Initializing git submodules")
	@git submodule update --init --recursive
	$(call print_success,"Submodules initialized")

##@ Build

.PHONY: build
build: build-influxdata build-rethinkdb build-redis build-garnet build-nats build-seaweedfs build-traefik ## Build all components
	$(call print_success,"All components built successfully")
	$(call print_info,"Build artifacts are in $(DIST_DIR)")

.PHONY: build-influxdata
build-influxdata: ## Download InfluxDB and Telegraf binaries
	$(call print_header,"Downloading InfluxDB and Telegraf")
	@mkdir -p $(DIST_DIR)
	@cd $(ROOT_DIR)/influxdata && sh get-influxdb.sh
	@cd $(ROOT_DIR)/influxdata && sh get-telegraf.sh
	$(call print_success,"InfluxDB $(INFLUXDB_VERSION) and Telegraf $(TELEGRAF_VERSION) downloaded")

.PHONY: build-rethinkdb
build-rethinkdb: ## Build RethinkDB from source
	$(call print_header,"Building RethinkDB")
	@mkdir -p $(DIST_DIR)/rethinkdb
	@cd $(ROOT_DIR)/rethinkdb && \
		./configure --prefix="$(DIST_DIR)/rethinkdb" --allow-fetch && \
		$(MAKE) -j$(BUILD_JOBS) && \
		$(MAKE) install
	$(call print_success,"RethinkDB built")

.PHONY: build-redis
build-redis: ## Build Redis from source
	$(call print_header,"Building Redis")
	@mkdir -p $(DIST_DIR)/redis
	@cd $(ROOT_DIR)/redis && \
		$(MAKE) -j$(BUILD_JOBS) PREFIX="$(DIST_DIR)/redis" install
	$(call print_success,"Redis built")

.PHONY: build-garnet
build-garnet: ## Build Garnet (.NET 9) from source
	$(call print_header,"Building Garnet")
	@mkdir -p $(DIST_DIR)/garnet
	@cd $(ROOT_DIR)/garnet && \
		dotnet restore && \
		dotnet publish main/GarnetServer/GarnetServer.csproj \
			-c Release \
			-o "$(DIST_DIR)/garnet" \
			--framework "$(DOTNET_FRAMEWORK)" \
			-p:PublishSingleFile=true
	$(call print_success,"Garnet built")

.PHONY: build-nats
build-nats: build-nats-server build-nats-cli ## Build NATS Server and CLI
	$(call print_success,"NATS components built")

.PHONY: build-nats-server
build-nats-server: ## Build NATS Server
	$(call print_header,"Building NATS Server")
	@mkdir -p $(DIST_DIR)/nats
	@cd $(ROOT_DIR)/nats && \
		go build -o "$(DIST_DIR)/nats/nats-server"
	$(call print_success,"NATS Server built")

.PHONY: build-nats-cli
build-nats-cli: ## Build NATS CLI
	$(call print_header,"Building NATS CLI")
	@mkdir -p $(DIST_DIR)/nats
	@cd $(ROOT_DIR)/natscli && \
		go build -o "$(DIST_DIR)/nats/nats-cli" nats/main.go
	$(call print_success,"NATS CLI built")

.PHONY: build-seaweedfs
build-seaweedfs: ## Build SeaweedFS from source
	$(call print_header,"Building SeaweedFS")
	@mkdir -p $(DIST_DIR)/seaweedfs
	@cd $(ROOT_DIR)/seaweedfs/weed && \
		go build -o "$(DIST_DIR)/seaweedfs/seaweedfs"
	$(call print_success,"SeaweedFS built")

.PHONY: build-traefik
build-traefik: ## Build Traefik from source
	$(call print_header,"Building Traefik")
	@mkdir -p $(DIST_DIR)/traefik
	@cd $(ROOT_DIR)/traefik && \
		$(MAKE) binary -j$(BUILD_JOBS) PREFIX="$(DIST_DIR)/traefik"
	$(call print_success,"Traefik built")

##@ Testing

.PHONY: test
test: test-rethinkdb test-redis ## Run all tests

.PHONY: test-rethinkdb
test-rethinkdb: ## Run RethinkDB unit tests
	$(call print_header,"Running RethinkDB tests")
	@cd $(ROOT_DIR)/rethinkdb && $(MAKE) unit
	$(call print_success,"RethinkDB tests passed")

.PHONY: test-redis
test-redis: ## Run Redis tests
	$(call print_header,"Running Redis tests")
	@cd $(ROOT_DIR)/redis && $(MAKE) test
	$(call print_success,"Redis tests passed")

.PHONY: test-nats
test-nats: ## Run NATS tests
	$(call print_header,"Running NATS tests")
	@cd $(ROOT_DIR)/nats && go test ./...
	$(call print_success,"NATS tests passed")

.PHONY: test-seaweedfs
test-seaweedfs: ## Run SeaweedFS tests
	$(call print_header,"Running SeaweedFS tests")
	@cd $(ROOT_DIR)/seaweedfs && go test ./...
	$(call print_success,"SeaweedFS tests passed")

##@ Distribution

.PHONY: dist
dist: dist-archive ## Create distribution package

.PHONY: dist-archive
dist-archive: build ## Create compressed archive of dist directory
	$(call print_header,"Creating distribution archive")
	@tar -czf $(ROOT_DIR)/trcloud-dist-$$(date +%Y%m%d-%H%M%S).tar.gz -C $(DIST_DIR) .
	$(call print_success,"Distribution archive created")

.PHONY: dist-clean
dist-clean: ## Remove distribution archives
	$(call print_header,"Removing distribution archives")
	@rm -f $(ROOT_DIR)/trcloud-dist-*.tar.gz
	$(call print_success,"Distribution archives removed")

##@ Cleanup

.PHONY: clean
clean: clean-rethinkdb clean-redis clean-nats clean-seaweedfs ## Clean all build artifacts

.PHONY: clean-all
clean-all: clean dist-clean ## Clean everything including distribution archives
	$(call print_header,"Removing dist directory")
	@rm -rf $(DIST_DIR)
	$(call print_success,"All build artifacts removed")

.PHONY: clean-rethinkdb
clean-rethinkdb: ## Clean RethinkDB build artifacts
	$(call print_header,"Cleaning RethinkDB")
	@cd $(ROOT_DIR)/rethinkdb && $(MAKE) clean || true
	$(call print_success,"RethinkDB cleaned")

.PHONY: clean-redis
clean-redis: ## Clean Redis build artifacts
	$(call print_header,"Cleaning Redis")
	@cd $(ROOT_DIR)/redis && $(MAKE) distclean || true
	$(call print_success,"Redis cleaned")

.PHONY: clean-nats
clean-nats: ## Clean NATS build artifacts
	$(call print_header,"Cleaning NATS")
	@cd $(ROOT_DIR)/nats && go clean || true
	@cd $(ROOT_DIR)/natscli && go clean || true
	$(call print_success,"NATS cleaned")

.PHONY: clean-seaweedfs
clean-seaweedfs: ## Clean SeaweedFS build artifacts
	$(call print_header,"Cleaning SeaweedFS")
	@cd $(ROOT_DIR)/seaweedfs && go clean || true
	$(call print_success,"SeaweedFS cleaned")

.PHONY: clean-traefik
clean-traefik: ## Clean Traefik build artifacts
	$(call print_header,"Cleaning Traefik")
	@cd $(ROOT_DIR)/traefik && $(MAKE) clean || true
	$(call print_success,"Traefik cleaned")

.PHONY: clean-garnet
clean-garnet: ## Clean Garnet build artifacts
	$(call print_header,"Cleaning Garnet")
	@cd $(ROOT_DIR)/garnet && dotnet clean || true
	$(call print_success,"Garnet cleaned")

##@ Development

.PHONY: dev-setup
dev-setup: dep submodules ## Complete development environment setup
	$(call print_success,"Development environment ready")

.PHONY: rebuild
rebuild: clean build ## Clean and rebuild everything

.PHONY: rebuild-%
rebuild-%: clean-% build-% ## Clean and rebuild specific component
	$(call print_success,"Component rebuilt")

.PHONY: status
status: ## Show build status and component information
	$(call print_header,"TRCloud Build Status")
	@echo ""
	@echo "$(COLOR_BOLD)Components:$(COLOR_RESET)"
	@[ -d "$(DIST_DIR)/rethinkdb" ] && echo "  $(COLOR_GREEN)✓$(COLOR_RESET) RethinkDB" || echo "  $(COLOR_RED)✗$(COLOR_RESET) RethinkDB"
	@[ -d "$(DIST_DIR)/redis" ] && echo "  $(COLOR_GREEN)✓$(COLOR_RESET) Redis" || echo "  $(COLOR_RED)✗$(COLOR_RESET) Redis"
	@[ -d "$(DIST_DIR)/garnet" ] && echo "  $(COLOR_GREEN)✓$(COLOR_RESET) Garnet" || echo "  $(COLOR_RED)✗$(COLOR_RESET) Garnet"
	@[ -d "$(DIST_DIR)/nats" ] && echo "  $(COLOR_GREEN)✓$(COLOR_RESET) NATS" || echo "  $(COLOR_RED)✗$(COLOR_RESET) NATS"
	@[ -d "$(DIST_DIR)/seaweedfs" ] && echo "  $(COLOR_GREEN)✓$(COLOR_RESET) SeaweedFS" || echo "  $(COLOR_RED)✗$(COLOR_RESET) SeaweedFS"
	@[ -d "$(DIST_DIR)/traefik" ] && echo "  $(COLOR_GREEN)✓$(COLOR_RESET) Traefik" || echo "  $(COLOR_RED)✗$(COLOR_RESET) Traefik"
	@[ -d "$(DIST_DIR)/influxdata" ] && echo "  $(COLOR_GREEN)✓$(COLOR_RESET) InfluxData" || echo "  $(COLOR_RED)✗$(COLOR_RESET) InfluxData"
	@echo ""
	@echo "$(COLOR_BOLD)Distribution Directory:$(COLOR_RESET)"
	@if [ -d "$(DIST_DIR)" ]; then \
		du -sh $(DIST_DIR) 2>/dev/null || echo "  Unknown size"; \
	else \
		echo "  $(COLOR_RED)Not found$(COLOR_RESET)"; \
	fi

##@ Docker

.PHONY: docker-crux
docker-crux: ## Build CRUX Linux Docker image
	$(call print_header,"Building CRUX Linux Docker image")
	@cd $(ROOT_DIR)/crux && docker build -f Dockerfile.cruxupdated -t trcloud/crux:latest .
	$(call print_success,"CRUX Docker image built")

# Special targets
.PHONY: all
all: dep-check submodules build test ## Complete build pipeline with tests

.PHONY: quick
quick: build-nats build-seaweedfs ## Quick build (Go components only)
	$(call print_success,"Quick build complete")

.PHONY: ci
ci: dep-check build ## CI/CD build (no interactive prompts)
	$(call print_success,"CI build complete")

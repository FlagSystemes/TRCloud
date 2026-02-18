# TRCloud Makefile
# Build all infrastructure components

.PHONY: all clean help submodules \
        influxdb telegraf influxdata \
        rethinkdb redis garnet nats natscli seaweedfs traefik

# Directories
ROOT_DIR := $(shell pwd)
DIST_DIR := $(ROOT_DIR)/dist

# Parallel jobs for C/C++ builds
JOBS ?= $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# Default target
all: influxdata rethinkdb redis garnet nats natscli seaweedfs traefik
	@echo "Build complete. Artifacts are in $(DIST_DIR)"

# Initialize git submodules
submodules:
	git submodule update --init --recursive

# Create dist directory
$(DIST_DIR):
	mkdir -p $(DIST_DIR)

#------------------------------------------------------------------------------
# InfluxData (downloaded binaries)
#------------------------------------------------------------------------------

influxdata: influxdb telegraf

influxdb: $(DIST_DIR)
	@echo "Downloading InfluxDB..."
	cd influxdata && sh get-influxdb.sh

telegraf: $(DIST_DIR)
	@echo "Downloading Telegraf..."
	cd influxdata && sh get-telegraf.sh

#------------------------------------------------------------------------------
# RethinkDB (C++)
#------------------------------------------------------------------------------

rethinkdb: $(DIST_DIR)
	@echo "Building RethinkDB..."
	cd rethinkdb && \
		./configure --prefix="$(DIST_DIR)/rethinkdb" --allow-fetch && \
		$(MAKE) -j$(JOBS) && \
		$(MAKE) install

rethinkdb-debug: $(DIST_DIR)
	@echo "Building RethinkDB (debug)..."
	cd rethinkdb && \
		./configure --prefix="$(DIST_DIR)/rethinkdb" --allow-fetch && \
		$(MAKE) -j$(JOBS) DEBUG=1 VERBOSE=1 && \
		$(MAKE) install

#------------------------------------------------------------------------------
# Redis (C)
#------------------------------------------------------------------------------

redis: $(DIST_DIR)
	@echo "Building Redis..."
	cd redis && $(MAKE) -j$(JOBS) PREFIX="$(DIST_DIR)/redis" install

redis-test:
	@echo "Testing Redis..."
	cd redis && $(MAKE) test

#------------------------------------------------------------------------------
# Garnet (.NET 9)
#------------------------------------------------------------------------------

garnet: $(DIST_DIR)
	@echo "Building Garnet..."
	cd garnet && \
		dotnet restore && \
		dotnet publish main/GarnetServer/GarnetServer.csproj \
			-c Release \
			-o "$(DIST_DIR)/garnet" \
			--framework "net10.0" \
			-p:PublishSingleFile=true

#------------------------------------------------------------------------------
# NATS (Go)
#------------------------------------------------------------------------------

nats: $(DIST_DIR)
	@echo "Building NATS Server..."
	mkdir -p $(DIST_DIR)/nats
	cd nats && go build -o "$(DIST_DIR)/nats/nats-server"

natscli: $(DIST_DIR)
	@echo "Building NATS CLI..."
	mkdir -p $(DIST_DIR)/nats
	cd natscli && go build -o "$(DIST_DIR)/nats/nats-cli" nats/main.go

nats-all: nats natscli

#------------------------------------------------------------------------------
# SeaweedFS (Go)
#------------------------------------------------------------------------------

seaweedfs: $(DIST_DIR)
	@echo "Building SeaweedFS..."
	mkdir -p $(DIST_DIR)/seaweedfs
	cd seaweedfs/weed && go build -o "$(DIST_DIR)/seaweedfs/seaweedfs"

#------------------------------------------------------------------------------
# Traefik (Go)
#------------------------------------------------------------------------------

traefik: $(DIST_DIR)
	@echo "Building Traefik..."
	cd traefik && $(MAKE) binary -j$(JOBS)
	mkdir -p $(DIST_DIR)/traefik
	cp traefik/dist/traefik $(DIST_DIR)/traefik/

#------------------------------------------------------------------------------
# Clean targets
#------------------------------------------------------------------------------

clean:
	rm -rf $(DIST_DIR)

clean-rethinkdb:
	cd rethinkdb && $(MAKE) clean || true

clean-redis:
	cd redis && $(MAKE) distclean || true

clean-garnet:
	cd garnet && dotnet clean || true

clean-go:
	cd nats && go clean || true
	cd natscli && go clean || true
	cd seaweedfs/weed && go clean || true
	cd traefik && $(MAKE) clean || true

clean-all: clean clean-rethinkdb clean-redis clean-garnet clean-go

#------------------------------------------------------------------------------
# Test targets
#------------------------------------------------------------------------------

test-rethinkdb:
	cd rethinkdb && $(MAKE) unit

test-rethinkdb-full:
	cd rethinkdb && $(MAKE) test

test-redis:
	cd redis && $(MAKE) test

test-nats:
	cd nats && go test ./...

test-seaweedfs:
	cd seaweedfs && go test ./...

test-traefik:
	cd traefik && go test ./...

test: test-rethinkdb test-redis test-nats

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------

help:
	@echo "TRCloud Build System"
	@echo ""
	@echo "Usage: make [target] [JOBS=n]"
	@echo ""
	@echo "Main targets:"
	@echo "  all             Build all components (default)"
	@echo "  submodules      Initialize git submodules"
	@echo "  clean           Remove dist directory"
	@echo "  clean-all       Clean everything including build artifacts"
	@echo ""
	@echo "Components:"
	@echo "  influxdata      Download InfluxDB and Telegraf"
	@echo "  influxdb        Download InfluxDB only"
	@echo "  telegraf        Download Telegraf only"
	@echo "  rethinkdb       Build RethinkDB"
	@echo "  rethinkdb-debug Build RethinkDB with debug symbols"
	@echo "  redis           Build Redis"
	@echo "  garnet          Build Garnet"
	@echo "  nats            Build NATS Server"
	@echo "  natscli         Build NATS CLI"
	@echo "  nats-all        Build NATS Server and CLI"
	@echo "  seaweedfs       Build SeaweedFS"
	@echo "  traefik         Build Traefik"
	@echo ""
	@echo "Testing:"
	@echo "  test            Run unit tests (rethinkdb, redis, nats)"
	@echo "  test-rethinkdb  Run RethinkDB unit tests"
	@echo "  test-rethinkdb-full  Run full RethinkDB test suite"
	@echo "  test-redis      Run Redis tests"
	@echo "  test-nats       Run NATS tests"
	@echo "  test-seaweedfs  Run SeaweedFS tests"
	@echo "  test-traefik    Run Traefik tests"
	@echo ""
	@echo "Options:"
	@echo "  JOBS=n          Parallel jobs for C/C++ builds (default: auto)"
	@echo ""
	@echo "Examples:"
	@echo "  make                    # Build everything"
	@echo "  make nats seaweedfs     # Build only Go components"
	@echo "  make rethinkdb JOBS=4   # Build RethinkDB with 4 jobs"
	@echo "  make -j4 nats natscli   # Build NATS components in parallel"

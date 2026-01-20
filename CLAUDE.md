# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TRCloud (Tech Runner Cloud) is a comprehensive infrastructure bundle that builds and packages multiple database, messaging, storage, and networking components for cloud deployment. The project combines both built-from-source components and downloaded binaries to create a complete cloud infrastructure stack.

### Components

**Databases:**
- **RethinkDB** - Realtime NoSQL database with push capabilities (C++, built from source)
- **Redis** - In-memory data structure store (C, built from source)
- **Garnet** - High-performance Redis alternative from Microsoft (.NET 9, built from source)
- **InfluxDB 3** - Time-series database (downloaded binaries)

**Messaging & Queuing:**
- **NATS Server** - High-performance messaging system (Go, built from source)
- **NATS CLI** - Command-line interface for NATS (Go, built from source)

**Storage:**
- **SeaweedFS** - Distributed file system (Go, built from source)

**Networking:**
- **Traefik** - Modern HTTP reverse proxy and load balancer (Go, built from source)
- **Telegraf** - Metrics collection agent (downloaded binaries)

**Infrastructure:**
- **crux** - CRUX Linux Docker configuration for minimal Linux environments

## Quick Start

### Prerequisites

Install required build tools:
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y build-essential automake libtool pkg-config \
  python3 g++ libssl-dev golang dotnet-sdk-9.0

# macOS
brew install autoconf automake libtool pkg-config go dotnet
```

### Initialize Git Submodules

All major components are git submodules. Initialize them before building:
```bash
git submodule update --init --recursive
```

### Full Build

Build all components at once:
```bash
./build.sh
```

This will:
1. Download InfluxDB 3.3.0 and Telegraf 1.35.3 binaries for all platforms
2. Build RethinkDB from source
3. Build Redis from source
4. Build Garnet from source (.NET 9)
5. Build NATS Server from source
6. Build NATS CLI from source
7. Build SeaweedFS from source
8. Build Traefik from source

All artifacts are placed in `dist/` organized by component.

## Build Commands

### RethinkDB

```bash
cd rethinkdb
./configure --prefix="$PWD/../dist/rethinkdb" --allow-fetch
make -j8
make install
```

**Build Options:**
- `make -j<n>` - Parallel build (use number of cores)
- `make DEBUG=1` - Debug build with symbols
- `make VERBOSE=1` - Show full build commands
- `make ALLOW_WARNINGS=0` - Fail on compiler warnings
- `make SYMBOLS=0` - Exclude debugging symbols
- `make clean` - Remove build directory
- `make rethinkdb` - Build server executable only
- `make unit` - Build and run unit tests
- `make test` - Run all tests (unit, reql, integration)

**Configure Options:**
- `--allow-fetch` - Fetch missing dependencies automatically
- `--prefix <path>` - Set installation prefix
- `--ccache` - Use ccache for faster rebuilds
- `CXX=clang++` - Use Clang instead of GCC

### Redis

```bash
cd redis
make -j8 PREFIX="../dist/redis" install
make test  # Optional: run tests
```

### Garnet (.NET 9)

```bash
cd garnet
dotnet restore
dotnet publish main/GarnetServer/GarnetServer.csproj \
  -c Release \
  -o "../dist/garnet" \
  --framework "net9.0" \
  -p:PublishSingleFile=true
```

### NATS Server

```bash
cd nats
go build -o "../dist/nats/nats-server"
```

### NATS CLI

```bash
cd natscli
go build -o "../dist/nats/nats-cli" nats/main.go
```

### SeaweedFS

```bash
cd seaweedfs/weed
go build -o "../../dist/seaweedfs/seaweedfs"
```

### Traefik

```bash
cd traefik
make binary -j8 PREFIX="../dist/traefik"
```

### InfluxDB & Telegraf (Download)

```bash
cd influxdata
sh get-influxdb.sh    # Downloads InfluxDB 3.3.0 for all platforms
sh get-telegraf.sh    # Downloads Telegraf 1.35.3 for all platforms
```

## Project Structure

```
TRCloud/
├── .github/
│   └── workflows/
│       └── release.yml        # CI/CD for automated releases
├── rethinkdb/                 # Git submodule - RethinkDB source
│   ├── src/                   # C++ source code
│   │   ├── arch/              # Runtime primitives
│   │   ├── btree/             # B-tree implementation
│   │   ├── buffer_cache/      # Page cache
│   │   ├── clustering/        # Distributed cluster management
│   │   ├── rdb_protocol/      # ReQL query processing
│   │   ├── serializer/        # Log-structured storage
│   │   ├── rpc/               # RPC infrastructure
│   │   └── unittest/          # Unit tests
│   ├── test/                  # Integration tests
│   ├── mk/                    # Build system
│   └── external/              # Third-party dependencies
├── redis/                     # Git submodule - Redis source
├── garnet/                    # Git submodule - Garnet source
├── nats/                      # Git submodule - NATS Server source
├── natscli/                   # Git submodule - NATS CLI source
├── seaweedfs/                 # Git submodule - SeaweedFS source
├── traefik/                   # Git submodule - Traefik source
├── influxdata/                # InfluxDB/Telegraf download scripts
│   ├── get-influxdb.sh        # Downloads InfluxDB 3.3.0
│   └── get-telegraf.sh        # Downloads Telegraf 1.35.3
├── crux/                      # CRUX Linux Docker configuration
│   └── Dockerfile.cruxupdated
├── dist/                      # Build artifacts (generated)
│   ├── rethinkdb/             # Built RethinkDB installation
│   ├── redis/                 # Built Redis binaries
│   ├── garnet/                # Built Garnet binaries
│   ├── nats/                  # Built NATS Server & CLI
│   ├── seaweedfs/             # Built SeaweedFS binary
│   ├── traefik/               # Built Traefik binary
│   └── influxdata/
│       ├── influxdb/          # InfluxDB binaries per platform
│       └── telegraf/          # Telegraf binaries per platform
├── build.sh                   # Main build script
├── CLAUDE.md                  # This file - AI assistant guidance
├── WARP.md                    # Warp terminal guidance
└── README.md                  # Project readme

```

## Platform Support

**Built Artifacts Support:**
- macOS arm64
- macOS amd64 (Telegraf only)
- Linux amd64
- Linux arm64
- Windows x64
- Windows arm64 (Telegraf only)

**Build Platforms:**
- Linux (primary build platform)
- macOS (RethinkDB, Redis, Go/Rust components)
- Cross-compilation for Windows targets

## RethinkDB Architecture

RethinkDB is the most complex component in TRCloud. Understanding its architecture helps when debugging or modifying the build.

### Core Concepts

- **Coroutines**: Cooperatively-scheduled coroutines for async operations (`arch/runtime/coroutines.hpp`)
- **Event Loops**: Fixed thread pool running event loops for I/O
- **Mailboxes**: Point-to-point RPC communication between cluster nodes
- **Directory**: Service discovery via broadcast values (business cards)
- **Raft Consensus**: Per-table metadata consensus (`clustering/generic/raft_core.hpp`)

### Query Execution Flow

1. **Entry Point**: `main.cc` → `command_line.cc` → `serve.cc` (`do_serve()`)
2. **Network Layer**: `rdb_query_server_t` accepts TCP connections from client drivers
3. **Query Compilation**: `ql::compile_term()` converts protocol buffers to `ql::term_t` AST
4. **Execution**: Terms execute via `eval()` methods in `rdb_protocol/terms/`
5. **Table Operations**: Convert to `read_t`/`write_t` objects sent to `table_query_client_t`
6. **Storage**: Route through `primary_query_server_t` → `store_t` → B-tree in `page_cache_t`

### Key Source Directories

- `src/arch/` - Runtime (threads, I/O, timers, coroutines)
- `src/btree/` - B-tree data structure and operations
- `src/buffer_cache/` - Page cache for disk I/O
- `src/clustering/` - Distributed cluster management, Raft
- `src/rdb_protocol/` - ReQL query language implementation
- `src/serializer/` - Log-structured storage backend
- `src/rpc/` - RPC infrastructure and mailbox system
- `src/unittest/` - Unit test suite

## Testing

### RethinkDB Tests

**Unit Tests:**
```bash
cd rethinkdb
make unit
```

**Full Test Suite:**
```bash
cd rethinkdb
make test  # Runs unit tests, ReQL tests, and integration tests
```

**Integration Tests:**
Located in `rethinkdb/test/`:
- `test/scenarios/` - Integration test scenarios
- `test/interface/` - Interface tests
- `test/common/driver.py` - Test harness for cluster management

Run integration tests in isolated scratch directory:
```bash
cd rethinkdb/test
rm -rf scratch && mkdir scratch
cd scratch
../../scenarios/<SCENARIO_NAME> <ARGS>
```

### Redis Tests

```bash
cd redis
make test
```

### Component-Specific Testing

Most Go-based components (NATS, SeaweedFS, Traefik) have their own test suites:
```bash
# Example for NATS
cd nats
go test ./...
```

## Development Workflows

### Working with Git Submodules

**Initialize all submodules:**
```bash
git submodule update --init --recursive
```

**Update a specific submodule:**
```bash
cd <submodule-dir>
git fetch origin
git checkout <branch-or-tag>
cd ..
git add <submodule-dir>
git commit -m "Update <submodule> to <version>"
```

**Update all submodules to latest:**
```bash
git submodule update --remote --recursive
```

### Incremental Builds

After making changes to a component, rebuild only that component:

```bash
# RethinkDB incremental
cd rethinkdb && make -j8 && make install

# Redis incremental
cd redis && make -j8 PREFIX="../dist/redis" install

# Go components (fast)
cd nats && go build -o "../dist/nats/nats-server"
```

### Clean Builds

Remove build artifacts for a clean rebuild:

```bash
# RethinkDB
cd rethinkdb && make clean

# Redis
cd redis && make distclean

# Go components
cd nats && go clean
```

### Debugging Builds

**RethinkDB Debug Build:**
```bash
cd rethinkdb
./configure --allow-fetch --prefix="$PWD/../dist/rethinkdb"
make DEBUG=1 VERBOSE=1 -j8
```

**View Full Compiler Commands:**
```bash
make VERBOSE=1 -j8
```

## CI/CD

### GitHub Actions Workflow

Located at `.github/workflows/release.yml`

**Trigger**: Commits to `main` branch with "release" in the commit message

**Process:**
1. Checkout repository with all submodules
2. Install build dependencies
3. Run `./build.sh` to build all components
4. Archive `dist/` folder as `dist.tar.gz`
5. Create GitHub Release with commit SHA as tag
6. Upload `dist.tar.gz` as release artifact

**Manual Release:**
```bash
git commit -m "feature: add new capability (release)"
git push origin main
```

## Key Conventions for AI Assistants

### File Operations

1. **Always read before edit**: Never propose changes to files you haven't read
2. **Respect submodules**: Submodule directories are external code - be cautious with modifications
3. **Build artifacts**: The `dist/` directory is generated - never commit it

### Build Process

1. **Test before committing**: Run relevant tests for any component you modify
2. **Follow build order**: Some components depend on others being built first
3. **Document changes**: Update this file if you change build processes

### Code Style

1. **RethinkDB (C++)**: Follow existing style (2-space indent, snake_case)
2. **Go components**: Use `gofmt` before committing
3. **Shell scripts**: Use shellcheck for validation

### Git Workflow

1. **Branch names**: Use descriptive names like `claude/add-feature-name-{sessionId}`
2. **Commit messages**: Use conventional commits (feat:, fix:, docs:, etc.)
3. **Submodule updates**: Always test after updating submodules
4. **Never force push**: Especially to main/master branch

### Problem Solving Approach

1. **Read documentation first**: Check component README files in submodules
2. **Understand dependencies**: Know which components depend on each other
3. **Test incrementally**: Build and test one component at a time
4. **Check logs**: Build logs contain valuable debugging information
5. **Verify platforms**: Some components build on specific platforms only

### Common Issues

**Submodule not initialized:**
```bash
git submodule update --init --recursive
```

**Build fails with missing dependencies:**
```bash
# RethinkDB
cd rethinkdb && ./configure --allow-fetch

# System packages
sudo apt-get install -y build-essential automake libtool pkg-config
```

**Out of memory during build:**
```bash
# Reduce parallel jobs
make -j4  # instead of -j8
```

**Go build fails:**
```bash
# Update Go modules
cd <component> && go mod tidy
```

## Additional Resources

- **RethinkDB Docs**: https://rethinkdb.com/docs/
- **Redis Docs**: https://redis.io/docs/
- **Garnet Docs**: https://microsoft.github.io/garnet/
- **NATS Docs**: https://docs.nats.io/
- **SeaweedFS Docs**: https://github.com/seaweedfs/seaweedfs/wiki
- **Traefik Docs**: https://doc.traefik.io/traefik/
- **InfluxDB Docs**: https://docs.influxdata.com/influxdb/
- **Telegraf Docs**: https://docs.influxdata.com/telegraf/

## Version Information

- **InfluxDB**: 3.3.0 (downloaded binaries)
- **Telegraf**: 1.35.3 (downloaded binaries)
- **Garnet**: Built with .NET 9.0
- **Other Components**: Version controlled via git submodules (see `.gitmodules`)

## Performance Optimization

### Build Performance

1. **Use ccache**: Speeds up RethinkDB rebuilds
   ```bash
   cd rethinkdb && ./configure --ccache --allow-fetch
   ```

2. **Parallel builds**: Use `-j<cores>` flag
   ```bash
   make -j$(nproc)  # Linux
   make -j$(sysctl -n hw.ncpu)  # macOS
   ```

3. **Incremental builds**: Only rebuild changed components

### Runtime Performance

- **RethinkDB**: Configure cache size, thread count in config files
- **Redis**: Use redis.conf for memory limits, persistence settings
- **NATS**: Configure clustering, JetStream for persistence
- **Traefik**: Configure caching, rate limiting

## Security Considerations

1. **Default credentials**: Change default passwords before deployment
2. **Network exposure**: Configure firewalls appropriately
3. **TLS/SSL**: Enable encryption for production deployments
4. **Updates**: Keep submodules updated for security patches
5. **Secrets**: Never commit credentials or API keys to repository

## License Information

This bundle includes components with different licenses:
- **RethinkDB**: Apache License 2.0
- **Redis**: BSD 3-Clause
- **Garnet**: MIT License
- **NATS**: Apache License 2.0
- **SeaweedFS**: Apache License 2.0
- **Traefik**: MIT License
- **InfluxDB/Telegraf**: Check InfluxData licensing

Review individual component licenses before commercial use.

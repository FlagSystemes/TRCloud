# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

TRCloud (Tech Runner Cloud) bundles and builds several database and infrastructure components:
- **RethinkDB** - A realtime NoSQL database (git submodule from upstream)
- **InfluxDB 3** - Time-series database (downloaded binaries)
- **Telegraf** - Metrics collection agent (downloaded binaries)
- **crux** - CRUX Linux Dockerfile configuration

## Build Commands

### Full Build
Build all components (RethinkDB from source, download InfluxDB/Telegraf binaries):
```bash
./build.sh
```

### RethinkDB Only
```bash
cd rethinkdb
./configure --allow-fetch
make -j8
make install
```

Key build options:
- `make -j<n>` - Parallel build (use number of cores + 1)
- `make DEBUG=1` - Debug build
- `make VERBOSE=1` - Show build commands
- `make ALLOW_WARNINGS=0` - Fail on compiler warnings
- `make SYMBOLS=0` - Exclude debugging symbols
- `make clean` - Remove build directory
- `make rethinkdb` - Build only the server executable (without installing)

### Download InfluxDB/Telegraf
```bash
cd influxdata
sh get-influxdb.sh    # Downloads InfluxDB 3.3.0 for all platforms
sh get-telegraf.sh    # Downloads Telegraf 1.35.3 for all platforms
```

## Testing

### RethinkDB Tests
- `make unit` - Build and run unit tests
- `make test` - Run unit tests, reql tests, and integration tests

Note: Test instructions in mk/README.md indicate driver dependencies may be required.

Unit tests are in `rethinkdb/src/unittest/`.

Integration tests are in `rethinkdb/test/`:
- `test/scenarios/` - Integration test scenarios
- `test/interface/` - Interface tests
- `test/common/driver.py` - Test support for cluster management

Run integration tests from a scratch directory:
```bash
cd rethinkdb/test
(rm -rf scratch; mkdir scratch; cd scratch; ../scenarios/<SCENARIO> <ARGS>)
```

## Project Structure

```
TRCloud/
├── rethinkdb/           # Git submodule - RethinkDB source
│   ├── src/             # C++ source code
│   ├── test/            # Integration tests
│   ├── mk/              # Build system
│   └── external/        # Third-party dependencies
├── influxdata/          # Scripts to download InfluxDB/Telegraf
│   ├── get-influxdb.sh
│   └── get-telegraf.sh
├── dist/                # Built artifacts and downloaded binaries
│   ├── rethinkdb/       # Built RethinkDB
│   └── influxdata/      # InfluxDB and Telegraf binaries per platform
├── crux/                # CRUX Linux Docker configuration
└── build.sh             # Main build script
```

## RethinkDB Architecture

RethinkDB is written in C++ and uses a thread pool with fixed threads running event loops.

### Core Architectural Concepts

- **Coroutines**: Cooperatively-scheduled coroutines (`arch/runtime/coroutines.hpp`)
- **Mailboxes**: Dynamic objects for point-to-point RPC communication between nodes
- **Directory**: Service discovery system using broadcast values (called "business cards")
- **Raft**: Per-table consensus protocol for metadata management (custom implementation in `clustering/generic/raft_core.hpp`)

### Query Execution Flow

1. `main.cc` → `command_line.cc` → `serve.cc` (`do_serve()`) - Server startup
2. `rdb_query_server_t` - Receives TCP connections from client drivers
3. `ql::compile_term()` - Converts protocol buffer messages to `ql::term_t` expression trees
4. Term execution - Terms execute via `eval()` methods in `rdb_protocol/terms/`
5. Table operations - Become `read_t`/`write_t` objects sent to `table_query_client_t`
6. Query routing - Through `primary_query_server_t` → `store_t` → B-tree in `page_cache_t`

### Key Source Directories

- `src/arch/` - Runtime primitives (thread pool, IO operations, timers, coroutines)
- `src/btree/` - B-tree implementation and operations
- `src/buffer_cache/` - Page cache implementation
- `src/clustering/` - Distributed cluster management, Raft consensus
- `src/rdb_protocol/` - ReQL query language processing and execution
- `src/serializer/` - Log-structured storage backend
- `src/unittest/` - Unit tests
- `src/rpc/` - RPC infrastructure and mailboxes

## Platform Support

Built artifacts target:
- macOS arm64
- macOS amd64 (Telegraf only)
- Linux amd64
- Linux arm64
- Windows x64

## Development Notes

### Git Submodules
RethinkDB is a git submodule. When cloning fresh or switching branches:
```bash
git submodule update --init --recursive
```

### RethinkDB Configuration
On first build, run `./configure --allow-fetch` to fetch and build missing dependencies.

Common configure options:
- `--allow-fetch` - Fetch missing dependencies
- `--prefix <path>` - Set installation prefix
- `--ccache` - Use ccache for faster rebuilds
- `CXX=clang++` - Use Clang instead of GCC

### Build Artifacts
All build artifacts are placed in `dist/`:
- `dist/rethinkdb/` - RethinkDB installation
- `dist/influxdata/influxdb/` - InfluxDB binaries per platform
- `dist/influxdata/telegraf/` - Telegraf binaries per platform

### CI/CD
GitHub Actions workflow (`.github/workflows/release.yml`) builds and releases on commits with "release" in the message.

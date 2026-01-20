# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TRCloud (Tech Runner Cloud) is a project that bundles and builds several database and infrastructure components:
- **RethinkDB** - A realtime NoSQL database (git submodule from upstream)
- **InfluxDB 3** - Time-series database (downloaded binaries)
- **Telegraf** - Metrics collection agent (downloaded binaries)
- **crux** - CRUX Linux Dockerfile configuration

## Build Commands

### Full Build
```bash
./build.sh
```
This builds RethinkDB from source and downloads InfluxDB/Telegraf binaries for multiple platforms.

### RethinkDB Only
```bash
cd rethinkdb
./configure --allow-fetch
make -j8
make install
```

Build options:
- `make -j<n>` - Parallel build (use number of cores + 1)
- `make DEBUG=1` - Debug build
- `make VERBOSE=1` - Show build commands
- `make ALLOW_WARNINGS=0` - Fail on compiler warnings
- `make clean` - Remove build directory
- `make rethinkdb` - Build only the server executable
- `make unit` - Build and run unit tests
- `make test` - Run unit tests, reql tests, and integration tests

### Download InfluxDB/Telegraf
```bash
cd influxdata
sh get-influxdb.sh    # Downloads InfluxDB 3.3.0 for all platforms
sh get-telegraf.sh    # Downloads Telegraf for all platforms
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
├── dist/                # Built artifacts and downloaded binaries
│   ├── rethinkdb/       # Built RethinkDB
│   └── influxdata/      # InfluxDB and Telegraf binaries per platform
├── crux/                # CRUX Linux Docker configuration
└── build.sh             # Main build script
```

## RethinkDB Architecture

RethinkDB uses a thread pool with fixed threads running event loops. Key architectural concepts:

- **Coroutines**: Cooperatively-scheduled (`arch/runtime/coroutines.hpp`)
- **Mailboxes**: Dynamic objects for point-to-point RPC communication
- **Directory**: Service discovery via broadcast values ("business cards")
- **Raft**: Per-table consensus for metadata (custom implementation in `clustering/generic/raft_core.hpp`)

### Query Execution Flow
1. `main.cc` → `command_line.cc` → `serve.cc` (`do_serve()`)
2. `rdb_query_server_t` receives TCP connections from drivers
3. `ql::compile_term()` converts messages to `ql::term_t` trees
4. Terms execute via `eval()` methods in `rdb_protocol/terms/`
5. Table operations become `read_t`/`write_t` objects sent to `table_query_client_t`
6. Queries route through `primary_query_server_t` → `store_t` → B-tree in `page_cache_t`

### Key Source Directories
- `src/arch/` - Runtime primitives (thread pool, IO, timers)
- `src/btree/` - B-tree operations
- `src/buffer_cache/` - Page cache implementation
- `src/clustering/` - Distributed cluster management
- `src/rdb_protocol/` - ReQL query processing
- `src/serializer/` - Log-structured storage
- `src/unittest/` - Unit tests

## Testing

RethinkDB tests are in `rethinkdb/test/`:
- Unit tests: `src/unittest/`
- Integration tests: `test/scenarios/`, `test/interface/`
- Test support: `test/common/driver.py` for cluster management

Run integration tests from a scratch directory:
```bash
cd rethinkdb/test
(rm -rf scratch; mkdir scratch; cd scratch; ../scenarios/<SCENARIO> <ARGS>)
```

## Platform Support

Built artifacts support:
- macOS arm64
- Linux amd64
- Linux arm64
- Windows x64

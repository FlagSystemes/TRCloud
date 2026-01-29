# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TRCloud (Tech Runner Cloud) is an infrastructure bundle that builds and packages database, messaging, storage, and networking components for cloud deployment. All major components are git submodules.

**Built from source:** RethinkDB (C++), Redis (C), Garnet (.NET 9), NATS Server (Go), NATS CLI (Go), SeaweedFS (Go), Traefik (Go)

**Downloaded binaries:** InfluxDB 3.3.0, Telegraf 1.35.3

## Build Commands

### Full Build
```bash
git submodule update --init --recursive  # Required first time
./build.sh                                # Builds everything to dist/
```

### Individual Components

```bash
# RethinkDB (slowest - C++ build)
cd rethinkdb
./configure --prefix="$PWD/../dist/rethinkdb" --allow-fetch
make -j8 && make install

# Redis
cd redis && make -j8 PREFIX="../dist/redis" install

# Garnet
cd garnet && dotnet publish main/GarnetServer/GarnetServer.csproj -c Release -o "../dist/garnet" --framework "net9.0" -p:PublishSingleFile=true

# NATS Server & CLI
cd nats && go build -o "../dist/nats/nats-server"
cd natscli && go build -o "../dist/nats/nats-cli" nats/main.go

# SeaweedFS
cd seaweedfs/weed && go build -o "../../dist/seaweedfs/seaweedfs"

# Traefik
cd traefik && make binary -j8 PREFIX="../dist/traefik"

# Download InfluxDB/Telegraf
cd influxdata && sh get-influxdb.sh && sh get-telegraf.sh
```

### RethinkDB Build Options
- `make DEBUG=1` - Debug build with symbols
- `make VERBOSE=1` - Show full compiler commands
- `make clean` - Clean build artifacts
- `make rethinkdb` - Build server only (no install)
- `./configure --ccache --allow-fetch` - Use ccache for faster rebuilds

## Testing

```bash
# RethinkDB
cd rethinkdb && make unit              # Unit tests only
cd rethinkdb && make test              # Full suite (unit + reql + integration)

# Redis
cd redis && make test

# Go components
cd nats && go test ./...
cd seaweedfs && go test ./...
cd traefik && go test ./...
```

**RethinkDB integration tests** (run from scratch directory):
```bash
cd rethinkdb/test && rm -rf scratch && mkdir scratch && cd scratch
../../scenarios/<SCENARIO_NAME> <ARGS>
```

## RethinkDB Architecture

RethinkDB is the most complex component. Key concepts:

- **Coroutines**: Cooperatively-scheduled (`arch/runtime/coroutines.hpp`)
- **Mailboxes**: Point-to-point RPC between cluster nodes
- **Directory**: Service discovery via broadcast "business cards"
- **Raft**: Per-table metadata consensus (`clustering/generic/raft_core.hpp`)

**Query execution flow:**
1. Entry: `main.cc` → `command_line.cc` → `serve.cc` (`do_serve()`)
2. Network: `rdb_query_server_t` accepts TCP from client drivers
3. Compile: `ql::compile_term()` converts protobuf to `ql::term_t` AST
4. Execute: Terms run via `eval()` in `rdb_protocol/terms/`
5. Storage: `read_t`/`write_t` → `table_query_client_t` → `store_t` → B-tree

**Key directories in `rethinkdb/src/`:**
- `arch/` - Runtime (threads, I/O, coroutines)
- `btree/` - B-tree operations
- `buffer_cache/` - Page cache
- `clustering/` - Cluster management, Raft
- `rdb_protocol/` - ReQL implementation
- `serializer/` - Log-structured storage
- `rpc/` - RPC and mailboxes

## CI/CD

GitHub Actions (`.github/workflows/release.yml`) triggers on commits to `main` containing "release" in the message. It runs `./build.sh` and uploads `dist.tar.gz` as a release artifact.

## Key Notes

- **Submodules are external code** - be cautious with modifications; prefer updating to newer tags
- **`dist/` is generated** - never commit build artifacts
- **RethinkDB style**: 2-space indent, snake_case
- **Go components**: run `gofmt` before committing

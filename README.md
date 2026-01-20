# TRCloud

**Tech Runner Cloud** - A comprehensive infrastructure bundle that builds and packages multiple database, messaging, storage, and networking components for cloud deployment.

## Components

- **Databases**: RethinkDB, Redis, Garnet, InfluxDB 3
- **Messaging**: NATS Server, NATS CLI
- **Storage**: SeaweedFS
- **Networking**: Traefik, Telegraf
- **Infrastructure**: CRUX Linux Docker configuration

## Quick Start

### Prerequisites

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y build-essential automake libtool pkg-config \
  python3 g++ libssl-dev golang dotnet-sdk-9.0

# macOS
brew install autoconf automake libtool pkg-config go dotnet
```

### Initialize Submodules

```bash
git submodule update --init --recursive
```

### Build Everything

```bash
# Using Makefile (recommended)
make dev-setup  # Setup environment
make build      # Build all components

# Or using build script
./build.sh
```

## Using the Makefile

The project includes a modern, feature-rich Makefile:

```bash
# Show all available targets
make help

# Check dependencies
make dep-check

# Build all components
make build

# Build specific component
make build-redis
make build-nats
make build-seaweedfs

# Check build status
make status

# Run tests
make test

# Create distribution archive
make dist

# Clean build artifacts
make clean
```

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Comprehensive developer documentation and AI assistant guidance
- **[WARP.md](WARP.md)** - Warp terminal configuration

## Build Artifacts

All built components are placed in the `dist/` directory:

```
dist/
├── rethinkdb/
├── redis/
├── garnet/
├── nats/
├── seaweedfs/
├── traefik/
└── influxdata/
    ├── influxdb/
    └── telegraf/
```

## Platform Support

- **Linux**: amd64, arm64
- **macOS**: arm64, amd64 (Telegraf only)
- **Windows**: x64, arm64 (Telegraf only)

## License

This bundle includes components with different licenses. Review individual component licenses before commercial use:

- RethinkDB: Apache License 2.0
- Redis: BSD 3-Clause
- Garnet: MIT License
- NATS: Apache License 2.0
- SeaweedFS: Apache License 2.0
- Traefik: MIT License
- InfluxDB/Telegraf: InfluxData licensing

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Submit a pull request

## CI/CD

Automated builds are triggered on commits to `main` branch containing "release" in the commit message. Build artifacts are automatically packaged and released via GitHub Actions.

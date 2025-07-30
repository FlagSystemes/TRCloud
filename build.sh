#!/bin/bash

set -e

ROOT_DIR="$(cd "$(dirname "$0")"; pwd)"
DIST_DIR="$ROOT_DIR/dist"

# Ensure dist directory exists
mkdir -p "$DIST_DIR"

# Build RethinkDB
echo "Building RethinkDB..."
cd "$ROOT_DIR/rethinkdb"
./configure --prefix="$DIST_DIR/rethinkdb" --allow-fetch
make -j4
make install

# Build Redis
echo "Building Redis..."
cd "$ROOT_DIR/redis"
make -j4 PREFIX="$DIST_DIR/redis" install
make test

echo "Build complete. Artifacts are in $DIST_DIR."
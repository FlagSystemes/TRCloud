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
make -j8
make install

# # Build Redis
# echo "Building Redis..."
# cd "$ROOT_DIR/redis"
# make -j4 PREFIX="$DIST_DIR/redis" install
# #make test

# # Build Garnet
# echo "Building Garnet..."
# cd "$ROOT_DIR/garnet"
# dotnet restore
# dotnet publish main/GarnetServer/GarnetServer.csproj -c Release -o "$DIST_DIR/garnet"  --framework "net9.0" -p:PublishSingleFile=true #--self-contained true --runtime osx-arm64 
 

# # Build NATS Server
# echo "Building NATS Server..."
# cd "$ROOT_DIR/nats-server"
# go build -o "$DIST_DIR/nats-server/nats-server"


# # Build SeaweedFS
# echo "Building SeaweedFS..."
# cd "$ROOT_DIR/seaweedfs"
# cd "weed"
# go build -o "$DIST_DIR/seaweedfs/seaweedfs"



# # Build traefik
# echo "Building traefik..."
# cd "$ROOT_DIR/traefik"
# make binary -j4 PREFIX="$DIST_DIR/traefik"

# # Build influxdb
# echo "Building traefik..."
# cd "$ROOT_DIR/influxdb"
# cargo build --all-targets --target-dir ../dist/influxdb --profile quick-release

# get influxdb
echo "getting influxdb..."
cd "$ROOT_DIR/influxdata"
sh get-influxdb.sh

sh get-telegraf.sh

echo "Build complete. Artifacts are in $DIST_DIR."
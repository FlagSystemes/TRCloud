#!/bin/bash

set -e

mkdir -p '../dist/influxdata/influxdb/osx-arm64/'
mkdir -p '../dist/influxdata/influxdb/linux-amd64/'
mkdir -p '../dist/influxdata/influxdb/linux-arm64/'
mkdir -p '../dist/influxdata/influxdb/win-x64/'

echo "Downloading InfluxDB 3.3.0 core binaries for osx arm64..."

curl -sSL 'https://dl.influxdata.com/influxdb/releases/influxdb3-core-3.3.0_darwin_arm64.tar.gz' -o '../dist/influxdata/influxdb/influxdb3-core.tar.gz'

tar -xf '../dist/influxdata/influxdb/influxdb3-core.tar.gz' --strip-components=1 -C '../dist/influxdata/influxdb/osx-arm64/'

rm '../dist/influxdata/influxdb/influxdb3-core.tar.gz'

echo "Downloading InfluxDB 3.3.0 core binaries for Linux arm64..."

curl -sSL 'https://dl.influxdata.com/influxdb/releases/influxdb3-core-3.3.0_linux_arm64.tar.gz' -o '../dist/influxdata/influxdb/influxdb3-core.tar.gz'

tar -xf '../dist/influxdata/influxdb/influxdb3-core.tar.gz' --strip-components=1 -C '../dist/influxdata/influxdb/linux-arm64/'

rm '../dist/influxdata/influxdb/influxdb3-core.tar.gz'
echo "Downloading InfluxDB 3.3.0 core binaries for Linux amd64..."
curl -sSL 'https://dl.influxdata.com/influxdb/releases/influxdb3-core-3.3.0_linux_amd64.tar.gz' -o '../dist/influxdata/influxdb/influxdb3-core.tar.gz'

tar -xf '../dist/influxdata/influxdb/influxdb3-core.tar.gz' --strip-components=1 -C '../dist/influxdata/influxdb/linux-amd64/'

rm '../dist/influxdata/influxdb/influxdb3-core.tar.gz'

echo "Downloading InfluxDB 3.3.0 core binaries for Windows..."
curl -sSL 'https://dl.influxdata.com/influxdb/releases/influxdb3-core-3.3.0-windows_amd64.zip' -o '../dist/influxdata/influxdb/influxdb3-core.zip'

unzip  -o '../dist/influxdata/influxdb/influxdb3-core.zip' -d '../dist/influxdata/influxdb/win-x64'

rm '../dist/influxdata/influxdb/influxdb3-core.zip'

echo "InfluxDB 3.3.0 core binaries downloaded and extracted successfully."

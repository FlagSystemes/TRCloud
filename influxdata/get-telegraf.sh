#!/bin/bash

set -e

mkdir -p '../dist/influxdata/telegraf/osx-arm64/'
mkdir -p '../dist/influxdata/telegraf/osx-amd64/'
mkdir -p '../dist/influxdata/telegraf/linux-amd64/'
mkdir -p '../dist/influxdata/telegraf/linux-arm64/'
mkdir -p '../dist/influxdata/telegraf/win-x64/'

echo "Downloading telegraf  binaries for osx arm64..."

curl -sSL 'https://dl.influxdata.com/telegraf/releases/telegraf-1.35.3_darwin_arm64.dmg' -o '../dist/influxdata/telegraf/osx-arm64/telegraf-1.35.3_darwin_arm64.dmg'

echo "Downloading telegraf binaries for osx amd64..."

curl -sSL 'https://dl.influxdata.com/telegraf/releases/telegraf-1.35.3_darwin_amd64.dmg' -o '../dist/influxdata/telegraf/osx-amd64/telegraf-1.35.3_darwin_amd64.dmg'

echo "Downloading telegraf binaries for windows amd64..."

curl -sSL 'https://dl.influxdata.com/telegraf/releases/telegraf-1.35.3_windows_amd64.zip'  -o '../dist/influxdata/telegraf/telegraf-1.35.3_windows_amd64.zip'

unzip  -o '../dist/influxdata/telegraf/telegraf-1.35.3_windows_amd64.zip' -d '../dist/influxdata/telegraf/win-x64' 

rm '../dist/influxdata/telegraf/telegraf-1.35.3_windows_amd64.zip'




echo "Downloading telegraf for Linux amd64..."

curl -sSL 'https://dl.influxdata.com/telegraf/releases/telegraf-1.35.3_linux_amd64.tar.gz' -o '../dist/influxdata/telegraf/telegraf-1.35.3_linux_amd64.tar.gz'

tar -xf '../dist/influxdata/telegraf/telegraf-1.35.3_linux_amd64.tar.gz' --strip-components=2 -C '../dist/influxdata/telegraf/linux-amd64/'

rm '../dist/influxdata/telegraf/telegraf-1.35.3_linux_amd64.tar.gz'

echo "Downloading telegraf for Linux arm64..."

curl -sSL 'https://dl.influxdata.com/telegraf/releases/telegraf-1.35.3_linux_arm64.tar.gz' -o '../dist/influxdata/telegraf/telegraf-1.35.3_linux_arm64.tar.gz'

tar -xf '../dist/influxdata/telegraf/telegraf-1.35.3_linux_arm64.tar.gz' --strip-components=2 -C '../dist/influxdata/telegraf/linux-arm64/'

rm '../dist/influxdata/telegraf/telegraf-1.35.3_linux_arm64.tar.gz'

echo "Downloading telegraf done..."
#!/bin/bash
# This script sets up and builds the Tauri + Vue + Python application
# Prerequisite: Node.js, Rust/Cargo, uv must be installed

set -e

echo "=== Step 1: Install Node.js dependencies ==="
npm install

echo "=== Step 2: Install Python dependencies ==="
cd src-backend
uv sync

echo "=== Step 3: Build Python backend executable ==="
cd ..
make build-python-bin

echo "=== Step 4: Build Tauri application ==="
make build-app

echo "=== Step 5: Run tests ==="
make test

echo "=== Build complete! ==="
echo "The app bundle is located in src-tauri/target/release/bundle/"
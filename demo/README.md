# Tauri + Vue + Python Demo App

A desktop To-Do List application built with Tauri, Vue 3, and Python.

## Prerequisites

- Rust/Cargo installed
- Python 3.8+ with uv package manager

## Development Mode

### Option 1: Using Makefile

**Terminal 1 - Backend:**
```bash
cd demo
make run-dev-backend
```

**Terminal 2 - UI:**
```bash
cd demo
make run-dev-ui
```

### Option 2: Manual Commands

**Start Python Backend (Terminal 1):**
```bash
cd demo/src-backend
uv run python main.py
# Runs on http://127.0.0.1:8000
```

**Start Tauri UI (Terminal 2):**
```bash
cd demo
./node_modules_runtime/bin/node ./node_modules_runtime/bin/npm run tauri dev
```

### Option 3: With System Tools (if installed)

```bash
# Terminal 1 - Python backend
cd demo/src-backend
python3 main.py

# Terminal 2 - Tauri UI  
cd demo
npm run tauri dev
```

## Production Build

```bash
# Build Python executable
make build-python-bin

# Build complete app
make build-app
```

Output: `src-tauri/target/release/bundle/macos/demo-todo-ru-py.app`

## Tests

```bash
# Frontend tests
make test-frontend
# or
npm run test

# Backend tests
make test-backend

# All tests
make test
```

## Project Structure

```
demo/
├── src/                    # Vue.js frontend
│   ├── App.vue            # Main component
│   └── utils.ts           # API utilities
├── src-tauri/             # Rust/Tauri backend
│   ├── src/              # Rust source
│   └── binaries/         # Python sidecar
├── src-backend/          # Python backend
│   └── main.py           # Bottle API server
├── tests/                 # Unit tests
└── node_modules_runtime/  # Local Node.js
```

## Quick Reference

| Command | Description |
|---------|-------------|
| `make run-dev-backend` | Start Python API server |
| `make run-dev-ui` | Start Tauri dev window |
| `make build-python-bin` | Build Python executable |
| `make build-app` | Build desktop app |
| `make test` | Run all tests |
# Building Desktop Apps with Tauri + Vue + Python

This guide provides detailed steps to create a desktop To-Do List application using Tauri, Vue, and Python.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Project Architecture Overview](#project-architecture-overview)
3. [Step-by-Step Implementation](#step-by-step-implementation)
4. [Development Mode](#development-mode)
5. [Testing](#testing)
6. [Building](#building)

---

## Development Mode

### Quick Start (Two Terminals Required)

**Terminal 1 - Start Python Backend:**
```bash
cd demo

# Using local uv
./src-backend/.venv/bin/python src-backend/main.py

# Or use the Makefile
make run-dev-backend
```

The backend will start on `http://127.0.0.1:8000`

**Terminal 2 - Start Tauri UI:**
```bash
cd demo

# Using local Node.js
./node_modules_runtime/bin/node ./node_modules_runtime/bin/npm run tauri dev

# Or use the Makefile
make run-dev-ui
```

The UI will open in a new window at `http://localhost:1420`

### Combined Start (Makefile)

From the demo directory:
```bash
# Start both backend and UI (requires two terminals)
make run-dev-backend  # Terminal 1
make run-dev-ui        # Terminal 2
```

### Using Node.js Locally (Without System Installation)

The project includes a local Node.js runtime in `node_modules_runtime/`:

```bash
cd demo

# View Node version
./node_modules_runtime/bin/node --version

# Install dependencies
./node_modules_runtime/bin/node ./node_modules_runtime/bin/npm install

# Build frontend
./node_modules_runtime/bin/node ./node_modules_runtime/bin/npm run build

# Run Tauri dev
./node_modules_runtime/bin/node ./node_modules_runtime/bin/npm run tauri dev
```

### Using Python with uv Locally

```bash
cd demo/src-backend

# Install dependencies (already done)
uv sync

# Run the backend server
uv run python main.py

# Or manually
.venv/bin/python main.py
```

### Development Mode Behavior

| Component | Port | Purpose |
|-----------|------|---------|
| Python Backend | 8000 | REST API server (Bottle) |
| Vue Frontend | 1420 | Vite dev server |
| Tauri Window | GUI | Desktop application window |

### Key Environment Variables

- `TAURI_DEV=1` - Skips auto-spawning Python backend (run manually in dev mode)

```bash
# In makefile or shell
TAURI_DEV=1 ./node_modules_runtime/bin/npm run tauri dev
```

### Troubleshooting Development Mode Issues

**Port 8000 already in use:**
```bash
# Find and kill process using port 8000
lsof -i :8000 | grep LISTEN
kill <PID>
```

**Backend not starting:**
```bash
# Check Python dependencies
cd demo/src-backend && uv pip list

# Verify bottle is installed
uv pip show bottle
```

**Tauri window not opening:**
```bash
# Check Rust compilation
cd demo/src-tauri && cargo check
```

---

## Prerequisites

### Required Tools

| Tool | Purpose | Installation |
|------|---------|--------------|
| **Rust/Cargo** | Tauri backend runtime | https://doc.rust-lang.org/cargo/getting-started/installation.html |
| **Node.js** | Frontend build tools | https://nodejs.org/ |
| **Python 3.8+** | Backend runtime | Built-in or via pyenv |
| **uv** | Python package manager | https://docs.astral.sh/uv/guides/install-python/ |
| **PyInstaller** | Python to executable | `uv pip install pyinstaller` |

### Verify Installations

```bash
cargo --version    # Should show Rust 1.70+
node --version     # Should show Node 16+
python3 --version  # Should show Python 3.8+
uv --version       # Should show uv installed
```

---

## Project Architecture Overview

```
tauri-vue-python/
├── src/                    # Vue.js frontend
│   ├── App.vue            # Main Vue component
│   └── utils.ts           # API calling utilities
├── src-tauri/             # Tauri/Rust backend
│   ├── src/
│   │   ├── main.rs        # Entry point, spawns Python sidecar
│   │   ├── lib.rs         # Library exports
│   │   └── api.rs         # Rust API commands
│   ├── binaries/          # Compiled Python executable
│   ├── capabilities/      # Tauri permissions
│   ├── icons/             # App icons
│   └── tauri.conf.json    # Tauri configuration
├── src-backend/           # Python backend
│   ├── main.py            # Bottle/FastAPI server
│   └── pyproject.toml     # Python dependencies
└── tests/                 # Unit and integration tests
```

### How It Works

1. **Vue Frontend**: Renders the UI, makes API calls via Tauri commands
2. **Tauri (Rust)**: Wraps the webview, spawns Python backend as sidecar
3. **Python Backend**: REST API server (Bottle) managing SQLite database
4. **IPC**: Vue → Tauri Command → Python API → SQLite

---

## Step-by-Step Implementation

### Step 1: Initialize Tauri + Vue Project

```bash
# Create project with Vite + Vue template
npm create tauri-app@latest demo-todo -- --template vue-ts --manager npm

cd demo-todo
npm install
```

### Step 2: Install Rust Dependencies

Update `src-tauri/Cargo.toml`:

```toml
[package]
name = "demo-todo-ru-py"
version = "0.1.0"
description = "A Tauri App"
authors = ["you"]
edition = "2021"

[lib]
name = "demo_todo_ru_py_lib"
crate-type = ["staticlib", "cdylib", "rlib"]

[build-dependencies]
tauri-build = { version = "2", features = [] }

[dependencies]
tauri = { version = "2", features = [] }
tauri-plugin-opener = "2"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
reqwest = { version = "0.12", features = ["json"] }
libc = "0.2"
```

### Step 3: Configure Tauri

Create `src-tauri/tauri.conf.json`:

```json
{
  "$schema": "https://schema.tauri.app/config/2",
  "productName": "demo-todo-ru-py",
  "version": "0.1.0",
  "identifier": "com.demo-todo-ru-py.app",
  "build": {
    "beforeDevCommand": "npm run dev",
    "devUrl": "http://localhost:1420",
    "beforeBuildCommand": "npm run build",
    "frontendDist": "../dist"
  },
  "app": {
    "windows": [
      {
        "title": "demo-todo-ru-py",
        "width": 800,
        "height": 600
      }
    ],
    "security": {
      "csp": "default-src tauri://localhost http://127.0.0.1:8000 http://localhost:8000; script-src 'self'; img-src 'self' data:;"
    }
  },
  "bundle": {
    "active": true,
    "targets": "all",
    "icon": [
      "icons/32x32.png",
      "icons/128x128.png",
      "icons/128x128@2x.png",
      "icons/icon.icns",
      "icons/icon.ico"
    ],
    "externalBin": [
      "binaries/python_backend"
    ]
  }
}
```

Create `src-tauri/capabilities/default.json`:

```json
{
  "$schema": "../gen/schemas/desktop-schema.json",
  "identifier": "default",
  "description": "Capability for the main window",
  "windows": ["main"],
  "permissions": [
    "core:default",
    "opener:default"
  ]
}
```

### Step 4: Create Rust API Commands

Create `src-tauri/src/api.rs`:

```rust
use reqwest::Client;
use serde_json::Value;

#[tauri::command]
pub async fn py_api(
    method: String,
    endpoint: String,
    payload: Option<Value>,
) -> Result<Value, String> {
    let client = Client::new();
    let url = format!("http://127.0.0.1:8000/{}", endpoint);

    let request = match method.as_str() {
        "GET" => client.get(&url),
        "POST" => {
            let req = client.post(&url);
            if let Some(data) = &payload {
                req.json(data)
            } else {
                req
            }
        }
        "PUT" => client.put(&url),
        "DELETE" => client.delete(&url),
        _ => return Err(format!("Unsupported HTTP method: {}", method)),
    };

    let request = if let Some(data) = payload {
        request.json(&data)
    } else {
        request
    };

    let response = request
        .send()
        .await
        .map_err(|e| e.to_string())?
        .json::<Value>()
        .await
        .map_err(|e| e.to_string())?;

    Ok(response)
}
```

### Step 5: Create Rust Main Entry Point

Create `src-tauri/src/lib.rs`:

```rust
pub mod api;
pub use api::py_api;
```

Create `src-tauri/src/main.rs`:

```rust
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::{
    env,
    io::{BufRead, BufReader},
    net::TcpStream,
    path::PathBuf,
    process::{Child, Command, Stdio},
    sync::{Arc, Mutex},
    thread,
    time::{Duration, Instant},
};
use tauri::{App, AppHandle, Builder, Emitter, RunEvent, WindowEvent};

#[cfg(unix)]
use libc;
#[cfg(unix)]
use std::os::unix::process::CommandExt;

fn backend_filename() -> &'static str {
    if cfg!(windows) {
        "python_backend.exe"
    } else {
        "python_backend"
    }
}

fn spawn_backend() -> std::io::Result<Child> {
    let exe_dir: PathBuf = env::current_exe()?
        .parent()
        .expect("exe has no parent")
        .to_path_buf();
    let bin = exe_dir.join(backend_filename());
    println!("▶ spawning backend: {:?}", bin);

    let mut cmd = Command::new(&bin);
    cmd.stdout(Stdio::piped()).stderr(Stdio::piped());

    #[cfg(unix)]
    unsafe {
        cmd.pre_exec(|| {
            if libc::setsid() < 0 {
                return Err(std::io::Error::last_os_error());
            }
            Ok(())
        });
    }

    let mut child = cmd.spawn()?;

    if let Some(out) = child.stdout.take() {
        thread::spawn(move || {
            for line in BufReader::new(out).lines().flatten() {
                println!("[backend] {line}");
            }
        });
    }

    if let Some(err) = child.stderr.take() {
        thread::spawn(move || {
            for line in BufReader::new(err).lines().flatten() {
                eprintln!("[backend-err] {line}");
            }
        });
    }

    Ok(child)
}

fn monitor_backend_ready(app_handle: &AppHandle) {
    let handle = app_handle.clone();
    thread::spawn(move || {
        let deadline = Instant::now() + Duration::from_secs(10);
        while Instant::now() < deadline {
            if TcpStream::connect(("127.0.0.1", 8000)).is_ok() {
                println!("✅ backend is ready");
                let _ = handle.emit("backend-ready", ());
                return;
            }
            thread::sleep(Duration::from_millis(100));
        }
        eprintln!("⚠️ backend did not become ready in 10s");
    });
}

fn kill_on_exit(handle: Arc<Mutex<Option<Child>>>, event: &RunEvent) {
    let should_kill = matches!(
        event,
        RunEvent::WindowEvent { event: WindowEvent::CloseRequested { .. }, .. }
            | RunEvent::ExitRequested { .. }
            | RunEvent::Exit
    );
    if should_kill {
        if let Some(mut child) = handle.lock().unwrap().take() {
            #[cfg(unix)]
            {
                let pgid = child.id() as i32;
                unsafe { libc::kill(-pgid, libc::SIGKILL) };
            }
            #[cfg(windows)]
            {
                let _ = child.kill();
            }
            let _ = child.wait();
            println!("⛔ backend terminated, port 8000 freed");
        }
    }
}

fn main() {
    let child_handle = Arc::new(Mutex::new(None));

    Builder::default()
        .setup({
            let child_handle = child_handle.clone();
            move |app: &mut App| {
                if env::var("TAURI_DEV").unwrap_or_default() != "1" {
                    let child = spawn_backend().expect("failed to spawn python backend");
                    *child_handle.lock().unwrap() = Some(child);
                    monitor_backend_ready(app.handle());
                } else {
                    println!("⚠️ TAURI_DEV=1 → skipping backend spawn");
                }
                Ok(())
            }
        })
        .invoke_handler(tauri::generate_handler![demo_todo_ru_py_lib::py_api])
        .build(tauri::generate_context!())
        .expect("error building Tauri")
        .run(move |_app, event| {
            kill_on_exit(child_handle.clone(), &event);
        });
}
```

### Step 6: Create Python Backend

Create `src-backend/pyproject.toml`:

```toml
[project]
name = "tauri-todo-backend"
version = "0.1.0"
description = "Python backend for Tauri Vue app"
requires-python = ">=3.8"
dependencies = [
    "bottle",
    "sqlalchemy",
    "platformdirs",
]

[project.optional-dependencies]
dev = ["pyinstaller"]
```

Create `src-backend/main.py`:

```python
from bottle import Bottle, json_dumps, request

from sqlalchemy import (
    create_engine,
    Table,
    Column,
    Integer,
    String,
    MetaData,
)
from sqlalchemy import insert, delete, select
from platformdirs import user_data_dir
import os

APP_NAME = "TauriTodoPythonBackend"
DATA_APP_DIR = user_data_dir(APP_NAME)
os.makedirs(DATA_APP_DIR, exist_ok=True)

engine = create_engine(f"sqlite:///{DATA_APP_DIR}/tasks.db", future=True)
metadata = MetaData()

task_table = Table(
    "tasks",
    metadata,
    Column("id", Integer, primary_key=True),
    Column("name", String, nullable=False),
    Column("created_at", String),
)

metadata.create_all(engine)

app = Bottle()


@app.get("/")
def index():
    return json_dumps({"status": "running"})


@app.get("/tasks")
def tasks_get():
    with engine.begin() as conn:
        tasks_result = [dict(el) for el in conn.execute(select(task_table)).mappings()]
        return json_dumps({
            "message": "Getting tasks for client",
            "data": tasks_result,
        })


@app.post("/tasks")
def tasks_post():
    data = {
        "name": request.json.get("taskName", "no-name"),
        "created_at": request.json.get("createdAt"),
        "id": request.json.get("taskId"),
    }
    with engine.begin() as conn:
        conn.execute(insert(task_table).values(**data))
        print(f"Added task: {data['name']}")
    return json_dumps({"message": f"Created task name {data.get('name')}"})


@app.delete("/tasks")
def tasks_delete():
    task_id = request.json.get("taskId", "no-id")
    with engine.begin() as conn:
        conn.execute(delete(task_table).where(task_table.c.id == task_id))
    return json_dumps({"message": f"Deleted task of id {task_id}"})


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8000)
```

### Step 7: Create Vue Frontend

Update `src/utils.ts`:

```typescript
import { invoke } from "@tauri-apps/api/core";

export async function callPython(method: string, endpoint: string, payload?: any) {
  return await invoke("py_api", {
    method,
    endpoint,
    payload: payload || null,
  });
}
```

Update `src/App.vue`:

```vue
<script setup>
import { ref, onMounted } from "vue";
import { callPython } from "./utils";
import { listen } from "@tauri-apps/api/event";

const taskName = ref("");
const tasks = ref([]);

onMounted(async () => {
  try {
    tasks.value = await callPython("GET", "tasks").then((response) => response.data);
  } catch (e) {
    listen("backend-ready", async () => {
      tasks.value = await callPython("GET", "tasks").then((response) => response.data);
    });
  }
});

async function deleteTask(taskId) {
  tasks.value = tasks.value.filter((task) => task.id !== taskId);
  await callPython("DELETE", "tasks", { taskId });
}

async function addTask() {
  const task = {
    id: tasks.value.length + 1,
    createdAt: new Date().toISOString(),
    taskName: taskName.value,
  };
  await callPython("POST", "tasks", task);
  tasks.value.push({ ...task, name: task.taskName });
  taskName.value = "";
}
</script>

<template>
  <main class="container">
    <h1>Todo list demo</h1>
    <h2>Tauri + Vue + Python</h2>

    <form class="row" @submit.prevent="addTask">
      <input v-model="taskName" placeholder="Add task name..." />
      <button type="submit">Add task</button>
    </form>

    <div class="task-list">
      <div v-for="task in tasks" :key="task.id" class="task-row">
        <div class="task-name">{{ task.name }}</div>
        <button @click="deleteTask(task.id)">Delete</button>
      </div>
    </div>
  </main>
</template>

<style>
html, body {
  height: 100%;
  margin: 0;
  color: #f6f6f6;
  background-color: #2f2f2f;
}
#app {
  display: flex;
  justify-content: center;
  align-items: center;
}
</style>

<style scoped>
.task-list {
  padding: 1rem;
  margin-top: 2rem;
  width: 100%;
  border: white dotted 1px;
  border-radius: 5px;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
.task-row {
  background: white;
  padding: 4px 0;
  display: flex;
  border-radius: 5px;
  align-items: center;
}
.task-name {
  display: flex;
  justify-content: center;
  align-items: center;
  flex: 1;
  padding: 1px;
  color: black;
  text-transform: uppercase;
  font-size: 130%;
}
.task-row > button {
  background: red;
  padding: 4px 8px;
  margin-right: 1rem;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
.container {
  padding-top: 10vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  height: 400px;
  width: 600px;
  margin-top: 10vh;
}
.container h1 {
  font-size: 2.5em;
}
input, button {
  border-radius: 8px;
  border: 1px solid transparent;
  padding: 0.6em 1.2em;
  font-size: 1em;
  font-weight: 500;
  font-family: inherit;
  color: #0f0f0f;
  background-color: #ffffff;
  transition: border-color 0.25s;
  box-shadow: 0 2px 2px rgba(0, 0, 0, 0.2);
  margin-top: 2rem;
}
input {
  margin-right: 1rem;
}
button {
  background-color: green;
  color: #ffffff;
  cursor: pointer;
}
button:hover {
  outline: solid white 1px;
  box-sizing: border-box;
}
</style>
```

### Step 8: Create Package.json Scripts

Update `package.json`:

```json
{
  "name": "demo-todo-ru-py",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "tauri": "tauri"
  },
  "dependencies": {
    "vue": "^3.5.13",
    "@tauri-apps/api": "^2",
    "@tauri-apps/plugin-opener": "^2"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^5.2.1",
    "vite": "^6.0.3",
    "@tauri-apps/cli": "^2"
  }
}
```

### Step 9: Create Build Configuration

Create `Makefile`:

```makefile
BACKEND_NAME:=python_backend

HOST_ARCH := $(shell rustc -vV | grep host | awk '{print $$2}')

build-python-bin:
	cd src-backend && uv run pyinstaller main.py \
	--onefile \
	--name ${BACKEND_NAME} \
	--clean \
	--log-level=DEBUG \
	--collect-all sqlalchemy \
	--collect-all platformdirs

copy-python-bin: build-python-bin
	mkdir -p src-tauri/binaries
	cp src-backend/dist/${BACKEND_NAME} src-tauri/binaries/$(BACKEND_NAME)-$(HOST_ARCH)

build-app: copy-python-bin
	cd src-tauri && npm run tauri build

run-dev-ui:
	cd src-tauri && export TAURI_DEV=1 && npm run tauri dev

run-dev-backend:
	cd src-backend && uv run python main.py
```

---

## Testing

### Unit Tests (Python Backend)

Create `tests/test_backend.py`:

```python
import pytest
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src-backend'))

from main import app

@pytest.fixture
def client():
    from bottle import patch
    return app

def test_index_endpoint(client):
    """Test the index endpoint returns running status"""
    # Test would require mock server or test client
    pass

def test_tasks_crud():
    """Test task CRUD operations"""
    # Integration test would start the server
    pass
```

### Integration Tests (Vue Frontend)

Create `tests/frontend.spec.ts`:

```typescript
import { test, expect } from '@vitest/browser';

test('App loads and displays title', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('h1')).toHaveText('Todo list demo');
});

test('Can add a task', async ({ page }) => {
  await page.goto('/');
  await page.fill('input', 'Test Task');
  await page.click('button[type="submit"]');
  await expect(page.locator('.task-name')).toContainText('Test Task');
});
```

### Running Tests

```bash
# Python tests
cd src-backend && uv pip install pytest && uv run pytest ../tests/

# Vue frontend tests
npm run test:ui
```

---

## Building

### Development Mode

**Terminal 1 - Run Backend:**
```bash
make run-dev-backend
# or
cd src-backend && uv run python main.py
```

**Terminal 2 - Run UI:**
```bash
make run-dev-ui
# or
cd src-tauri && npm run tauri dev
```

### Production Build

```bash
# Build Python executable
make build-python-bin

# Build complete Tauri app
make build-app
```

The built app will be at:
- macOS: `src-tauri/target/release/bundle/dmg/demo-todo-ru-py_0.1.0_*.dmg`
- Windows: `src-tauri/target/release/bundle/msi/demo-todo-ru-py_0.1.0_*.msi`
- Linux: `src-tauri/target/release/bundle/deb/demo-todo-ru-py_0.1.0_*.deb`

---

## Troubleshooting

### Common Issues

1. **Python backend not starting**: Ensure port 8000 is available
2. **Tauri dev mode**: Set `TAURI_DEV=1` to skip auto-spawn backend
3. **Build errors**: Ensure all Rust dependencies are installed with `cargo build`
4. **Icon errors**: Create placeholder icons in `src-tauri/icons/`

### Useful Commands

```bash
# Check Rust dependencies
cd src-tauri && cargo check

# Check Vue build
npm run build

# Check Python dependencies
cd src-backend && uv pip list
```

---

## References

- Original Tutorial: https://hamza-senhajirhazi.medium.com/how-to-write-and-package-desktop-apps-with-tauri-vue-python-ecc08e1e9f2a
- Reference Repository: https://github.com/Senhaji-Rhazi-Hamza/tauri-vue-python-demo-todo
- Tauri Documentation: https://tauri.app/
- Vue Documentation: https://vuejs.org/
- Bottle Framework: https://bottlepy.org/

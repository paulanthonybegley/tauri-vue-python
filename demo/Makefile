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
	cd src-tauri && npm run tauri dev

run-dev-backend:
	cd src-backend && uv run python main.py

run-dev: run-dev-backend run-dev-ui
	@echo "Starting development backend..."
	@echo "Starting development UI..."

test: test-frontend test-backend

test-frontend:
	cd . && npm run test

test-backend:
	cd src-backend && uv run pytest ../tests/test_backend.py
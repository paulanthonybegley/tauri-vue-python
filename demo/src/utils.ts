import { invoke } from "@tauri-apps/api/core";

export async function callPython(method: string, endpoint: string, payload?: any) {
  return await invoke("py_api", {
    method,
    endpoint,
    payload: payload || null,
  });
}
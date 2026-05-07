<script setup>
import { ref, onMounted } from "vue";
import { callPython } from "./utils";
import { listen } from "@tauri-apps/api/event";

const taskName = ref("");
const tasks = ref([]);
const isLoading = ref(true);

onMounted(async () => {
  try {
    const response = await callPython("GET", "tasks");
    tasks.value = response.data;
    isLoading.value = false;
  } catch (e) {
    listen("backend-ready", async () => {
      try {
        const response = await callPython("GET", "tasks");
        tasks.value = response.data;
      } catch (err) {
        console.error("Failed to fetch tasks:", err);
      }
      isLoading.value = false;
    });
  }
});

async function deleteTask(taskId) {
  tasks.value = tasks.value.filter((task) => task.id !== taskId);
  await callPython("DELETE", "tasks", { taskId });
}

async function addTask() {
  if (!taskName.value.trim()) return;
  
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

    <div v-if="isLoading" class="loading">Loading...</div>

    <div v-else class="task-list">
      <div v-for="task in tasks" :key="task.id" class="task-row">
        <div class="task-name">{{ task.name }}</div>
        <button @click="deleteTask(task.id)" class="delete-btn">Delete</button>
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
.loading {
  margin-top: 2rem;
  color: #888;
}
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
.delete-btn {
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
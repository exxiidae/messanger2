<script setup lang="ts">
import { onMounted, ref } from "vue";
import Database from "@tauri-apps/plugin-sql";

import AppHeader from "./components/AppHeader.vue";
import MessageList from "./components/MessageList.vue";
import MessageComposer from "./components/MessageComposer.vue";

import type { Message } from "./types/message.ts";

const messages = ref<Message[]>([]);
const status = ref("Локальная история сообщений");

const users = ["Олег", "Миша", "Кирилл"];
const currentUser = ref(localStorage.getItem("currentUser") || "Олег");

let db: Database | null = null;
let currentUserId = 1;

async function loadMessages() {
  if (!db) return;

  messages.value = await db.select<Message[]>(
      `SELECT
       m.id,
       m.chat_id,
       m.author_id,
       u.display_name AS author,
       m.type,
       m.body,
       m.attachment,
       m.created_at,
       m.updated_at
     FROM messages m
     JOIN users u ON u.id = m.author_id
     WHERE m.chat_id = 1
     ORDER BY m.id ASC`
  );
}

async function resolveCurrentUserId() {
  if (!db) return;
  const rows = await db.select<{ id: number }[]>(
      "SELECT id FROM users WHERE display_name = $1 LIMIT 1",
      [currentUser.value]
  );
  currentUserId = rows[0]?.id ?? 1;
}

function changeUser(name: string) {
  currentUser.value = name;
  localStorage.setItem("currentUser", name);
  resolveCurrentUserId();
}

async function sendMessage(payload: { body?: string; attachment?: string }) {
  if (!db) return;

  const type = payload.attachment ? "image" : "text";
  const body = payload.attachment ? null : payload.body;
  const attachment = payload.attachment ?? null;

  await db.execute(
      "INSERT INTO messages (chat_id, author_id, type, body, attachment) VALUES ($1, $2, $3, $4, $5)",
      [1, currentUserId, type, body, attachment]
  );

  await loadMessages();
}

async function editMessage(id: number, newBody: string) {
  if (!db) return;
  await db.execute(
      "UPDATE messages SET body = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 AND author_id = $3",
      [newBody, id, currentUserId]
  );
  await loadMessages();
}

async function deleteMessage(id: number) {
  if (!db) return;
  await db.execute(
      "DELETE FROM messages WHERE id = $1 AND author_id = $2",
      [id, currentUserId]
  );
  await loadMessages();
}

onMounted(async () => {
  try {
    db = await Database.load("sqlite:messenger.db");
    await resolveCurrentUserId();
    await loadMessages();
    status.value = "Локальная история сообщений";
  } catch (error) {
    console.error(error);
    status.value = "Ошибка подключения в бд";
  }
});
</script>

<template>
  <main class="app">
    <AppHeader
        :status="status"
        :current-user="currentUser"
        :users="users"
        @change-user="changeUser"
    />
    <section class="chat">
      <div class="chat-info">
        <h2>Первый чат</h2>
        <p>strannost</p>
      </div>

      <MessageList
          :messages="messages"
          :current-user="currentUser"
          @edit="editMessage"
          @delete="deleteMessage"
      />

      <MessageComposer @send="sendMessage" />
    </section>
  </main>
</template>

<style scoped>
:global(*) {
  box-sizing: border-box;
}

:global(html) {
  background: #111318;
  color-scheme: dark;
}

:global(body) {
  margin: 0;
  font-family: Inter, system-ui, -apple-system, BlickMacSystemFont, "Segoe UI",
  sans-serif;
  color: #f2f3f5;
  background: #111318;
}

.app {
  height: 100vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.chat {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
}

.chat-info {
  padding: 20px 25px;
  border-bottom: 1px solid #252830;
  flex-shrink: 0;
}

.chat-info h2 {
  margin: 0;
  font-size: 16px;
}

.chat-info p {
  margin: 5px 0 0;
  color: #858c98;
}
</style>
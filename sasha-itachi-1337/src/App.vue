<script setup lang="ts">
import { onMounted, ref } from "vue";

import Database from "@tauri-apps/plugin-sql";

import AppHeader from "./components/AppHeader.vue";
import MessageList from "./components/MessageList.vue";
import MessageComposer from "./components/MessageComposer.vue";

import type { Message } from "./types/message.ts";

const messages = ref<Message[]>([]);

const status = ref("Гомер бартов выпустил");

let db: Database | null = null;

async function loadMessages() {
  if (!db) return;

  messages.value = await db.select<Message[]>(
      "SELECT id, author, body, created_at, updated_at FROM messages ORDER BY id ASC"
  );
}

async function sendMessage(body: string) {
  if (!db) return;

  await db.execute(
      "INSERT INTO messages (author, body) VALUES ($1, $2)",
      ["Вы", body]
  );

  await loadMessages();
}

async function editMessage(id: number, newBody: string) {
  if (!db) return;

  await db.execute(
      "UPDATE messages SET body = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2",
      [newBody, id]
  );

  await loadMessages();
}

async function deleteMessage(id: number) {
  if (!db) return;

  await db.execute("DELETE FROM messages WHERE id = $1", [id]);

  await loadMessages();
}

onMounted(async () => {
  try {
    db = await Database.load("sqlite:messenger.db");

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
    <AppHeader :status="status" />
    <section class="chat">
      <div class="chat-info">
        <h2>Первый чат</h2>
        <p>strannost</p>
      </div>

      <MessageList
          :messages="messages"
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
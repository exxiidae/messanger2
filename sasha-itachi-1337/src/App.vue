<script setup lang="ts">
import { onMounted, ref, computed } from "vue";
import Database from "@tauri-apps/plugin-sql";

import AppHeader from "./components/AppHeader.vue";
import MessageList from "./components/MessageList.vue";
import MessageComposer from "./components/MessageComposer.vue";
import SettingsModal from "./components/SettingsModal.vue";
import AvatarPicker from "./components/AvatarPicker.vue";
import UserManager from "./components/UserManager.vue";

import type { Message, User } from "./types/message.ts";

const messages = ref<Message[]>([]);
const dbUsers = ref<User[]>([]);
const status = ref("Локальная история сообщений");

const currentUser = ref(localStorage.getItem("currentUser") || "Олег");
const mode = ref<"user" | "admin">("user");

const theme = ref<"dark" | "light">(
    (localStorage.getItem("theme") as "dark" | "light") || "dark"
);
const settingsOpen = ref(false);
const viewingUser = ref<User | null>(null);

function viewUserProfile(authorName: string) {
  viewingUser.value =
      dbUsers.value.find((u) => u.display_name === authorName) ?? null;
}
const avatarPickerOpen = ref(false);

const users = computed(() =>
    dbUsers.value.filter((u) => !u.is_deleted).map((u) => u.display_name)
);

const currentUserRecord = computed(() =>
    dbUsers.value.find((u) => u.display_name === currentUser.value) ?? null
);

function applyTheme() {
  document.documentElement.setAttribute("data-theme", theme.value);
}

function changeTheme(newTheme: "dark" | "light") {
  theme.value = newTheme;
  localStorage.setItem("theme", newTheme);
  applyTheme();
}

let db: Database | null = null;
let currentUserId = 1;

async function loadUsers() {
  if (!db) return;
  dbUsers.value = await db.select<User[]>(
      "SELECT id, username, display_name, avatar_path, status, is_deleted FROM users ORDER BY id ASC"
  );
}

async function loadMessages() {
  if (!db) return;
  messages.value = await db.select<Message[]>(
      `SELECT
         m.id,
         m.chat_id,
         m.author_id,
         CASE WHEN u.is_deleted = 1 THEN '(аккаунт удалён)' ELSE u.display_name END AS author,
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
  mode.value = "user";
  resolveCurrentUserId();
}

function enterAdmin() {
  mode.value = "admin";
}

async function sendMessage(payload: { body?: string; attachment?: string }) {
  if (!db || mode.value !== "user") return;

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

// ===== Admin =====

async function addUser(username: string, displayName: string) {
  if (!db) return;
  try {
    await db.execute(
        "INSERT INTO users (username, display_name, status) VALUES ($1, $2, 'В сети')",
        [username, displayName]
    );
    await loadUsers();
  } catch (e) {
    alert("Не удалось добавить: " + e);
  }
}

async function deleteUser(id: number) {
  if (!db) return;
  if (!confirm("Удалить пользователя? Сообщения останутся.")) return;
  await db.execute("UPDATE users SET is_deleted = 1 WHERE id = $1", [id]);
  await loadUsers();
  await loadMessages();
}

// ===== Профиль =====

async function updateProfile(displayName: string, username: string) {
  if (!db || !currentUserRecord.value) return;
  try {
    await db.execute(
        "UPDATE users SET display_name = $1, username = $2 WHERE id = $3",
        [displayName, username, currentUserRecord.value.id]
    );
    // Если меняли текущее имя — переключаемся на новое
    if (currentUser.value !== displayName) {
      currentUser.value = displayName;
      localStorage.setItem("currentUser", displayName);
    }
    await loadUsers();
    await loadMessages();
  } catch (e) {
    alert("Не удалось обновить профиль: " + e);
  }
}

async function updateAvatar(path: string) {
  if (!db || !currentUserRecord.value) return;
  await db.execute(
      "UPDATE users SET avatar_path = $1 WHERE id = $2",
      [path, currentUserRecord.value.id]
  );
  await loadUsers();
}

onMounted(async () => {
  applyTheme();

  try {
    db = await Database.load("sqlite:messenger.db");
    await loadUsers();
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
        :mode="mode"
        :current-user="currentUser"
        :users="users"
        @change-user="changeUser"
        @enter-admin="enterAdmin"
        @open-settings="settingsOpen = true"
    />

    <section class="chat">
      <template v-if="mode === 'user'">
        <div class="chat-info">
          <h2>Первый чат</h2>
          <p>strannost</p>
        </div>

        <MessageList
            :messages="messages"
            :current-user="currentUser"
            :users="dbUsers"
            @edit="editMessage"
            @delete="deleteMessage"
            @view-profile="viewUserProfile"
        />

        <MessageComposer @send="sendMessage" />
      </template>

      <UserManager
          v-else
          :users="dbUsers"
          @add-user="addUser"
          @delete-user="deleteUser"
      />
    </section>

    <SettingsModal
        v-if="settingsOpen"
        :theme="theme"
        :current-user="currentUserRecord"
        @close="settingsOpen = false"
        @change-theme="changeTheme"
        @update-profile="updateProfile"
        @open-avatar-picker="avatarPickerOpen = true"
    />

    <AvatarPicker
        v-if="avatarPickerOpen && currentUserRecord"
        :username="currentUserRecord.username"
        @close="avatarPickerOpen = false"
        @pick="(path) => { updateAvatar(path); avatarPickerOpen = false; }"
    />
    <SettingsModal
        v-if="viewingUser"
        :theme="theme"
        :current-user="viewingUser"
        :readonly="true"
        @close="viewingUser = null"
        @change-theme="changeTheme"
        @update-profile="() => {}"
        @open-avatar-picker="() => {}"
    />
  </main>
</template>

<style scoped>
:global(*) { box-sizing: border-box; }

:global(html) {
  background: var(--bg);
  color-scheme: dark;
}

:global(html[data-theme="light"]) { color-scheme: light; }

:global(body) {
  margin: 0;
  font-family: Inter, system-ui, -apple-system, BlickMacSystemFont, "Segoe UI", sans-serif;
  color: var(--text);
  background: var(--bg);
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
  border-bottom: 1px solid var(--border-soft);
  flex-shrink: 0;
}

.chat-info h2 { margin: 0; font-size: 16px; }
.chat-info p { margin: 5px 0 0; color: var(--text-dim); }
</style>
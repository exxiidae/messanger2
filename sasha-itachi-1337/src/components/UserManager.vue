<script setup lang="ts">
import { ref } from "vue";
import Avatar from "./Avatar.vue";
import type { User } from "../types/message.ts";

const props = defineProps<{
  users: User[];
}>();

const emit = defineEmits<{
  addUser: [username: string, displayName: string];
  deleteUser: [id: number];
}>();

const newUsername = ref("");
const newDisplayName = ref("");

function submitAdd() {
  const u = newUsername.value.trim();
  const d = newDisplayName.value.trim();
  if (!u || !d) return;
  emit("addUser", u, d);
  newUsername.value = "";
  newDisplayName.value = "";
}
</script>

<template>
  <div class="user-manager">
    <h2>Управление пользователями</h2>

    <div class="add-form">
      <input v-model="newUsername" placeholder="username (латиница)" />
      <input v-model="newDisplayName" placeholder="Отображаемое имя" />
      <button type="button" @click="submitAdd">+ Добавить</button>
    </div>

    <div class="user-list">
      <div
          v-for="user in props.users"
          :key="user.id"
          class="user-row"
          :class="{ deleted: user.is_deleted }"
      >
        <Avatar :name="user.display_name" :avatar-path="user.avatar_path" :size="40" />
        <div class="user-info">
          <strong>{{ user.display_name }}</strong>
          <span>@{{ user.username }}</span>
        </div>
        <div class="actions">
          <span v-if="user.is_deleted" class="deleted-mark">удалён</span>
          <button
              v-else
              type="button"
              class="danger"
              @click="emit('deleteUser', user.id)"
          >
            🗑
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.user-manager {
  flex: 1;
  overflow-y: auto;
  padding: 24px;
}

.user-manager h2 {
  margin: 0 0 16px;
  font-size: 16px;
}

.add-form {
  display: flex;
  gap: 8px;
  margin-bottom: 20px;
}

.add-form input {
  flex: 1;
  padding: 8px 12px;
  border: 1px solid var(--border);
  border-radius: 6px;
  background: var(--bg-element);
  color: var(--text);
  font: inherit;
}

.add-form input:focus {
  border-color: var(--accent-border);
  outline: none;
}

.add-form button {
  padding: 0 16px;
  border: none;
  border-radius: 6px;
  background: var(--accent);
  color: white;
  font: inherit;
  font-weight: 600;
  cursor: pointer;
}

.add-form button:hover {
  background: var(--accent-hover);
}

.user-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.user-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  border: 1px solid var(--border-soft);
  border-radius: 8px;
  background: var(--bg-panel);
}

.user-row.deleted {
  opacity: 0.5;
}

.user-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.user-info strong {
  font-size: 14px;
}

.user-info span {
  font-size: 12px;
  color: var(--text-muted);
}

.actions button {
  padding: 6px 10px;
  border: none;
  border-radius: 6px;
  background: var(--bg-element);
  color: var(--danger);
  cursor: pointer;
  font-size: 16px;
}

.actions button:hover {
  background: var(--danger-bg-hover);
}

.deleted-mark {
  font-size: 12px;
  color: var(--text-muted);
  font-style: italic;
}
</style>
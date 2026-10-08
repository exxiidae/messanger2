<script setup lang="ts">
import { ref, watch } from "vue";
import Avatar from "./Avatar.vue";
import type { User } from "../types/message.ts";

const props = defineProps<{
  user: User | null;
  readonly?: boolean;
}>();

const emit = defineEmits<{
  update: [displayName: string, username: string];
  openAvatarPicker: [];
}>();

const draftName = ref("");
const draftUsername = ref("");

watch(
    () => props.user,
    (u) => {
      draftName.value = u?.display_name ?? "";
      draftUsername.value = u?.username ?? "";
    },
    { immediate: true }
);

function save() {
  const n = draftName.value.trim();
  const u = draftUsername.value.trim();
  if (!n || !u) return;
  emit("update", n, u);
}
</script>

<template>
  <div v-if="user" class="profile">
    <div class="avatar-row">
      <Avatar :name="user.display_name" :avatar-path="user.avatar_path" :size="72" />
      <button
          v-if="!readonly"
          type="button"
          class="change-avatar-btn"
          @click="emit('openAvatarPicker')"
      >
        Сменить аватар
      </button>
    </div>

    <div class="field">
      <label>Отображаемое имя</label>
      <input
          v-if="!readonly"
          v-model="draftName"
          type="text"
      />
      <p v-else class="readonly-text">{{ user.display_name }}</p>
    </div>

    <div class="field">
      <label>Username</label>
      <input
          v-if="!readonly"
          v-model="draftUsername"
          type="text"
      />
      <p v-else class="readonly-text">@{{ user.username }}</p>
    </div>

    <button
        v-if="!readonly"
        type="button"
        class="save-btn"
        @click="save"
    >
      Сохранить
    </button>
  </div>
</template>

<style scoped>
.profile {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.avatar-row {
  display: flex;
  align-items: center;
  gap: 16px;
}

.change-avatar-btn {
  padding: 8px 14px;
  border: 1px solid var(--border);
  border-radius: 6px;
  background: var(--bg-element);
  color: var(--text);
  font: inherit;
  cursor: pointer;
}

.change-avatar-btn:hover { background: var(--bg-hover); }

.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field label {
  font-size: 12px;
  color: var(--text-muted);
}

.field input {
  padding: 8px 12px;
  border: 1px solid var(--border);
  border-radius: 6px;
  background: var(--bg-element);
  color: var(--text);
  font: inherit;
}

.field input:focus {
  border-color: var(--accent-border);
  outline: none;
}

.readonly-text {
  margin: 0;
  padding: 8px 12px;
  border: 1px solid var(--border-soft);
  border-radius: 6px;
  background: var(--bg-element);
  color: var(--text);
  font-size: 14px;
}

.save-btn {
  align-self: flex-start;
  padding: 8px 18px;
  border: none;
  border-radius: 6px;
  background: var(--accent);
  color: white;
  font: inherit;
  font-weight: 600;
  cursor: pointer;
}

.save-btn:hover { background: var(--accent-hover); }
</style>
<script setup lang="ts">
import { ref } from "vue";
import ProfileSettings from "./ProfileSettings.vue";
import type { User } from "../types/message.ts";

defineProps<{
  theme: "dark" | "light";
  currentUser: User | null;
  readonly?: boolean;
}>();

const emit = defineEmits<{
  close: [];
  changeTheme: [theme: "dark" | "light"];
  updateProfile: [displayName: string, username: string];
  openAvatarPicker: [];
}>();

type Tab = "profile" | "theme";
const activeTab = ref<Tab>("profile");

const tabs: { id: Tab; label: string }[] = [
  { id: "profile", label: "Профиль" },
  { id: "theme", label: "Тема" },
];
</script>

<template>
  <div class="modal-overlay" @click="emit('close')">
    <div class="modal" @click.stop>
      <div class="modal-header">
        <h2>Настройки</h2>
        <button class="close-btn" type="button" @click="emit('close')">×</button>
      </div>

      <div v-if="!readonly" class="tabs">
        <button
            v-for="tab in tabs"
            :key="tab.id"
            type="button"
            class="tab-btn"
            :class="{ active: activeTab === tab.id }"
            @click="activeTab = tab.id"
        >
          {{ tab.label }}
        </button>
      </div>

      <div class="modal-body">
        <ProfileSettings
            v-if="readonly || activeTab === 'profile'"
            :user="currentUser"
            :readonly="readonly"
            @update="(n, u) => emit('updateProfile', n, u)"
            @open-avatar-picker="emit('openAvatarPicker')"
        />

        <div v-if="!readonly && activeTab === 'theme'" class="setting-row">
          <span>Тема</span>
          <div class="theme-switch">
            <button
                type="button"
                :class="{ active: theme === 'dark' }"
                @click="emit('changeTheme', 'dark')"
            >
              Тёмная
            </button>
            <button
                type="button"
                :class="{ active: theme === 'light' }"
                @click="emit('changeTheme', 'light')"
            >
              Светлая
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 2000;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--overlay);
}

.modal {
  width: 460px;
  max-width: 90vw;
  background: var(--bg-panel);
  border: 1px solid var(--border);
  border-radius: 12px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
  color: var(--text);
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid var(--border-soft);
}

.modal-header h2 { margin: 0; font-size: 16px; }

.close-btn {
  width: 32px;
  height: 32px;
  border: none;
  border-radius: 6px;
  background: transparent;
  color: var(--text);
  font-size: 22px;
  line-height: 1;
  cursor: pointer;
}

.close-btn:hover { background: var(--bg-hover); }

.tabs {
  display: flex;
  gap: 4px;
  padding: 10px 20px 0;
  border-bottom: 1px solid var(--border-soft);
}

.tab-btn {
  padding: 8px 14px;
  border: none;
  background: transparent;
  color: var(--text-muted);
  font: inherit;
  font-size: 13px;
  cursor: pointer;
  border-bottom: 2px solid transparent;
}

.tab-btn.active {
  color: var(--accent);
  border-bottom-color: var(--accent);
}

.modal-body { padding: 20px; }

.setting-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.setting-row > span { font-size: 14px; }

.theme-switch { display: flex; gap: 6px; }

.theme-switch button {
  padding: 6px 12px;
  border: 1px solid var(--border);
  border-radius: 6px;
  background: var(--bg-element);
  color: var(--text-muted);
  font: inherit;
  font-size: 13px;
  cursor: pointer;
}

.theme-switch button:hover { background: var(--bg-hover); }

.theme-switch button.active {
  background: var(--accent);
  border-color: var(--accent-border);
  color: white;
}
</style>
<script setup lang="ts">
defineProps<{
  status: string;
  mode: "user" | "admin";
  currentUser: string;
  users: string[];
}>();

const emit = defineEmits<{
  changeUser: [name: string];
  enterAdmin: [];
  openSettings: [];
}>();
</script>

<template>
  <header class="header">
    <div>
      <p>{{ status }}</p>
    </div>

    <div class="right-side">
      <div class="users">
        <button
            v-for="user in users"
            :key="user"
            type="button"
            class="user-btn"
            :class="{ active: mode === 'user' && user === currentUser }"
            @click="emit('changeUser', user)"
        >
          {{ user }}
        </button>

        <button
            type="button"
            class="user-btn admin-btn"
            :class="{ active: mode === 'admin' }"
            @click="emit('enterAdmin')"
        >
          Admin
        </button>
      </div>

      <button
          type="button"
          class="settings-btn"
          title="Настройки"
          @click="emit('openSettings')"
      >
        ⚙
      </button>
    </div>
  </header>
</template>

<style scoped>
.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 24px;
  border-bottom: 1px solid var(--border-soft);
  background: var(--bg-panel);
  flex-shrink: 0;
}

.header p { margin: 0; font-size: 12px; color: var(--text-muted); }

.right-side { display: flex; align-items: center; gap: 12px; }
.users { display: flex; gap: 8px; }

.user-btn {
  padding: 6px 12px;
  border: 1px solid var(--border);
  border-radius: 6px;
  background: var(--bg-element);
  color: var(--text-muted);
  font-size: 12px;
  font: inherit;
  cursor: pointer;
}

.user-btn:hover { background: var(--bg-hover); }

.user-btn.active {
  background: var(--accent);
  border-color: var(--accent-border);
  color: white;
}

.admin-btn.active {
  background: #b8860b;
  border-color: #d4a017;
  color: white;
}

.settings-btn {
  width: 34px;
  height: 34px;
  border: 1px solid var(--border);
  border-radius: 6px;
  background: var(--bg-element);
  color: var(--text-muted);
  font-size: 16px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.settings-btn:hover { background: var(--bg-hover); }
</style>
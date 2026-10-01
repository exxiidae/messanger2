<script setup lang="ts">
defineProps<{
  status: string;
  currentUser: string;
  users: string[];
}>();

const emit = defineEmits<{
  changeUser: [name: string];
}>();
</script>

<template>
  <header class="header">
    <div>
      <p>{{ status }}</p>
    </div>

    <div class="users">
      <button
          v-for="user in users"
          :key="user"
          type="button"
          class="user-btn"
          :class="{ active: user === currentUser }"
          @click="emit('changeUser', user)"
      >
        {{ user }}
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
  border-bottom: 1px solid #292c34;
  background: #17191f;
  flex-shrink: 0;
}

.header p {
  margin: 0;
  font-size: 12px;
  color: #8f96a3;
}

.users {
  display: flex;
  gap: 8px;
}

.user-btn {
  padding: 6px 12px;
  border: 1px solid #343842;
  border-radius: 6px;
  background: #20232a;
  color: #afb5c0;
  font-size: 12px;
  font: inherit;
  cursor: pointer;
}

.user-btn:hover {
  background: #2a2e36;
}

.user-btn.active {
  background: #386be0;
  border-color: #4f7fea;
  color: white;
}
</style>
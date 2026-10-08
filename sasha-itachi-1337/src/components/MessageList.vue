<script setup lang="ts">
import MessageBubble from "./MessageBubble.vue";
import type { Message, User } from "../types/message.ts";

const props = defineProps<{
  messages: Message[];
  currentUser: string;
  users: User[];
}>();

const emit = defineEmits<{
  edit: [id: number, body: string];
  delete: [id: number];
  viewProfile: [authorName: string];
}>();

function avatarFor(author: string): string | null {
  return props.users.find((u) => u.display_name === author)?.avatar_path ?? null;
}
</script>

<template>
  <div class="messages">
    <div v-if="messages.length === 0" class="empty">
      <strong>Пока пусто</strong>
      <span>Напишите первое сообщение</span>
    </div>

    <MessageBubble
        v-for="message in messages"
        :key="message.id"
        :message="message"
        :current-user="currentUser"
        :avatar-path="avatarFor(message.author)"
        @edit="(id, body) => emit('edit', id, body)"
        @delete="(id) => emit('delete', id)"
        @view-profile="(name) => emit('viewProfile', name)"
    />
  </div>
</template>

<style scoped>
.messages {
  flex: 1;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 24px;
  min-height: 0;
}

.empty {
  margin: auto;
  display: flex;
  flex-direction: column;
  gap: 6px;
  text-align: center;
  color: var(--text-dim);
}
</style>
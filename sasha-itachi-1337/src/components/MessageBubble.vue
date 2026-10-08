<script setup lang="ts">
import { ref, watch, computed, nextTick, onMounted, onBeforeUnmount } from "vue";
import { readFile, BaseDirectory } from "@tauri-apps/plugin-fs";
import Avatar from "./Avatar.vue";
import type { Message } from "../types/message.ts";

const props = defineProps<{
  message: Message;
  currentUser: string;
  avatarPath?: string | null;
}>();

const emit = defineEmits<{
  edit: [id: number, body: string];
  delete: [id: number];
}>();

const isMine = computed(() => props.message.author === props.currentUser);

const imgSrc = ref("");
const imageOpened = ref(false);

const isEditing = ref(false);
const draft = ref("");
const inputRef = ref<HTMLInputElement | null>(null);

const menuVisible = ref(false);
const menuX = ref(0);
const menuY = ref(0);

function openMenu(e: MouseEvent) {
  if (!isMine.value) return;
  e.preventDefault();
  menuX.value = e.clientX;
  menuY.value = e.clientY;
  menuVisible.value = true;
}

function closeMenu() { menuVisible.value = false; }

function startEdit() {
  closeMenu();
  draft.value = props.message.body ?? "";
  isEditing.value = true;
  nextTick(() => inputRef.value?.focus());
}

function cancelEdit() { isEditing.value = false; draft.value = ""; }

function saveEdit() {
  const body = draft.value.trim();
  if (!body) return;
  if (body === props.message.body) { cancelEdit(); return; }
  emit("edit", props.message.id, body);
  isEditing.value = false;
}

function confirmDelete() {
  closeMenu();
  if (confirm("Удалить сообщение?")) emit("delete", props.message.id);
}

onMounted(() => window.addEventListener("click", closeMenu));
onBeforeUnmount(() => window.removeEventListener("click", closeMenu));

watch(
    () => props.message.attachment ?? props.message.body,
    async (src) => {
      imgSrc.value = "";
      imageOpened.value = false;
      if (!src) return;
      if (!/\.(png|jpe?g|webp)$/i.test(src)) return;
      try {
        const bytes = await readFile(src, { baseDir: BaseDirectory.AppData });
        const ext = src.split(".").pop()!.toLowerCase();
        const mime = ext === "jpg" ? "jpeg" : ext;
        let binary = "";
        const chunkSize = 0x8000;
        for (let i = 0; i < bytes.length; i += chunkSize) {
          const chunk = bytes.subarray(i, Math.min(i + chunkSize, bytes.length));
          binary += String.fromCharCode(...chunk);
        }
        imgSrc.value = `data:image/${mime};base64,${btoa(binary)}`;
      } catch (e) {
        console.error("Не удалось прочитать картинку:", e);
      }
    },
    { immediate: true }
);

watch(
    () => props.currentUser,
    () => {
      menuVisible.value = false;
      if (isEditing.value) cancelEdit();
    }
);

function openImage() { if (imgSrc.value) imageOpened.value = true; }
function closeImage() { imageOpened.value = false; }
</script>

<template>
  <div class="message-row" :class="{ mine: isMine }">
    <Avatar
        v-if="!isMine"
        :name="message.author"
        :avatar-path="avatarPath ?? null"
        :size="32"
    />

    <article
        class="message"
        :class="{ mine: isMine, theirs: !isMine }"
        @contextmenu="openMenu"
    >
      <div v-if="!isMine" class="author-name">{{ message.author }}</div>

      <div v-if="isEditing" class="edit-row">
        <input
            ref="inputRef"
            v-model="draft"
            type="text"
            class="edit-input"
            @keydown.enter.prevent="saveEdit"
            @keydown.esc.prevent="cancelEdit"
        />
        <button type="button" class="save-btn" @click="saveEdit">ОК</button>
        <button type="button" class="cancel-btn" @click="cancelEdit">×</button>
      </div>

      <template v-else>
        <img v-if="imgSrc" :src="imgSrc" class="message-image" alt="Вложение" @click="openImage" />
        <p v-else>{{ message.body }}</p>
      </template>

      <footer>
        <span>{{ message.created_at }}</span>
        <span v-if="message.updated_at" class="edited-mark">(изменено)</span>
      </footer>
    </article>
  </div>

  <div
      v-if="menuVisible"
      class="context-menu"
      :style="{ top: menuY + 'px', left: menuX + 'px' }"
      @click.stop
  >
    <button v-if="!imgSrc" type="button" @click="startEdit">✎ Редактировать</button>
    <button type="button" class="danger" @click="confirmDelete">🗑 Удалить</button>
  </div>

  <div v-if="imageOpened" class="image-viewer" @click="closeImage">
    <button class="close-button" type="button" @click="closeImage">×</button>
    <img :src="imgSrc" class="image-viewer-image" alt="Увеличенное изображение" @click.stop />
  </div>
</template>

<style scoped>
.message-row {
  display: flex;
  align-items: flex-end;
  gap: 8px;
  max-width: 80%;
}

.message-row.mine {
  align-self: flex-end;
  flex-direction: row;
}

.message-row:not(.mine) {
  align-self: flex-start;
}

.message {
  max-width: 100%;
  margin: 0;
  padding: 10px 12px;
  border-radius: 10px;
}

.mine { background: var(--msg-mine-bg); }
.theirs { background: var(--msg-theirs-bg); }

.author-name {
  font-size: 11px;
  font-weight: 600;
  color: var(--text-muted);
  margin-bottom: 4px;
}

.message p { margin: 0; line-height: 1.45; overflow-wrap: anywhere; }

.message-image {
  display: block;
  max-width: 100%;
  max-height: 300px;
  border-radius: 6px;
  object-fit: contain;
  cursor: pointer;
}

.message footer {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 5px;
  margin-top: 6px;
  font-size: 10px;
}

.mine footer { color: var(--msg-mine-footer); }
.theirs footer { color: var(--msg-theirs-footer); }

.edited-mark { font-style: italic; opacity: 0.8; }

.edit-row { display: flex; gap: 6px; align-items: center; }
.edit-input { flex: 1; min-width: 0; padding: 6px 10px; border: 1px solid var(--msg-mine-footer); border-radius: 6px; background: var(--bg-element); color: var(--text); font: inherit; outline: none; }
.edit-input:focus { border-color: #ffffff; }
.save-btn, .cancel-btn { padding: 4px 10px; border: none; border-radius: 6px; cursor: pointer; font: inherit; font-weight: 600; color: white; }
.save-btn { background: #2aa84a; }
.save-btn:hover { background: #34c95b; }
.cancel-btn { background: #444851; }
.cancel-btn:hover { background: #5a5f6a; }

.context-menu { position: fixed; z-index: 999; min-width: 160px; padding: 4px; background: var(--bg-panel); border: 1px solid var(--border); border-radius: 8px; box-shadow: 0 8px 24px rgba(0, 0, 0, 0.5); display: flex; flex-direction: column; }
.context-menu button { padding: 8px 12px; border: none; border-radius: 6px; background: transparent; color: var(--text); text-align: left; font: inherit; cursor: pointer; }
.context-menu button:hover { background: var(--bg-hover); }
.context-menu button.danger { color: var(--danger); }
.context-menu button.danger:hover { background: var(--danger-bg-hover); }

.image-viewer { position: fixed; inset: 0; z-index: 1000; display: flex; align-items: center; justify-content: center; padding: 40px; background: rgba(0, 0, 0, 0.85); cursor: pointer; }
.image-viewer-image { max-width: 90vw; max-height: 90vh; object-fit: contain; border-radius: 8px; cursor: default; box-shadow: 0 10px 40px rgba(0, 0, 0, 0.5); }
.close-button { position: absolute; top: 20px; right: 25px; width: 42px; height: 42px; border: none; border-radius: 50%; background: var(--bg-element); color: white; font-size: 28px; line-height: 1; cursor: pointer; }
.close-button:hover { background: var(--bg-hover); }
</style>
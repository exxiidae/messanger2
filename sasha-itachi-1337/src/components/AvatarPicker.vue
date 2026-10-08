<script setup lang="ts">

import { open } from "@tauri-apps/plugin-dialog";
import { copyFile, mkdir, BaseDirectory } from "@tauri-apps/plugin-fs";

const props = defineProps<{
  username: string;
}>();

const emit = defineEmits<{
  close: [];
  pick: [path: string];
}>();

const emojis = ["😀", "😎", "🐱", "🐶", "🦊", "🐼", "🦁", "🐸", "🐙", "🦄", "👽", "🤖", "🎃", "💀", "🌟"];

async function pickFromEmoji(emoji: string) {
  try {
    // Создаём SVG с эмодзи и сохраняем как картинку
    await mkdir("avatars", { baseDir: BaseDirectory.AppData, recursive: true });
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256">
      <rect width="256" height="256" fill="#20232a"/>
      <text x="50%" y="50%" font-size="160" text-anchor="middle" dominant-baseline="central">${emoji}</text>
    </svg>`;
    const fileName = `avatars/${props.username}_emoji.svg`;

    // Пишем через fetch-blob + запись
    const blob = new Blob([svg], { type: "image/svg+xml" });
    const arrayBuf = await blob.arrayBuffer();
    const bytes = new Uint8Array(arrayBuf);

    // Используем writeFile через plugin-fs (нужен в capabilities: fs:allow-write-file)
    const { writeFile } = await import("@tauri-apps/plugin-fs");
    await writeFile(fileName, bytes, { baseDir: BaseDirectory.AppData });

    emit("pick", fileName);
  } catch (e) {
    console.error("Ошибка сохранения эмодзи-аватара:", e);
  }
}

async function pickFromPc() {
  try {
    const file = await open({
      multiple: false,
      directory: false,
      filters: [{ name: "Images", extensions: ["png", "jpg", "jpeg", "webp"] }],
    });

    if (!file || Array.isArray(file)) return;

    const ext = file.split(".").pop() || "png";
    const fileName = `avatars/${props.username}.${ext}`;

    await mkdir("avatars", { baseDir: BaseDirectory.AppData, recursive: true });
    await copyFile(file, fileName, { toPathBaseDir: BaseDirectory.AppData });

    emit("pick", fileName);
  } catch (e) {
    console.error("Ошибка загрузки аватара:", e);
  }
}
</script>

<template>
  <div class="picker-overlay" @click="emit('close')">
    <div class="picker" @click.stop>
      <div class="picker-header">
        <h3>Выбрать аватар</h3>
        <button type="button" class="close-btn" @click="emit('close')">×</button>
      </div>

      <div class="picker-body">
        <button type="button" class="upload-btn" @click="pickFromPc">
          📁 Загрузить с ПК
        </button>

        <div class="emoji-grid">
          <button
              v-for="emoji in emojis"
              :key="emoji"
              type="button"
              class="emoji-btn"
              @click="pickFromEmoji(emoji)"
          >
            {{ emoji }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.picker-overlay {
  position: fixed;
  inset: 0;
  z-index: 3000;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--overlay);
}

.picker {
  width: 420px;
  max-width: 90vw;
  background: var(--bg-panel);
  border: 1px solid var(--border);
  border-radius: 12px;
  color: var(--text);
}

.picker-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 18px;
  border-bottom: 1px solid var(--border-soft);
}

.picker-header h3 {
  margin: 0;
  font-size: 15px;
}

.close-btn {
  width: 30px;
  height: 30px;
  border: none;
  border-radius: 6px;
  background: transparent;
  color: var(--text);
  font-size: 22px;
  line-height: 1;
  cursor: pointer;
}

.close-btn:hover { background: var(--bg-hover); }

.picker-body { padding: 16px 18px; }

.upload-btn {
  width: 100%;
  padding: 10px;
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--bg-element);
  color: var(--text);
  font: inherit;
  cursor: pointer;
  margin-bottom: 14px;
}

.upload-btn:hover { background: var(--bg-hover); }

.emoji-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 8px;
}

.emoji-btn {
  padding: 10px;
  border: 1px solid transparent;
  border-radius: 8px;
  background: var(--bg-element);
  font-size: 24px;
  cursor: pointer;
}

.emoji-btn:hover {
  background: var(--bg-hover);
  border-color: var(--accent-border);
}
</style>
<script setup lang="ts">
import { ref, watch } from "vue";
import { readFile, BaseDirectory } from "@tauri-apps/plugin-fs";

const props = defineProps<{
  name: string;
  avatarPath: string | null;
  size?: number;
}>();

const imgSrc = ref("");

// Палитра для фона (когда нет картинки)
const colors = [
  "#e57373", "#f06292", "#ba68c8", "#9575cd", "#7986cb",
  "#64b5f6", "#4fc3f7", "#4dd0e1", "#4db6ac", "#81c784",
  "#aed581", "#ffb74d", "#ff8a65", "#a1887f",
];

// Стабильный цвет для имени
function colorFor(name: string): string {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  return colors[Math.abs(hash) % colors.length];
}

const letter = () => (props.name || "?").trim().charAt(0).toUpperCase();

watch(
    () => props.avatarPath,
    async (path) => {
      imgSrc.value = "";
      if (!path) return;
      try {
        const bytes = await readFile(path, { baseDir: BaseDirectory.AppData });
        const ext = path.split(".").pop()!.toLowerCase();
        const mime = ext === "jpg" ? "jpeg" : ext;
        let binary = "";
        const chunkSize = 0x8000;
        for (let i = 0; i < bytes.length; i += chunkSize) {
          const chunk = bytes.subarray(i, Math.min(i + chunkSize, bytes.length));
          binary += String.fromCharCode(...chunk);
        }
        imgSrc.value = `data:image/${mime};base64,${btoa(binary)}`;
      } catch (e) {
        console.error("Не удалось прочитать аватар:", e);
      }
    },
    { immediate: true }
);
</script>

<template>
  <div
      class="avatar"
      :style="{
        width: (size ?? 32) + 'px',
        height: (size ?? 32) + 'px',
        background: imgSrc ? 'transparent' : colorFor(name),
      }"
  >
    <img v-if="imgSrc" :src="imgSrc" class="avatar-img" alt="" />
    <span v-else class="avatar-letter">{{ letter() }}</span>
  </div>
</template>

<style scoped>
.avatar {
  border-radius: 50%;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  color: white;
  font-weight: 600;
  user-select: none;
}

.avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar-letter {
  font-size: 14px;
  line-height: 1;
}
</style>
-- 1. Создаём таблицу пользователей
CREATE TABLE IF NOT EXISTS users (
                                     id INTEGER PRIMARY KEY AUTOINCREMENT,
                                     username TEXT NOT NULL UNIQUE,
                                     display_name TEXT NOT NULL,
                                     avatar_path TEXT,
                                     status TEXT NOT NULL DEFAULT '',
                                     created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Заполняем тремя пользователями
INSERT OR IGNORE INTO users (id, username, display_name, status) VALUES
    (1, 'oleg227', 'Олег', 'В сети'),
    (2, 'kirill2010', 'Кирилл', 'В сети'),
    (3, 'mishasigma', 'Миша', 'В сети');

-- 3. Создаём таблицу чатов
CREATE TABLE IF NOT EXISTS chats (
                                     id INTEGER PRIMARY KEY AUTOINCREMENT,
                                     title TEXT NOT NULL,
                                     created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT OR IGNORE INTO chats (id, title) VALUES (1, 'Первый чат');

-- 4. Переносим старых авторов в users
INSERT OR IGNORE INTO users (username, display_name)
SELECT
    'legacy_' || CAST(old_authors.first_message_id AS TEXT),
    old_authors.author
FROM (
         SELECT MIN(id) AS first_message_id, author
         FROM messages
         GROUP BY author
     ) AS old_authors
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE users.display_name = old_authors.author
);

-- 5. Новая структура messages
CREATE TABLE messages_new (
                              id INTEGER PRIMARY KEY AUTOINCREMENT,
                              chat_id INTEGER NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
                              author_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
                              type TEXT NOT NULL DEFAULT 'text',
                              body TEXT,
                              attachment TEXT,
                              created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                              updated_at TEXT,
                              CHECK (type IN ('text', 'image'))
);

-- 6. Переносим старые сообщения
INSERT INTO messages_new (id, chat_id, author_id, type, body, attachment, created_at, updated_at)
SELECT
    messages.id,
    1,
    (SELECT users.id FROM users WHERE users.display_name = messages.author ORDER BY users.id ASC LIMIT 1),
    'text',
    messages.body,
    NULL,
    messages.created_at,
    messages.updated_at
FROM messages;

-- 7. Заменяем старую таблицу
DROP TABLE messages;
ALTER TABLE messages_new RENAME TO messages;

-- 8. Индексы
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_author_id ON messages(author_id);
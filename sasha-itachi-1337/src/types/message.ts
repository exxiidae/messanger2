export interface Message {
    id: number;
    chat_id: number;
    author_id: number;
    author: string;
    type: "text" | "image";
    body: string | null;
    attachment: string | null;
    created_at: string;
    updated_at: string | null;
}

export interface User {
    id: number;
    username: string;
    display_name: string;
    status: string;
}
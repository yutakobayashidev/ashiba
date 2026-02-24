"use client";

import { createPost } from "@/actions/post";
import { useAction } from "next-safe-action/hooks";
import { useState } from "react";

export default function Post() {
  const [content, setContent] = useState("");

  const { execute, result } = useAction(createPost);

  return (
    <div>
      <h1 className="text-xl">Post</h1>
      <input
        type="text"
        value={content}
        onChange={(event) => {
          setContent(event.target.value);
        }}
        placeholder="Post something"
      />
      <button
        onClick={async () => {
          await execute({ content });
        }}
      >
        Post
      </button>
      <div>{JSON.stringify(result)}</div>
    </div>
  );
}

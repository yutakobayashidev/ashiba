"use server"

import { authActionClient } from "@/libs/safe-action";
import * as v from 'valibot';

const postSchema = v.object({
    content: v.string(),
});

export const createPost = authActionClient.schema(postSchema).action(async ({ parsedInput: { content } }) => {

    return { success: true, data: { content } };
});
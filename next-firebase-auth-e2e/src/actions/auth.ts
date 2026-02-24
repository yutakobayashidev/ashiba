"use server";

import { actionClient } from "@/libs/safe-action";
import { cookies } from "next/headers";
import * as v from 'valibot'
import {
    auth,
    createSessionCookie,
    revokeAllSessions,
} from "@/libs/firebase/firebase-admin";

const signinSchema = v.object({
    idToken: v.string(),
});

export const signin = actionClient
    .schema(signinSchema)
    .action(async ({ parsedInput: { idToken } }) => {
        const cookieStore = await cookies();
        const decodedToken = await auth.verifyIdToken(idToken);

        const { uid, picture, name } = decodedToken;

        const sessionCookie = await createSessionCookie(idToken, { expiresIn: 14 * 24 * 60 * 60 * 1000 });

        cookieStore.set("__session", sessionCookie, {
            maxAge: 14 * 24 * 60 * 60 * 1000,
            httpOnly: true,
            secure: true,
        });

        return { success: true, data: { uid, picture, name } };
    });

export const signout = actionClient.action(async () => {
    const sessionCookie = (await cookies()).get("__session")?.value;

    if (sessionCookie == undefined) {
        return { success: false, error: "Session not found." };
    }

    (await cookies()).delete("__session");

    await revokeAllSessions(sessionCookie);

    return { success: true, data: "Signed out successfully." };
});
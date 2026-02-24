import type { BrowserContext, TestType } from "@playwright/test";
import type { CreateRequest } from "firebase-admin/auth";
import { auth, createSessionCookie } from "../../src/libs/firebase/firebase-admin";
import type { TestFixtures, WorkerFixtures } from "../fixtures";

async function getIdToken(customToken: string) {
    const response = await fetch(
        `http://localhost:9099/www.googleapis.com/identitytoolkit/v3/relyingparty/verifyCustomToken?key=${process.env.NEXT_PUBLIC_FIREBASE_API_KEY}`,
        {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                token: customToken,
                returnSecureToken: true,
                expiresIn: 60 * 60 * 24 * 5 * 1000,
            }),
        }
    );

    const data = await response.json();

    const { idToken } = data;

    return idToken;
}

export async function createAuthState(context: BrowserContext, user: CreateRequest) {
    try {
        await auth.getUserByEmail(user.email as string);
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } catch (error: any) {
        if (error.code === "auth/user-not-found") {
            await auth.createUser(user);
        } else {
            throw error;
        }
    }

    const customToken = await auth.createCustomToken(user.uid as string);

    const idToken = await getIdToken(customToken);

    const sessionCookie = await createSessionCookie(idToken, { expiresIn: 60 * 60 * 24 * 5 * 1000 });

    await context.addCookies([
        {
            name: "__session",
            value: sessionCookie,
            domain: "localhost",
            path: "/",
            httpOnly: true,
            secure: false,
            sameSite: "Lax" as const,
            expires: Math.round((Date.now() + 60 * 60 * 24 * 5 * 1000) / 1000),
        },
    ]);

    await context.storageState({
        path: getStorageStatePath(user.uid ?? ""),
    });
}

export async function useUser<T extends TestType<TestFixtures, WorkerFixtures>>(
    test: T,
    userId: string
) {
    test.use({ storageState: getStorageStatePath(userId) });
}

function getStorageStatePath(id: string) {
    return `e2e/.auth/${id}.json`;
}
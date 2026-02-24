import { cert, getApps, initializeApp } from "firebase-admin/app";
import { cookies } from "next/headers";
import { getAuth } from "firebase-admin/auth";
import type { SessionCookieOptions } from "firebase-admin/auth";

const firebaseApp =
    getApps()[0] ??
    initializeApp({
        credential: cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY as string)),
    });

export const auth = getAuth(firebaseApp);

async function isUserAuthenticated(session: string | undefined = undefined) {
    const _session = session ?? (await getSession());
    if (_session == null) return false;

    try {
        const isRevoked = !(await auth.verifySessionCookie(_session, true));
        return !isRevoked;
    } catch {
        return false;
    }
}

export async function getCurrentUser() {
    const session = await getSession();

    if (!(await isUserAuthenticated(session))) {
        return null;
    }

    const decodedIdToken = await auth.verifySessionCookie(session!);

    const currentUser = await auth.getUser(decodedIdToken.uid);

    return currentUser;
}

async function getSession() {
    try {
        return (await cookies()).get("__session")?.value;
    } catch {
        return undefined;
    }
}

export async function createSessionCookie(
    idToken: string,
    sessionCookieOptions: SessionCookieOptions
) {
    return auth.createSessionCookie(idToken, sessionCookieOptions);
}

export async function revokeAllSessions(session: string) {
    const decodedIdToken = await auth.verifySessionCookie(session);

    return await auth.revokeRefreshTokens(decodedIdToken.sub);
}
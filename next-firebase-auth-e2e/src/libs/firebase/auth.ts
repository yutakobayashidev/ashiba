import {
    GoogleAuthProvider,
    connectAuthEmulator,
    getAuth,
    signInWithPopup,
    type Auth as FirebaseAuth,
} from "firebase/auth";
import { getApps, initializeApp, type FirebaseApp } from "firebase/app";
import { signin, signout } from "@/actions/auth";

const firebaseConfig = {
    apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
    authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
    projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
    storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
    appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

const getFirebaseApp = (): FirebaseApp | undefined => {
    if (typeof window === "undefined") return;

    return getApps()[0] || initializeApp(firebaseConfig);
};

async function setupEmulators(auth: FirebaseAuth) {
    try {
        const authUrl = "http://localhost:9099";
        connectAuthEmulator(auth, authUrl, {
            disableWarnings: true,
        });
    } catch (error) {
        console.info("🔥 Firebase Auth: not emulated", error);
    }
}

const getFirebaseAuth = (): FirebaseAuth => {
    const auth = getAuth(getFirebaseApp());

    if (process.env.NODE_ENV === "development") {
        console.info("🔥 Firebase Auth: emulated");
        setupEmulators(auth);
    }

    return auth;
};

export async function signInWithGoogle() {
    const auth = getFirebaseAuth();
    const provider = new GoogleAuthProvider();

    const userCreds = await signInWithPopup(auth, provider);
    const idToken = await userCreds.user.getIdToken();

    const currentUser = await signin({ idToken });

    if (currentUser?.data != null) {
        return currentUser.data;
    }

    return null;
}

export async function signOut() {
    const auth = getFirebaseAuth();

    await auth.signOut();

    const response = await signout();

    return response;
}
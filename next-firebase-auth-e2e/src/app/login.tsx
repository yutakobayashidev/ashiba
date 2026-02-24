"use client";

import { signout } from "@/actions/auth";
import { signInWithGoogle } from "@/libs/firebase/auth";
import { useRouter } from "next/navigation";

export default function Login() {
  const router = useRouter();

  const onGoogleLogin = async () => {
    const currentUser = await signInWithGoogle();

    if (currentUser != null) {
      router.refresh();
    }
  };

  const handleSignout = async () => {
    await signout();

    router.refresh();
  };

  return (
    <div>
      <button onClick={onGoogleLogin}>Sign in with Google</button>
      <button onClick={handleSignout}>Sign out</button>
    </div>
  );
}

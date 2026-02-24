import { getCurrentUser } from "@/libs/firebase/firebase-admin";
import Login from "./login";
import Post from "./post";

export default async function Page() {
  const user = await getCurrentUser();

  return (
    <div>
      <h1 className="text-xl">Home</h1>
      <Login />
      <div>
        {user ? (
          <div>
            <p>Welcome, {user.displayName}!</p>
            <div>{JSON.stringify(user)}</div>
          </div>
        ) : (
          <p>Please sign in to continue.</p>
        )}
      </div>
      <Post />
    </div>
  );
}

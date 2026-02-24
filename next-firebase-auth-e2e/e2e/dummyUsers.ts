import type { CreateRequest } from "firebase-admin/auth";

type RemoveNullish<T> = {
    [K in keyof T]-?: NonNullable<T[K]>;
};

type NonNullableUser = RemoveNullish<
    Pick<CreateRequest, "uid" | "email" | "password" | "displayName" | "emailVerified">
>;

export const user1: NonNullableUser = {
    uid: "user123",
    email: "user@example.com",
    password: "User1SecurePassword!",
    displayName: "John Doe",
    emailVerified: false,
};
import "server-only";

import { createSafeActionClient } from "next-safe-action";
import { valibotAdapter } from "next-safe-action/adapters/valibot";
import { DEFAULT_SERVER_ERROR_MESSAGE } from "next-safe-action";
import { getCurrentUser } from "./firebase/firebase-admin";

class BaseError extends Error {
    readonly cause?: unknown;

    constructor(message: string, options?: { cause: unknown }) {
        super(message);
        this.cause = options?.cause;
    }
}

export class ActionError extends BaseError {
    override readonly name = "ActionError" as const;
}


export const actionClient = createSafeActionClient({
    validationAdapter: valibotAdapter(),
    handleServerError(e) {

        if (e instanceof ActionError) {
            return e.message;
        }

        return DEFAULT_SERVER_ERROR_MESSAGE;
    },
});

export const authActionClient = actionClient.use(async ({ next }) => {
    const user = await getCurrentUser();

    if (user === null) {
        throw new ActionError("Auth required.");
    }

    return next({ ctx: { user } });
});
import { user1 } from "../dummyUsers";
import { test } from "../fixtures";
import { useUser } from "../helpers/users";

test.describe("no signin", () => {
    test("Please sign in to continue", async ({
        topPage,
    }) => {
        await topPage.goTo();

        await topPage.expectUI("signOut");
    });
});

test.describe("signin", () => {

    useUser(test, user1.uid);

    test("Welcome", async ({ topPage }) => {

        await topPage.goTo();

        await topPage.expectUI("signIn", user1);

    });
});
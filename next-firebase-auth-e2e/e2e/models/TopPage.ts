import { expect } from "@playwright/test";
import { CreateRequest } from "firebase-admin/auth";
import { Base } from "./Base";

export class TopPage extends Base {

    async goTo() {
        await this.page.waitForLoadState("networkidle");

        return await this.page.goto("/");
    }

    async expectUI(state: "signIn" | "signOut", user?: CreateRequest) {
        if (state === "signIn") {
            await expect(this.page.locator("text=Welcome, " + user?.displayName + "!")).toBeVisible();
        } else {
            await expect(this.page.locator("text=Please sign in to continue.")).toBeVisible();
        }

    }
}
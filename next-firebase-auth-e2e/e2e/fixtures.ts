import { test as base } from "@playwright/test";
import { TopPage } from "./models/TopPage";

export type TestFixtures = {
    topPage: TopPage;
    storageState: string;
};

export type WorkerFixtures = object;

export const test = base.extend<TestFixtures, WorkerFixtures>({
    topPage: ({ page }, use) => {
        // eslint-disable-next-line react-hooks/rules-of-hooks
        use(new TopPage(page));
    },
});
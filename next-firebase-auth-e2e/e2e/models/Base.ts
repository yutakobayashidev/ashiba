import { type Page } from "@playwright/test";

export class Base {
    page: Page;

    constructor(page: Page) {
        this.page = page;
    }
}
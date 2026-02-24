import { defineConfig, devices } from "@playwright/test";
import { loadEnvConfig } from "@next/env";

loadEnvConfig(process.cwd());

export default defineConfig({
    testDir: "./e2e",
    fullyParallel: false,
    workers: 1,
    use: {
        baseURL: process.env.NEXT_PUBLIC_BASE_URL,
    },
    webServer: {
        command: "pnpm start",
        port: 3000,
        reuseExistingServer: true,
        stdout: "pipe",
    },
    projects: [
        {
            name: "setup",
            testMatch: /.\/e2e\/setup\/.*.ts/,
            fullyParallel: true,
        },
        {
            name: "chrome",
            use: {
                ...devices["Desktop Chrome"],
                headless: true,
                launchOptions: {
                    args: [],
                },
            },
            dependencies: ["setup"],
        },
    ],
});
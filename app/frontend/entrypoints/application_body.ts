
import { dataThemeColorInit } from '@typescript/module/data_theme.ts';
import { dataThemeFontInit } from '@typescript/module/data_font.ts';

let initRun = 0; // guards against overlapping turbo:load events

async function runInitializers() {
    try { dataThemeColorInit(); } catch (e) { console.error("dataThemeColorInit() failed", e); }
    try { dataThemeFontInit(); } catch (e) { console.error("dataThemeFontInit() failed", e); }
}

async function initApp() {
    const runId = ++initRun;

    // Start the top header loading bar as soon as body scripts begin
    document.dispatchEvent(new CustomEvent("app:loading:start"));

    try {
        await runInitializers();
    } finally {
        if (runId === initRun) {
            document.dispatchEvent(new CustomEvent("app:loading:finish"));
        }
    }
}

/**
 * DOMContentLoaded replaced with "turbo:load" as it loads every time DOM reloads
 */
declare global { interface Window { __APP_INIT_BOUND?: boolean } }

if (!window.__APP_INIT_BOUND) {
    window.__APP_INIT_BOUND = true
    document.addEventListener("turbo:load", initApp)
}

// HMR cleanup to avoid accumulating bindings in dev
if ((import.meta as any).hot) {
    (import.meta as any).hot.accept?.()
    ;(import.meta as any).hot.dispose?.(() => {
        document.removeEventListener("turbo:load", initApp)
        window.__APP_INIT_BOUND = false
    })
}



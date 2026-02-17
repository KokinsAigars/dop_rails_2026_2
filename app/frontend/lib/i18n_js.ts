import enRaw from "@frontend/locales/en.json";
import lvRaw from "@frontend/locales/lv.json";

// console.log("init() lib/i18n_js.ts")
// console.log(enRaw);
// console.log(lvRaw);

const DEBUG = false; // flip on to debug lookup/locale flow

type Dict = Record<string, unknown>;
type Bundle = Record<string, Dict>;

// --- helpers
function isDict(v: unknown): v is Dict {
    return !!v && typeof v === "object";
}

function normalize(raw: Dict, code: string): Dict {
    // Support either {en:{...}} or flat {...}
    const pick = isDict(raw) ? (raw as Dict)[code] : undefined;
    const out = (isDict(pick) ? (pick as Dict) : raw) as Dict;
    if (DEBUG) console.log(`[i18n] normalize(${code}): rootKeys=`, Object.keys(out || {}));
    return out || {};
}

const bundles: Bundle = {
    en: normalize(enRaw as Dict, "en"),
    lv: normalize(lvRaw as Dict, "lv"),
};

const FALLBACK = "en" as const;

// --- locale source of truth = <html lang>
function htmlLang(): string {
    const raw = (typeof document !== "undefined" && document.documentElement.lang) || FALLBACK;
    const code = raw.split("-")[0].toLowerCase();
    return bundles[code] ? code : FALLBACK;
}

export function currentLocale(): string {
    return htmlLang();
}

export function setHtmlLocale(locale: string) {
    // Optional helper: let app code drive locale by setting <html lang>
    const code = locale.split("-")[0].toLowerCase();
    document.documentElement.lang = bundles[code] ? code : FALLBACK;
}

// --- events
function dispatchLocaleChanged(locale: string) {
    if (DEBUG) console.log("[i18n] dispatch locale-changed:", locale);
    window.dispatchEvent(new CustomEvent("i18n:locale-changed", { detail: { locale } }));
}

// --- lookup + interpolation
function lookup(obj: Dict, path: string): unknown {
    return path.split(".").reduce<unknown>((acc, key) => {
        if (isDict(acc) && key in acc) return (acc as Dict)[key];
        return undefined;
    }, obj);
}

function interpolate(str: string, vars?: Record<string, unknown>): string {
    if (!vars) return str;
    return str.replace(/%\{([^}]+)\}/g, (_, k: string) => String(vars[k] ?? ""));
}

// --- public translate
export function t(key: string, vars?: Record<string, unknown>, forceLocale?: string): string {
    const active = (forceLocale ? forceLocale.split("-")[0] : currentLocale()).toLowerCase();
    const primary = bundles[active];
    const fallback = bundles[FALLBACK];

    // 1) active locale
    const v1 = lookup(primary, key);
    if (typeof v1 === "string") return interpolate(v1, vars);

    // 2) fallback (en)
    const v2 = lookup(fallback, key);
    if (typeof v2 === "string") return interpolate(v2, vars);

    if (DEBUG) console.warn(`[i18n] missing key "${key}" for locales [${active}, ${FALLBACK}]`);
    return key; // final fallback: return key
}

// --- observer: watch <html lang> changes and notify
export function startLangObserver() {
    // prevent multiple observers
    if ((globalThis as any).__i18nLangObserverStarted) return;
    (globalThis as any).__i18nLangObserverStarted = true;

    if (DEBUG) console.log("[i18n] startLangObserver()");
    // fire once with current locale so listeners can initialize
    dispatchLocaleChanged(currentLocale());

    const obs = new MutationObserver(() => {
        const lang = currentLocale();
        if (DEBUG) console.log("[i18n] <html lang> mutated ->", lang);
        dispatchLocaleChanged(lang);
    });

    obs.observe(document.documentElement, { attributes: true, attributeFilter: ["lang"] });
    (globalThis as any).__i18nLangObserver = obs;

    // optional debug handle
    (window as any).__i18n = { t, bundles, currentLocale, setHtmlLocale };
}

// --- windows DEBUG overlay (if DEBUG === true)
function createDebugOverlay() {
    if (!DEBUG) return;
    if (document.getElementById("i18n-debug-overlay")) return;

    const div = document.createElement("div");
    div.id = "i18n-debug-overlay";
    div.textContent = `🌐 locale: ${currentLocale()}`;
    Object.assign(div.style, {
        position: "fixed",
        bottom: "8px",
        right: "10px",
        background: "rgba(0,0,0,0.7)",
        color: "white",
        fontSize: "12px",
        padding: "4px 8px",
        borderRadius: "6px",
        fontFamily: "monospace",
        zIndex: "99999",
        opacity: "0.7",
        pointerEvents: "none",
    });

    document.body.appendChild(div);

    window.addEventListener("i18n:locale-changed", (e: Event) => {
        const locale = (e as CustomEvent).detail.locale;
        div.textContent = `🌐 locale: ${locale}`;
        div.style.opacity = "1";
        setTimeout(() => (div.style.opacity = "0.7"), 800);
    });
}

createDebugOverlay();


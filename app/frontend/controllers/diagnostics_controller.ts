import { Controller } from "@hotwired/stimulus";

type Report = {
    viewport: string;
    dpr: number;
    ua: string;
    online: boolean;
    lang: string;
    cookieEnabled: boolean;
    localStorage: boolean;
    sessionStorage: boolean;
    hwConcurrency: number | null;
    memoryGB: number | null;
    webgl: boolean;
    serviceWorker: boolean;
    prefersReducedMotion: boolean | null;
};

export default class extends Controller<HTMLElement> {
    static targets = ["openBtn", "content", "attachModal"] as string[];

    declare readonly openBtnTarget: HTMLElement;
    declare readonly contentTarget: HTMLElement;
    declare readonly attachModalTarget: HTMLElement;

    connect() {
        // Auto-show if something looks problematic (e.g., very small viewport)
        const vw = Math.min(window.innerWidth, window.outerWidth || Infinity);
        if (vw < 360) this.open();
    }

    open() {
        const report = this.buildReport();
        this.render(report);
        // Ask the modal controller to open
        const modal = this.element.querySelector<HTMLElement>("[data-controller~='modal']");
        (modal as any)?.controller?.open?.(); // if you store controller instance
        // Or trigger by DOM method:
        modal?.dispatchEvent(new CustomEvent("open", { bubbles: true }));
        // Fallback: call the action directly if you expose it
        (modal as any)?.modalController?.open?.();
        // Easiest: add a data-action on a hidden button to modal#open and click it — see example below
    }

    render(r: Report) {
        this.contentTarget.innerHTML = `
      <ul>
        <li><strong>Viewport:</strong> ${r.viewport} (DPR ${r.dpr})</li>
        <li><strong>User agent:</strong> ${escapeHtml(r.ua)}</li>
        <li><strong>Online:</strong> ${r.online}</li>
        <li><strong>Language:</strong> ${r.lang}</li>
        <li><strong>Cookies enabled:</strong> ${r.cookieEnabled}</li>
        <li><strong>localStorage:</strong> ${r.localStorage}</li>
        <li><strong>sessionStorage:</strong> ${r.sessionStorage}</li>
        <li><strong>CPU threads:</strong> ${r.hwConcurrency ?? "n/a"}</li>
        <li><strong>RAM (approx):</strong> ${r.memoryGB ?? "n/a"}</li>
        <li><strong>WebGL:</strong> ${r.webgl}</li>
        <li><strong>Service Worker:</strong> ${r.serviceWorker}</li>
        <li><strong>Prefers reduced motion:</strong> ${r.prefersReducedMotion ?? "n/a"}</li>
      </ul>
    `;
    }

    buildReport(): Report {
        const canvas = document.createElement("canvas");
        let webgl = false;
        try {
            webgl = !!(canvas.getContext("webgl") || canvas.getContext("experimental-webgl"));
        } catch { webgl = false; }

        const prefersReducedMotion = matchMediaSafe("(prefers-reduced-motion: reduce)");

        return {
            viewport: `${window.innerWidth}×${window.innerHeight}`,
            dpr: Number((window.devicePixelRatio || 1).toFixed(2)),
            ua: navigator.userAgent,
            online: navigator.onLine,
            lang: navigator.language || (navigator as any).userLanguage || "n/a",
            cookieEnabled: navigator.cookieEnabled,
            localStorage: storageAvailable("localStorage"),
            sessionStorage: storageAvailable("sessionStorage"),
            hwConcurrency: (navigator as any).hardwareConcurrency ?? null,
            memoryGB: (navigator as any).deviceMemory ?? null,
            webgl,
            serviceWorker: "serviceWorker" in navigator,
            prefersReducedMotion,
        };
    }
}

function storageAvailable(type: "localStorage" | "sessionStorage") {
    try {
        const s = window[type];
        const x = "__t__";
        s.setItem(x, x);
        s.removeItem(x);
        return true;
    } catch { return false; }
}

function matchMediaSafe(query: string): boolean | null {
    try { return !!window.matchMedia?.(query).matches; } catch { return null; }
}

function escapeHtml(s: string) {
    return s.replace(/[&<>"']/g, (c) => ({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;" }[c]!));
}

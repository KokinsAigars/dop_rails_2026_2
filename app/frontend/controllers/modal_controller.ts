import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
    static targets = ["backdrop", "window", "initialFocus"] as string[];

    declare readonly backdropTarget: HTMLElement;
    declare readonly windowTarget: HTMLElement;
    declare readonly initialFocusTarget: HTMLElement;
    declare readonly hasInitialFocusTarget: boolean;

    connect() {
        // Close on ESC
        this._onKeyDown = this._onKeyDown.bind(this);
    }

    open() {
        this.element.hidden = false;
        document.addEventListener("keydown", this._onKeyDown);
        // Basic focus management
        queueMicrotask(() => {
            const el = this.hasInitialFocusTarget ? this.initialFocusTarget : this.windowTarget;
            el?.focus?.();
        });
        // ARIA
        this.element.setAttribute("role", "dialog");
        this.element.setAttribute("aria-modal", "true");
    }

    close() {
        document.removeEventListener("keydown", this._onKeyDown);
        this.element.hidden = true;
    }

    toggle() {
        this.element.hidden ? this.open() : this.close();
    }

    backdrop(e: Event) {
        if (e.target === this.backdropTarget) this.close();
    }

    private _onKeyDown(e: KeyboardEvent) {
        if (e.key === "Escape") this.close();
    }
}



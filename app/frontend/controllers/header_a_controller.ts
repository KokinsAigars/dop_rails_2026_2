
//  id : 019a8765-5973-76be-b2e1-5fbc1ed8e696
//
//  *   data-controller="header-a"
//

import {Controller} from "@hotwired/stimulus"

export default class extends Controller<HTMLDivElement> {

    // ---- Targets ----[data-signin-target=]
    static targets = [
        "progress"
    ]
    declare readonly progressTarget: HTMLElement

    // ---- Values ----
    static values  = {
        id: String,
    }
    declare readonly idValue: string
    declare readonly hasIdValue: boolean

    // Internal state
    private progress = 0 // 0..1
    private trickleTimer: number | null = null
    private pendingCount = 0
    private visibleSince: number | null = null
    private readonly minVisibleMs = 250 // keep bar visible briefly to avoid flicker

    // ---- Stimulus Controller Lifecycle ----
    initialize()  { }
    connect() {
        document.addEventListener("app:loading:start", this.onAppLoadingStart)
        document.addEventListener("app:loading:set", this.onAppLoadingSet as EventListener)
        document.addEventListener("app:loading:finish", this.onAppLoadingFinish)

        // Optional: integrate with Turbo (comment out if not using Turbo)
        document.addEventListener("turbo:before-fetch-request", this.onAppLoadingStart)
        document.addEventListener("turbo:before-fetch-response", this.onAppLoadingFinish)
    }
    stateValueChanged() {}
    disconnect() {
        document.removeEventListener("app:loading:start", this.onAppLoadingStart)
        document.removeEventListener("app:loading:set", this.onAppLoadingSet as EventListener)
        document.removeEventListener("app:loading:finish", this.onAppLoadingFinish)

        document.removeEventListener("turbo:before-fetch-request", this.onAppLoadingStart)
        document.removeEventListener("turbo:before-fetch-response", this.onAppLoadingFinish)

        this.stopTrickle()
    }

    // ---- Public API ----
    start() { this.begin() }
    set(p: number) { this.setProgress(this.clamp(p, 0, 1)) }
    finish() { this.complete() }

    // --- Event handlers ---
    private onAppLoadingStart = () => this.begin()
    private onAppLoadingFinish = () => this.complete()
    private onAppLoadingSet = (e: CustomEvent) => {
        const p = typeof e.detail?.progress === "number" ? e.detail.progress : undefined
        if (typeof p === "number") this.setProgress(this.clamp(p, 0, 1))
    }

    // --- Core progress logic ---
    private begin() {
        this.pendingCount = Math.max(0, this.pendingCount) + 1
        if (this.pendingCount === 1) {
            // first start → show bar and begin trickle
            this.visibleSince = performance.now()
            if (this.progress === 0) {
                this.showBar()
                this.setProgress(0.08) // jump-start
            }
            this.startTrickle()
        }
    }

    private complete() {
        this.pendingCount = Math.max(0, this.pendingCount - 1)
        if (this.pendingCount > 0) return // still have ongoing operations

        // final finish → stop trickle and complete quickly
        this.stopTrickle()
        const now = performance.now()
        const elapsed = this.visibleSince ? now - this.visibleSince : this.minVisibleMs
        const remaining = Math.max(0, this.minVisibleMs - elapsed)

        const finalize = () => {
            this.setProgress(1)
            // wait for the transform transition (~200ms) then hide
            window.setTimeout(() => {
                this.hideBar()
                this.progress = 0
                this.setTransform(0)
                this.visibleSince = null
            }, 220)
        }

        if (remaining > 0) {
            window.setTimeout(finalize, remaining)
        } else {
            finalize()
        }
    }

    private setProgress(p: number) {
        this.progress = p
        this.setTransform(p)
        if (p > 0 && !this.progressTarget.classList.contains("site-header-a__progress--visible")) {
            this.showBar()
        }
    }

    private setTransform(p: number) {
        this.progressTarget.style.transform = `scaleX(${p})`
    }

    private showBar() {
        this.progressTarget.classList.add("site-header-a__progress--visible")
    }

    private hideBar() {
        this.progressTarget.classList.remove("site-header-a__progress--visible")
    }

    private startTrickle() {
        if (this.trickleTimer != null) return
        this.trickleTimer = window.setInterval(() => {
            // Increase by smaller amounts as we approach 100%
            const inc = this.progress < 0.25 ? 0.03
                : this.progress < 0.65 ? 0.02
                    : this.progress < 0.9  ? 0.01
                        : 0.005
            const next = Math.min(this.progress + inc, 0.994) // never actually hit 1 during trickle
            this.setProgress(next)
        }, 350)
    }

    private stopTrickle() {
        if (this.trickleTimer != null) {
            window.clearInterval(this.trickleTimer)
            this.trickleTimer = null
        }
    }

    private clamp(n: number, min: number, max: number) {
        return Math.max(min, Math.min(max, n))
    }

}

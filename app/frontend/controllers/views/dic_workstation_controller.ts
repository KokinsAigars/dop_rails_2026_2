
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["upperPane", "dragHandle"]

    declare readonly upperPaneTarget: HTMLElement
    private isCurrentlyResizing: boolean = false
    private initialMouseY: number = 0
    private initialPaneHeight: number = 0
    private activeHandle: HTMLElement | null = null; // Store the handle here

    connect() {
        const savedHeight = localStorage.getItem("dic_workstation_upper_h")

        // Fallback to 300 if savedHeight is missing or too small
        const initialHeight = (savedHeight && parseInt(savedHeight) > 50) ? savedHeight : "300"

        if (this.hasUpperPaneTarget) {
            this.upperPaneTarget.style.height = `${initialHeight}px`
        }
    }

    // Unique names to avoid collision with other resizers
    beginDictionaryResize(event: PointerEvent) {
        this.isCurrentlyResizing = true;

        // 1. Capture the handle and SAVE it to the class
        this.activeHandle = event.currentTarget as HTMLElement;
        this.activeHandle.setPointerCapture(event.pointerId);

        this.initialMouseY = event.clientY;
        this.initialPaneHeight = this.upperPaneTarget.offsetHeight;

        this.activeResizeMoveHandler = (e: PointerEvent) => this.executeDictionaryResize(e);
        this.activeResizeUpHandler = (e: PointerEvent) => this.finalizeDictionaryResize(e);

        document.addEventListener("pointermove", this.activeResizeMoveHandler);
        document.addEventListener("pointerup", this.activeResizeUpHandler);

        document.body.classList.add("dic-resizing-active");
        event.preventDefault();
    }

    executeDictionaryResize(event: PointerEvent) {
        if (!this.isCurrentlyResizing) return;

        requestAnimationFrame(() => {
            // Use clientY for vertical movement
            const currentY = event.clientY;
            const deltaY = currentY - this.initialMouseY;
            const newHeight = this.initialPaneHeight + deltaY;

            // EMERGENCY LOGGING: Open console to see these numbers
            // console.log({initial: this.initialPaneHeight, delta: deltaY, final: newHeight});

            // Strict boundaries so it can't "vanish"
            if (newHeight > 50 && newHeight < 900) {
                this.upperPaneTarget.style.height = `${newHeight}px`;
            }
        });
    }

    finalizeDictionaryResize(event: PointerEvent) {
        if (!this.isCurrentlyResizing) return;
        this.isCurrentlyResizing = false;

        document.removeEventListener("pointermove", this.activeResizeMoveHandler);
        document.removeEventListener("pointerup", this.activeResizeUpHandler);

        // 2. Release using the SAVED handle reference
        if (this.activeHandle) {
            // Use the event.pointerId to tell the browser WHICH touch/mouse to release
            this.activeHandle.releasePointerCapture(event.pointerId);
            this.activeHandle = null; // Clear it for next time
        }

        document.body.classList.remove("dic-resizing-active");

        // Save height...
        localStorage.setItem("dic_workstation_upper_h", this.upperPaneTarget.offsetHeight.toString());
    }

}
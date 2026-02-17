
//  id: 3098b300-d561-42b5-96a3-0d864d4ff0f4
//
//  *   data-controller="user-workspace"
//
//  account_root_path (/account)
//  admin_root_path (/admin)
//

import {Controller} from "@hotwired/stimulus"
import { visit } from "@hotwired/turbo"
import { t } from "@frontend/lib/i18n_js.ts"
import { ensureElementId } from "@frontend/utils/dom_helpers.ts";

type Stage = 0 | 1 | 2;
const DEBUG = false;
const DEBUG_fn_call = true;
const DEBUG_DOM = false;
const DEBUG_GUIDS = false;

export default class extends Controller<HTMLDivElement> {

    // ---- data-target(s) ----
    static targets = [
        "guides",
        "activityBar",
        "explorer",
        "explorerBody",
        "explorerTitle",
        "separator",
        "workspaceMain",
        "edit_area",
        "container",
        "workspaceMain",
        "tabBar",
        "activityButton",
        "tabTemplate"
    ]
    declare readonly guidesTarget: HTMLDivElement
    declare readonly activityBarTarget: HTMLElement

    declare readonly explorerTarget: HTMLElement
    declare readonly hasExplorerTarget: boolean

    declare readonly explorerBodyTarget: HTMLElement
    declare readonly hasExplorerBodyTarget: boolean

    declare readonly explorerTitleTarget: HTMLElement
    declare readonly hasExplorerTitle: boolean

    declare readonly separatorTarget: HTMLDivElement
    declare readonly hasSeparatorTarget: boolean

    declare readonly workspaceMainTarget: HTMLElement
    declare readonly hasWorkspaceMainTarget: boolean

    declare readonly editAreaTarget: HTMLDivElement

    declare readonly tabBarTarget: HTMLElement

    declare readonly activityButtonTarget: HTMLElement

    declare readonly tabTemplateTarget: HTMLElement

    // ---- Values ----
    static values = {
        id: String,
        layout: String, // "left" or "right"
        width: Number,
        state: Number,
        isResizing: { type: Boolean, default: false },
        isOpen: { type: Boolean, default: true }
    }
    declare readonly idValue: string
    declare readonly hasIdValue: boolean
    declare readonly layout: string
    declare readonly width: number
    declare readonly state: number
    private resizeFrame: number | null = null;
    static classes = ["side"]
    private rafId: number | null = null;
    private startX: number = 0;
    private startWidth: number = 0;

    connect() {
        const savedWidth = localStorage.getItem("explorer-width")
        if (this.hasExplorerTarget) {
            this.explorerTarget.style.width = `${this.widthValue}px`
        }
        window.onpopstate = () => {
            // Optional: Refresh the page or trigger a click to the new URL
            window.location.reload();
        };
    }

    // --- ACTIONS ---

    fn_toggleLayout() {
        // Just flip the value. Stimulus handles the rest!
        this.layoutValue = (this.layoutValue === "right") ? "left" : "right"
    }

    // --- OBSERVERS (The "Automatic" part) ---

    layoutValueChanged(value: string, previousValue: string | undefined) {
        // 1. Update the DOM attribute so CSS can see it
        this.element.setAttribute("data-user-workspace-layout-value", value)

        // 2. Only save to DB if this isn't the first time the page loaded
        if (previousValue !== undefined) {
            this.persistSetting("layout", value)
        }

        console.log(`[GHOST-UI] Layout flipped to: ${value}`)
    }

    // --- PERSISTENCE ---

    private async persistSetting(key: string, value: any) {
        // This hits your Account::SettingsController
        await fetch("/account/management/settings/update_ui", {
            method: "PATCH",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": (document.querySelector('meta[name="csrf-token"]') as any).content
            },
            body: JSON.stringify({ key: key, value: value })
        })
    }

    fn_toggleSide() {
        const newLayout = this.layoutValue === "left" ? "right" : "left"
        this.layoutValue = newLayout // This triggers layoutValueChanged automatically
    }

    async fn_loadSection(event: PointerEvent) {
        event.preventDefault();
        const button = event.currentTarget as HTMLElement;
        const url = button.dataset.url;

        // Toggle logic: if already active, close it
        if (button.classList.contains("is-active")) {
            this.closeExplorer();
            button.classList.remove("is-active");
            return;
        }

        try {
            const response = await fetch(url, {
                headers: { "Accept": "application/json" } // THE VITAL LINE
            });

            if (!response.ok) {
                // const errorText = await response.text(); // Get the HTML error page from Rails
                // console.error("Rails Error:", errorText);
                throw new Error(`Response not OK: ${response.status}`);
            }

            const data = await response.json();

            // 1. Update UI Classes
            this.activityButtonTargets.forEach(btn => btn.classList.remove("is-active"));
            button.classList.add("is-active");

            // 2. Inject Content
            this.explorerTitleTarget.textContent = data.explorer_title;
            this.explorerBodyTarget.innerHTML = data.explorer_html;
            this.workspaceMainTarget.innerHTML = data.edit_html;

            // 3. Show Sidebar
            this.explorerTarget.classList.remove("is-hidden");

            // 4. Update URL and Tabs
            window.history.pushState({}, "", url);
            this.updateHistoryTabs(data.explorer_title, url);

        } catch (error) {
            console.error("Pulse failed:", error);
        }
    }


    async fn_loadUsersInWorkspace(event: PointerEvent) {
        event.preventDefault();
        const button = event.currentTarget as HTMLElement;
        const url = (event.currentTarget as HTMLElement).dataset.url;

        // Check if we are clicking the button that is already active
        if (button.classList.contains("is-active")) {
            this.closeExplorer();
            button.classList.remove("is-active");
            return; // Stop here
        }

        // 1. Reset all buttons
        this.activityButtonTargets.forEach(btn => btn.classList.remove("is-active"));

        // 2. Set this button to active
        button.classList.add("is-active");

        // Update URL
        window.history.pushState({}, "", url);

        try {

            // Fetch the JSON
            const response = await fetch(url, { headers: { "Accept": "application/json" } });
            const data = await response.json();

            // Logic specific to Users (like opening the explorer)
            this.renderUserManagement(data);

            // Update the Tab Bar
            this.updateHistoryTabs(data.explorer_title, url);

        } catch (e) { console.error(e); }
    }



    // Private helper to keep things tidy
    private renderUserManagement(data: any) {
        this.explorerTarget.classList.remove("is-hidden");

        // UPDATE THE TITLE (Targeting the span/h3)
        if (this.hasExplorerTitleTarget && data.explorer_title) {
            this.explorerTitleTarget.textContent = data.explorer_title;
        }

        // UPDATE THE BODY (Targeting the specific inner div)
        if (this.hasExplorerBodyTarget && data.explorer_html) {
            // This now leaves the Header/Title untouched!
            this.explorerBodyTarget.innerHTML = data.explorer_html;
        }


        if (data.edit_html) this.workspaceMainTarget.innerHTML = data.edit_html;


    }



    fn_closeTab(event: PointerEvent) {
        event.stopPropagation(); // Prevent the tab-click event from firing
        const closeBtn = event.currentTarget as HTMLElement;
        const tab = closeBtn.closest(".workspace-tab") as HTMLElement;
        const wasActive = tab.classList.contains("is-active");

        // 1. Remove the tab from DOM
        tab.remove();

        // 2. If we closed the active tab, we need to switch to another one
        if (wasActive) {
            const remainingTabs = this.tabBarTarget.querySelectorAll(".workspace-tab") as NodeListOf<HTMLElement>;

            if (remainingTabs.length > 0) {
                // Switch to the last tab in the list
                const nextTab = remainingTabs[remainingTabs.length - 1];
                this.fn_loadSectionFromTab({ currentTarget: nextTab } as unknown as PointerEvent);
            } else {
                // 3. No tabs left? Back to Dashboard
                this.resetToDashboard();
            }
        }
    }

    private resetToDashboard() {
        // 1. UI Reset
        this.explorerTarget.classList.add("is-hidden");
        this.activityButtonTargets.forEach(btn => btn.classList.remove("is-active"));

        // 2. Content Reset (Fetch the welcome screen or just inject it)
        // It's often cleaner to have a simple 'dashboard' partial ready
        this.workspaceMainTarget.innerHTML = `
        <div class="welcome-screen">
            <h1>Welcome to the Command Center</h1>
            <p>Select a module from the sidebar to begin.</p>
        </div>`;

        // 3. URL Reset: Points to your new root
        window.history.pushState({}, "", "/en/admin");
    }



    async fn_selectItem(event: PointerEvent) {
        event.preventDefault();
        const item = event.currentTarget as HTMLElement;
        const url = item.dataset.url;
        const title = item.querySelector(".main-text")?.textContent || "Detail";

        if (!url) return;

        try {
            const response = await fetch(url, { headers: { "Accept": "text/html" } });
            const html = await response.text();

            // 1. Pour the HTML into the workspace
            this.workspaceMainTarget.innerHTML = html;

            // 2. Update/Add a Tab for this specific item (The "Cherry")
            this.updateHistoryTabs(title, url);

            // 3. Highlight in Sidebar
            this.explorerBodyTarget.querySelectorAll(".explorer-item").forEach(el => el.classList.remove("is-active"));
            item.classList.add("is-active");

        } catch (e) {
            console.error("Failed to load item:", e);
        }
    }


    async fn_loadAction(event: PointerEvent) {
        event.preventDefault();
        const url = (event.currentTarget as HTMLElement).getAttribute("href");

        const response = await fetch(url, { headers: { "Accept": "text/html" } });
        const html = await response.text();

        this.workspaceMainTarget.innerHTML = html;
        this.updateHistoryTabs("New Item", url);
    }


    async fn_selectUser(event: PointerEvent) {
        const item = event.currentTarget as HTMLElement;
        const url = item.dataset.url;

        try {
            const response = await fetch(url, {
                headers: {
                    "Accept": "text/html",
                    "X-Requested-With": "XMLHttpRequest" // Tells Rails this is an AJAX call
                }
            });

            if (!response.ok) throw new Error(`Error: ${response.status}`);

            const html = await response.text();
            this.workspaceMainTarget.innerHTML = html;

            // Visual Selection
            this.explorerTarget.querySelectorAll(".explorer-item").forEach(el => el.classList.remove("is-active"));
            item.classList.add("is-active");

        } catch (e) {
            console.error("Failed to load user form:", e);
        }
    }



    private toggleExplorer() {
        if (!this.hasExplorerTarget) return;

        const explorer = this.explorerTarget;
        const isNowHidden = explorer.classList.toggle("is-hidden")

        // Toggle the classes explicitly
        explorer.classList.toggle("is-hidden", isNowHidden);

        if (this.hasSeparatorTarget) {
            this.separatorTarget.classList.toggle("is-hidden", isNowHidden);
        }

        // GHOST TRACE: Ensure the workspaceMain actually expands
        if (this.hasWorkspaceMainTarget) {
            // Force the browser to recalculate flex layout
            this.workspaceMainTarget.style.display = 'flex';
        }

        this.persistSetting("explorer_collapsed", isNowHidden);
    }

    private addHistoryTab(title: string, url: string) {
        // 1. Check if tab already exists to avoid duplicates
        const existingTab = this.tabBarTarget.querySelector(`[data-url="${url}"]`)
        if (existingTab) {
            this.activateTab(existingTab as HTMLElement)
            return
        }

        // 2. Create the new tab element
        const tab = document.createElement("button")
        tab.className = "tab-item"
        tab.dataset.url = url
        tab.dataset.action = "click->user-workspace#fn_loadSection" // Recursive!
        tab.innerHTML = `
        <span class="tab-title T-tab-bar">${title}</span>
        <span class="tab-close" data-action="click->user-workspace#fn_closeTab:stop">×</span>
    `

        this.tabBarTarget.appendChild(tab)
        this.activateTab(tab)
    }
    private activateTab(activeTab: HTMLElement) {
        this.tabBarTarget.querySelectorAll(".tab-item").forEach(t => t.classList.remove("is-active"))
        activeTab.classList.add("is-active")
    }

    private syncUIParts(url: string) {
        // Find any button or tab that matches this URL and make it active
        this.element.querySelectorAll(`[data-url="${url}"]`).forEach(el => {
            el.classList.add("is-active")
        })
    }




    private setActiveButton(activeButton: HTMLElement) {
        // Remove the active class from all buttons
        this.element.querySelectorAll(".AB-icon-btn").forEach(btn => {
            btn.classList.remove("is-active");
        });
        // Add to the current one
        activeButton.classList.add("is-active");
    }

    async loadSection(event: PointerEvent) {
        event.preventDefault();
        const button = event.currentTarget as HTMLElement
        const url = button.dataset.url
        const title = button.getAttribute("title") || "New Tab"

        // 1. Fetch the raw HTML from Rails
        const response = await fetch(url, {
            headers: { "Accept": "text/html" }
        })
        const html = await response.text()

        // 2. Manual DOM Injection (No magic!)
        // We assume the response contains the HTML for the explorer
        this.explorerTarget.innerHTML = html

        // 3. Optional: Trigger a second fetch or update the Edit area
        this.showExplorer()
    }







    // Helper to add/activate a tab
    updateHistoryTabs(title: string, url: string) {
        // 1. Check if tab already exists
        let existingTab = this.tabBarTarget.querySelector(`[data-url="${url}"]`);
        if (existingTab) return this.activateTab(existingTab);

        if (!existingTab) {
            // Clone the template instead of writing HTML strings
            const template = this.tabTemplateTarget.content.cloneNode(true) as HTMLElement;
            const tab = template.querySelector(".workspace-tab") as HTMLElement;

            tab.dataset.url = url;
            tab.querySelector(".tab-title").textContent = title;

            this.tabBarTarget.appendChild(tab);
            this.activateTab(tab);
        }
    }

// Action when clicking a tab
    fn_loadSectionFromTab(event: PointerEvent) {
        const tab = event.currentTarget as HTMLElement;
        const url = tab.dataset.url;

        // Find the original activity button and "click" it programmatically
        const originalBtn = this.activityButtonTargets.find(btn => btn.dataset.url === url);
        if (originalBtn) {
            // We reuse the existing logic!
            originalBtn.dispatchEvent(new PointerEvent("pointerdown"));
        }
    }













    private showExplorer() {
        if (this.hasExplorerTarget) {
            this.explorerTarget.classList.remove("is-hidden");
        }
    }
    private closeExplorer() {
        if (this.hasExplorerTarget) {
            this.explorerTarget.classList.add("is-hidden");
        }
    }



    // 1. Update the method signature to PointerEvent
    fn_onMouseDown(event: PointerEvent) {
        this.isResizingValue = true

        // THE NEW MAGIC: Lock the mouse to the separator
        const separator = event.currentTarget as HTMLElement
        separator.setPointerCapture(event.pointerId)

        this.startX = event.clientX;
        this.startWidth = this.explorerTarget.offsetWidth;

        document.body.classList.add("resizing-active")
        this.separatorTarget.classList.add("is-active")
        this.explorerTarget.classList.add("is-resizing")

        event.preventDefault()
    }

    // 2. Update to PointerEvent
    fn_onMouseMove(event: PointerEvent) {
        if (!this.isResizingValue || !this.hasExplorerTarget) return

        // Note: We no longer need to worry about the mouse "escaping"
        // because the events are captured by the separator.
        requestAnimationFrame(() => {
            const mouseDelta = event.clientX - this.startX;
            let newWidth: number;

            if (this.layoutValue === "right") {
                newWidth = this.startWidth - mouseDelta;
            } else {
                newWidth = this.startWidth + mouseDelta;
            }

            if (newWidth > 150 && newWidth < 800) {
                this.explorerTarget.style.width = `${newWidth}px`
            }
        })
    }

    // 3. Update to PointerEvent
    fn_onMouseUp(event: PointerEvent) {
        if (!this.isResizingValue) return
        this.isResizingValue = false

        // Release the capture
        const separator = event.currentTarget as HTMLElement
        separator.releasePointerCapture(event.pointerId)

        document.body.classList.remove("resizing-active")
        this.separatorTarget.classList.remove("is-active")
        this.explorerTarget.classList.remove("is-resizing")

        // Save to DB
        const finalWidth = this.explorerTarget.offsetWidth
        this.persistSetting("explorer_width", finalWidth)
    }

    // 4. Double-Click on the separator line
    fn_resetWidth() {
        const defaultWidth = 333;
        this.explorerTarget.style.width = `${defaultWidth}px`;

        // Don't forget to save it to the DB!
        this.persistSetting("explorer_width", defaultWidth);
    }




    async fn_instantSearch(event: InputEvent) {
        const input = event.target as HTMLInputElement;
        const query = input.value;
        const baseUrl = input.dataset.url;

        if (query.length < 2 && query.length !== 0) return;

        const url = `${baseUrl}?q=${encodeURIComponent(query)}`;

        const response = await fetch(url, { headers: { "Accept": "application/json" } });
        const data = await response.json();

        // We ONLY update the main area, keeping the search box (explorer) active
        this.workspaceMainTarget.innerHTML = data.edit_html;
    }



}
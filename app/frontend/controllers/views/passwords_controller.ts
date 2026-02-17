
//  id: b51986d3-d01f-4924-8b0d-76e5a4c1587c
//
//  *   data-controller="passwords"
//
//  /passwords/new
//  /passwords/edit

// DOCUMENTATION
// THE GHOST / BOT
// userName is an input field => a honeypot for bots
// if userName != '' === not a user, as the field is not visible in UI

import {Controller} from "@hotwired/stimulus"
import { visit } from "@hotwired/turbo"
import { t } from "@frontend/lib/i18n_js.ts"
import { flashBackground } from "@frontend/utils/ui_effects.ts";
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
        "title",
        "inputBeautyRegA",
        "inputForm",
        "email",
        "password",
        "eyeBtn",
        "eyeBtn_open",
        "eyeBtn_close",
        "tooltip_show_pwd",
        "tooltip_hide_pwd",
        "btnLabel",
        "userName",
        "confirmation"
    ]
    declare readonly guidesTarget: HTMLDivElement
    declare readonly titleTarget: HTMLDivElement
    declare readonly inputBeautyRegATarget: HTMLFormElement
    declare readonly emailTarget: HTMLInputElement
    declare readonly hasEmailTarget: boolean
    declare readonly inputFormTarget: HTMLFormElement
    declare readonly hasInputFormTarget: boolean
    declare readonly passwordTarget: HTMLInputElement
    declare readonly hasPasswordTarget: boolean
    declare readonly eyeBtnTarget: HTMLButtonElement
    declare readonly eyeBtn_openTarget: SVGGElement
    declare readonly eyeBtn_closeTarget: SVGGElement
    declare readonly tooltip_show_pwdTarget: HTMLDivElement
    declare readonly tooltip_hide_pwdTarget: HTMLDivElement
    declare readonly btnLabelTarget: HTMLSpanElement
    declare readonly confirmationTarget: HTMLInputElement

    // honeypot
    declare readonly userNameTarget: HTMLInputElement
    declare readonly hasUserNameTarget: boolean

    // ---- Values ----
    static values  = {
        id: String,
        state: Number,
        email: String,
        password: String
    }
    declare readonly idValue: string
    declare readonly hasIdValue: boolean
    declare stateValue: number
    declare emailValue: string
    declare passwordValue: string

    declare buttonUpdatingTitle: string
    declare buttonSuccessTitle: string
    declare buttonProcessingTitle: string
    declare buttonContinueTitle: string
    declare buttonSubmitTitle: string

    private startTime: number;
    private hasMouseMoved: boolean = false;
    private totalKeystrokes: number = 0;


    // ---- LIFECYCLE ----
    initialize() {
        if (DEBUG_fn_call) console.log("Lifecycle: initialize - \"passwords\"");
        if (DEBUG_fn_call) this.#ensureInitialize();

        this.idValue = ensureElementId(this.element, "data-registration-id-value");
        this.#ensureDefaults();
    }
    connect() {
        if (DEBUG_fn_call) console.log("Lifecycle: connect - \"passwords\"");
        if (DEBUG_GUIDS) {this.#createDevGuids();} else {this.guidesTarget.style.display = 'none';}

        this.onLocaleChanged = this.onLocaleChanged.bind(this);
        window.addEventListener("i18n:locale-changed", this.onLocaleChanged);

        // If the URL has an 'edit' segment or a token, jump straight to the password step
        const isEditPage = window.location.pathname.includes("/edit");
        if (isEditPage && this.hasPasswordTarget) {
            this.stateValue = 1;
        }

        this.render(); // Draw the initial state
    }
    stateValueChanged(value: number, previousValue: number) {
        if (DEBUG_fn_call) { console.log(`stateValueChanged(). Old State: ${previousValue}, New State: ${value}`); }

        this.render();
    }
    disconnect() {
        if (DEBUG_fn_call) console.log("Lifecycle: disconnect - \"passwords\"");

        window.removeEventListener("i18n:locale-changed", this.onLocaleChanged);

        this.#ensureDefaults();

        if (DEBUG) console.log("🔴 disconnect - \"passwords\"")
    }


    // ---- PUBLIC, data-action="..." ----
    fn_handleEnter(e: KeyboardEvent) {
        if (DEBUG_fn_call) console.log("function call: this.fn_handleEnter()");

        // Prevent reloading the page when the user hits enter
        e.preventDefault();

        if (this.canAdvance) {
            this.fn_next(e);
        }
    }
    async fn_next(e: Event) {
        if (DEBUG_fn_call) console.log("function call: this.fn_next()");

        e.preventDefault();

        // GHOST PROTOCOL FIRST
        // Check this immediately, before looking at stateValue or doing anything else.
        const isBot = await this.#checkIsBot();
        if  (isBot) return;

        if (this.stateValue === 0) {
            // STEP 0: Requesting the link
            const success = await this.#checkUser();
            if (success) {
                // This explicitly moves the user to your new "Success" page
                // This swaps the current URL for the new one.
                // If they hit 'Back', they go to whatever was BEFORE the email form.
                Turbo.visit("/passwords/sent", { action: "replace" });
            }
        } else if (this.stateValue === 1) {
            // STEP 1: Updating the password
            // calling getter function
            if (this.#hasValidPassword()) {
                this.confirmationTarget.value = this.passwordTarget.value;
                this.btnLabelTarget.innerHTML = this.buttonUpdatingTitle;
                this.element.style.pointerEvents = "none";

                // Trigger the Rails form we built in the HTML
                // This handles CSRF, PATCH method, and params nesting automatically
                if (this.hasInputFormTarget) {
                    this.btnLabelTarget.innerHTML = this.buttonSuccessTitle;
                    this.inputFormTarget.requestSubmit();
                } else {
                    console.error("Stimulus cannot find the inputForm target!");
                }
            }
        }
    }
    fn_toggleShowPassword(e: Event): void {
        if (DEBUG_fn_call) console.log("function call: this.fn_toggleShowPassword()");

        e.preventDefault();
        const isPassword = this.passwordTarget.type === "password";

        // Toggle input type
        this.passwordTarget.type = isPassword ? "text" : "password";

        // Toggle SVG Icons
        this.eyeBtn_openTarget.classList.toggle("hidden", isPassword);
        this.eyeBtn_closeTarget.classList.toggle("hidden", !isPassword);

        // Update Tooltips if the user is hovering
        this.#updateTooltipVisibility(!isPassword);
    }
    fn_onEyeEnter(): void {
        if (DEBUG_fn_call) console.log("function call: this.fn_onEyeEnter()");

        const isPassword = this.passwordTarget.type === "password";
        this.#updateTooltipVisibility(isPassword);
    }
    fn_onEyeLeave(): void {
        if (DEBUG_fn_call) console.log("function call: this.fn_onEyeLeave()");

        this.tooltip_show_pwdTarget.classList.add("hidden");
        this.tooltip_hide_pwdTarget.classList.add("hidden");
    }


    // ---- PRIVATE ----
    #ensureInitialize() {
        if (DEBUG_fn_call) console.log("function call: this.#ensureInitialize()");

        if(DEBUG_DOM) console.log("🔹 Stimulus Controller \"passwords\" initialized. id: ", this.idValue);
        if(DEBUG_DOM) console.log("data-controller=\"passwords\" has idValue ? : ", this.hasIdValue);
        if(DEBUG_DOM) console.log("Stimulus Controller \"passwords\" element in DOM: ", this.element);
    }
    #ensureDefaults() {
        if (DEBUG_fn_call) console.log("function call: this.#ensureDefaults()");

        if (![0, 1, 2].includes(this.stateValue as Stage)) { this.stateValue = 0; }

        this.emailTarget.value = "";
        this.passwordTarget.value = "";

        this.emailValue = "";
        this.passwordValue = "";

        this.buttonUpdatingTitle = t("registrations.button_updating");
        this.buttonSuccessTitle = t("registrations.button_success");
        this.buttonProcessingTitle = t("registrations.button_processing");
        this.buttonContinueTitle = t("registrations.button_continue");
        this.buttonSubmitTitle = t("registrations.button_submit");

        this.render();
    }
    private onLocaleChanged = () => {
        if (DEBUG_fn_call) console.log("function call: this.onLocaleChanged()");

        // External Callback (Arrow style !) to register for this controller's locale changes

        if (DEBUG_fn_call) console.log("Locale changed, re-rendering...");
        // Refresh translations or placeholders when the language flips
        this.render();
    }
    private render() {
        if (DEBUG_fn_call) console.log("function call: this.render()");

        this.#toggleInputBeauty();

        if (this.hasEmailTarget && this.stateValue === 0) {
            this.#renderStage0Email();
        }

        if (this.hasPasswordTarget && this.stateValue === 1) {
            this.#renderStage1Password();
        }
    }
    #toggleInputBeauty() {
        if (DEBUG_fn_call) console.log("function call: this.#toggleInputBeauty()");

        switch (this.stateValue) {
            case 0: {
                const isEmpty = this.emailTarget.value.trim() === ""
                this.inputBeautyRegATarget.classList.toggle("hidden", isEmpty)
                break;
            }

            case 1: {
                const isEmpty = this.passwordTarget.value.trim() === ""
                this.inputBeautyRegATarget.classList.toggle("hidden", isEmpty)
                break;
            }
            default:
                break;
        }

    }
    #renderStage0Email(){
        if (DEBUG_fn_call) console.log("function call: this.#renderStage0Email()");

        this.titleTarget.innerHTML = t("passwords.title_default");
        this.btnLabelTarget.innerHTML = this.buttonContinueTitle;
    }
    #renderStage1Password(){
        if (DEBUG_fn_call) console.log("function call: this.#renderStage1Password()");

        this.titleTarget.innerHTML = t("passwords.title_default_edit");
        this.btnLabelTarget.innerHTML = this.buttonSubmitTitle;
    }
    async #checkIsBot(): Promise<boolean> {
        if (DEBUG_fn_call) console.log("function call: this.#checkIsBot()");

        // Honeypot check: If a bot filled this hidden field, stop immediately.
        if (this.hasUserNameTarget && this.userNameTarget.value !== "") {
            if (DEBUG_fn_call) console.warn("Trap Sprung!");
            // If it's a bot, we pretend it worked and send them to the success page
            await this.handleBotInteraction();
            return true;
        }
        return false;
    }
    async #checkUser(): Promise<boolean> {
        if (DEBUG_fn_call) console.log("function call: this.#checkUser()");

        const email = this.emailTarget.value.trim();
        if (!this.isValidEmail) {
            await flashBackground(this.emailTarget.parentNode, 300, "#ff8080");
            return false;
        }

        // 1. Show loading state on the button
        const originalLabel = this.btnLabelTarget.innerHTML;
        this.btnLabelTarget.innerHTML = this.buttonProcessingTitle;

        // 2. Hit the Rails endpoint
        const result = await this.#postJson("/passwords", { email_address: email });

        if (result.ok) {
            // 3. Transition to Success UI
            this.titleTarget.innerHTML = t("passwords.check_inbox_title");
            return true;
        } else {
            // Handle actual server errors (500s, etc)
            this.btnLabelTarget.innerHTML = "Error";
            return false;
        }
    }
    async #postJson(url: string, params: Record<string, any>) {
        if (DEBUG_fn_call) console.log("function call: this.#postJson");

        try {
            const response = await fetch(url, {
                method: "POST",
                headers: {
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                    "X-CSRF-Token": this.#csrfToken(),
                },
                body: JSON.stringify(params)
            });

            const contentType = response.headers.get("content-type");

            // Check if we actually got JSON back
            if (contentType && contentType.includes("application/json")) {
                const data = await response.json();
                return { ok: response.ok, data: data };
            } else {
                // It's probably an HTML error page from Rails
                const text = await response.text();
                if (DEBUG) console.error("Expected JSON but got HTML. Check your Rails logs!");
                return { ok: false, data: { message: "Server returned HTML" } };
            }
        } catch (error) {
            if (DEBUG) console.error("Fetch failed:", error);
            return { ok: false, data: { message: "Network Error" } };
        }
    }
    #csrfToken(): string {
        if (DEBUG_fn_call) console.log("function call: this.#csrfToken()");

        const el = document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement | null
        return el?.content || ""
    }
    #createDevGuids() {
        if (DEBUG_fn_call) console.log("function call: this.#createDevGuids()");

        const classList = [
            "reg-gh0", "reg-gh1", "reg-gh1-1", "reg-gh2",
            "reg-gh3", "reg-gh3-1", "reg-gh4", "reg-gh5",
            "reg-gh6", "reg-gh7", "reg-v1", "reg-v2", "reg-v3"
        ];

        // Ensure container is visible for debug
        this.guidesTarget.classList.remove("hidden");

        classList.forEach((className) => {
            const guide = document.createElement("div");
            guide.classList.add(className);
            this.guidesTarget.appendChild(guide);
        });

        if (DEBUG) console.log("🛠️ Development Guides Injected");
    }
    #updateTooltipVisibility(isPassword: boolean): void {
        if (DEBUG_fn_call) console.log("function call: this.#updateTooltipVisibility");

        this.tooltip_show_pwdTarget.classList.toggle("hidden", !isPassword);
        this.tooltip_hide_pwdTarget.classList.toggle("hidden", isPassword);
    }
    async #hasValidPassword(): boolean {
        if (DEBUG_fn_call) console.log("getter call: this.#hasValidPassword()");

        // Standardizing on 8 characters for security
        if (this.passwordTarget.value.length < 8) {
            await flashBackground(this.passwordTarget.parentNode, 300, "#ff8080");
            return false;
        }
        return true;
    }

    // ---- PRIVATE GETTERS ----
    get canAdvance(): boolean {
        if (DEBUG_fn_call) console.log("getter call: this.canAdvance");

        switch (this.stateValue) {
            case 0: // EMAIL
                // Basic check for @ and at least one character before/after
                return this.emailTarget.value.includes("@") &&
                    this.emailTarget.value.length > 3;

            case 1: // PASSWORD
                // Your new logic: ensures password isn't just spaces
                return this.passwordTarget.value.trim().length > 0;

            default:
                return true;
        }
    }
    get isValidEmail(): boolean {
        if (DEBUG_fn_call) console.log("getter call: this.isValidEmail");

        const email = this.emailTarget.value.trim();
        const regex = /.+@.+\..+/;
        return regex.test(email);
    }


    // ---- CACHING BOTS ----
    async handleBotInteraction() {
        if (DEBUG_fn_call) { console.warn("Ghost Protocol Active: Logging Password Bot."); }

        try {
            await fetch("/passwords", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-CSRF-Token": this.getCsrfToken()
                },
                body: JSON.stringify({
                    user_Name: this.userNameTarget.value, // The Trap
                    bot_intercepted: true
                })
            });
        } catch (e) {
            console.error("Failed to log bot, but proceeding with trap anyway.");
        }

        this.titleTarget.innerHTML = "Processing...";
        this.element.querySelectorAll(".signin__floating-label-wrap, .signin__input-wrap, .signin__actions").forEach(el => {
            (el as HTMLElement).style.display = "none";
        });

        setTimeout(() => {
            Turbo.visit("/passwords/sent", { action: "replace" });
        }, 1500);
    }
    private getCsrfToken() {
        return (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement)?.content;
    }

}



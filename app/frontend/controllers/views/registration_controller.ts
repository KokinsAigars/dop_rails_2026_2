
//  id : 7ab36581-5447-4947-9aee-87a44ec104ed
//
//  *   data-controller="registration"
//
//  /signup
//

import {Controller} from "@hotwired/stimulus"
import { visit } from "@hotwired/turbo"
import { t } from "@frontend/lib/i18n_js.ts"
import { flashBackground } from "@frontend/utils/ui_effects.ts";

type Stage = 0 | 1 | 2;
const DEBUG = false;
const DEBUG_fn_call = false;
const DEBUG_DOM = false;
const DEBUG_GUIDS = false;

// userName is an input field -- a honeypot for bots
// if userName != '' === not a user, as the field is not visible in UI

export default class extends Controller<HTMLDivElement> {

    // ---- data-target(s) ----
    static targets = [
        "title",
        "inputBeautyRegA",
        "inputBeautyRegB",
        "firstName",
        "lastName",
        "email",
        "password",
        "btnLabel",
        "guides",
        "userName",
        "eyeBtn",
        "eyeBtn_open",
        "eyeBtn_close",
        "tooltip_show_pwd",
        "tooltip_hide_pwd"
    ]
    declare readonly titleTarget: HTMLDivElement
    declare readonly inputBeautyRegATarget: HTMLFormElement
    declare readonly inputBeautyRegBTarget: HTMLFormElement
    declare readonly firstNameTarget: HTMLInputElement
    declare readonly lastNameTarget: HTMLInputElement
    declare readonly emailTarget: HTMLInputElement
    declare readonly passwordTarget: HTMLInputElement
    declare readonly btnLabelTarget: HTMLSpanElement
    declare readonly guidesTarget: HTMLDivElement
    declare readonly eyeBtnTarget: HTMLButtonElement
    declare readonly eyeBtn_openTarget: SVGGElement
    declare readonly eyeBtn_closeTarget: SVGGElement
    declare readonly tooltip_show_pwdTarget: HTMLDivElement
    declare readonly tooltip_hide_pwdTarget: HTMLDivElement

    // honeypot
    declare readonly userNameTarget: HTMLInputElement

    // ---- Values ----
    static values  = {
        id: String,
        state: Number,
        firstName: String,
        lastName: String,
        email: String,
        password: String
    }
    declare readonly idValue: string
    declare readonly hasIdValue: boolean
    declare stateValue: number
    declare firstNameValue: string
    declare lastNameValue: string
    declare emailValue: string
    declare passwordValue: string

    declare buttonBackTitle: string
    declare buttonNextTitle: string
    declare buttonContinueTitle: string
    declare buttonSubmitTitle: string

    private startTime: number;
    private hasMouseMoved: boolean = false;
    private totalKeystrokes: number = 0;

    // ---- Stimulus Controller Lifecycle ----
    initialize() {
        if (DEBUG_fn_call) console.log("Lifecycle: initialize - \"registration\"");
        if (DEBUG_fn_call) this.ensureInitialize();

        this.ensureElementHasIdValue();
        this.ensureDefaults();
    }
    connect() {
        if (DEBUG_fn_call) console.log("Lifecycle: connect - \"registration\"");
        if (DEBUG_GUIDS) {this.createDevGuids();} else {this.guidesTarget.style.display = 'none';}

        this.onLocaleChanged = this.onLocaleChanged.bind(this);
        window.addEventListener("i18n:locale-changed", this.onLocaleChanged);

        this.startTime = Date.now();

        // Store the reference to the function
        this.mouseMoveHandler = () => {
            this.hasMouseMoved = true;
            console.log("Mouse moved - tracking active.");
            // We remove it immediately after first move to save memory
            this.cleanupMouseTracker();
        };

        window.addEventListener("mousemove", () => { this.hasMouseMoved = true }, { once: true });

        this.render(); // Draw the initial state
    }
    stateValueChanged(value: number, previousValue: number) {
        if (DEBUG_fn_call) { console.log(`stateValueChanged(). Old State: ${previousValue}, New State: ${value}`); }
        if (DEBUG_fn_call) console.log(`Keystrokes: ${this.totalKeystrokes}`);
        if (DEBUG_fn_call) console.log(`hasMouseMoved: ${this.hasMouseMoved}`);

        this.render();
    }
    disconnect() {
        if (DEBUG_fn_call) console.log("Lifecycle: disconnect - \"registration\"");

        window.removeEventListener("i18n:locale-changed", this.onLocaleChanged);

        this.cleanupMouseTracker();

        this.ensureDefaults();

        console.log("🔴 disconnect - \"registration\"")
    }


    // ---- Internal helpers (private) ----
    //initialize
    private ensureInitialize() {
        if(DEBUG_DOM) console.log("🔹 Stimulus Controller \"registration\" initialized. id: ", this.idValue);
        if(DEBUG_DOM) console.log("data-controller=\"registration\" has idValue ? : ", this.hasIdValue);
        if(DEBUG_DOM) console.log("Stimulus Controller \"registration\" element in DOM: ", this.element);
    }
    private onLocaleChanged = () => {
        // External Callback (Arrow style !) to register for this controller's locale changes

        if (DEBUG_fn_call) console.log("Locale changed, re-rendering...");
        // Refresh translations or placeholders when the language flips
        this.render();
    }
    private ensureElementHasIdValue() {
        // Generate id if missing for controller identity [data-registration-id-value]
        if (!this.hasIdValue) {
            const gen = (crypto as any).randomUUID?.() || `tmp-${Date.now()}`
            this.element.setAttribute("data-registration-id-value", gen)
            ;(this as any).idValue = gen
        }
    }
    private ensureDefaults() {
        if (DEBUG_fn_call) console.log("function call: ensureDefaults()");

        if (![0, 1, 2].includes(this.stateValue as Stage)) { this.stateValue = 0; }

        this.firstNameTarget.value = "";
        this.lastNameTarget.value = "";
        this.emailTarget.value = "";
        this.passwordTarget.value = "";

        this.firstNameValue = "";
        this.lastNameValue = "";
        this.emailValue = "";
        this.passwordValue = "";

        this.buttonBackTitle = t("registrations.button_back");
        this.buttonNextTitle = t("registrations.button_next");
        this.buttonContinueTitle = t("registrations.button_continue");
        this.buttonSubmitTitle = t("registrations.button_submit");

        this.render();
    }
    private render() {
        if (DEBUG_fn_call) console.log("function call: render()");

        this.toggleInputBeauty();

        switch (this.stateValue) {
            case 0: this.renderStage0Names(); break;
            case 1: this.renderStage1Email(); break;
            case 2: this.renderStage2Password(); break;
            default:
                this.stateValue = 0;
                this.renderStage0Names();
        }
    }
    private renderStage0Names() {
        this.titleTarget.innerHTML = t("registrations.title_default");
        this.btnLabelTarget.innerHTML = this.buttonNextTitle;
    }
    private renderStage1Email(){
        this.titleTarget.innerHTML = t("registrations.enter_email_address");
        this.btnLabelTarget.innerHTML = this.buttonContinueTitle;
    }
    private renderStage2Password(){
        this.titleTarget.innerHTML = t("registrations.create_password");
        this.btnLabelTarget.innerHTML = this.buttonSubmitTitle;
    }


    private async getEmail(): Promise<boolean> {
        const email = this.emailTarget.value.trim();
        if (!email.includes("@")) return false;

        // 1. Call the new postJson
        const result = await this.postJson("/registrations/check_email", { email });

        // 2. Logic Gate
        if (result.ok && result.data.available) {
            // EMAIL IS FREE!
            this.emailValue = email;
            this.titleTarget.innerHTML = email;
            return true;
        } else {
            // EMAIL IS TAKEN (or server crashed)
            const errorMsg = result.data.message || "Email already in use";
            this.titleTarget.innerHTML = errorMsg;
            return false;
        }
    }

    private async submitRegistration() {
        if (DEBUG_fn_call) console.log("submitRegistration() called.");

        // 1. Check Honeypots first -- is bot?
        if (this.userNameTarget.value !== "") {
            return this.handleBotInteraction();
        }
        // 2. Check Behavioral Trust -- is bot?
        if (!this.isTrustworthy) {
            return this.handleBotInteraction();
        }

        const payload = {
            user: {
                first_name: this.firstNameTarget.value,
                last_name: this.lastNameTarget.value,
                email_address: this.emailTarget.value,
                password: this.passwordTarget.value,
                password_confirmation: this.passwordTarget.value,
                user_Name: this.userNameTarget.value // Honeypot
            }
        }

        const response = await fetch("/registrations", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Accept": "application/json",
                "X-CSRF-Token": this.csrfToken()
            },
            body: JSON.stringify(payload)
        })

        const data = await response.json()

        // 1. Respond to bots?
        if (data.bot) {
            console.warn("Ghost Protocol Active: Feeding bot fake success.");
            // Do NOT log them in. Show a fake "Verification sent" message.
            this.titleTarget.innerHTML = "Check your email to verify your account!";
            return; // Exit here.
        }

        // 2. Respond to humans?
        if (response.ok) {

            // We do NOT log them in yet.
            // Use Turbo to visit the "Check your email" info page
            Turbo.visit(data.location);

        } else {
            // If Rails says "Email already taken", we flash red
            this.fn_passBackgroundColor(500, "#ff8080");

            // Optional: Show the specific error from Rails
            if (data.errors) {
                this.titleTarget.innerHTML = data.errors[0];
            }
        }
    }

    private async postJson(url: string, params: Record<string, any>) {
        try {
            const response = await fetch(url, {
                method: "POST",
                headers: {
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                    "X-CSRF-Token": this.csrfToken(),
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
                console.error("Expected JSON but got HTML. Check your Rails logs!");
                return { ok: false, data: { message: "Server returned HTML" } };
            }
        } catch (error) {
            console.error("Fetch failed:", error);
            return { ok: false, data: { message: "Network Error" } };
        }
    }

    private csrfToken(): string {
        const el = document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement | null
        return el?.content || ""
    }

    get canAdvance(): boolean {
        switch (this.stateValue) {
            case 0: // NAMES
                return this.firstNameTarget.value.trim().length > 0 &&
                    this.lastNameTarget.value.trim().length > 0;

            case 1: // EMAIL
                // Basic check for @ and at least one character before/after
                return this.emailTarget.value.includes("@") &&
                    this.emailTarget.value.length > 3;

            case 2: // PASSWORD
                // Your new logic: ensures password isn't just spaces
                return this.passwordTarget.value.trim().length > 0;

            default:
                return true;
        }
    }

    private isValidEmail(email: string): boolean {
        // Simple regex so we don't fight the user too much
        const regex = /.+@.+\..+/;
        return regex.test(email);
    }

    async handleInvalidEmail() {
        // Shaking noise is annoying, but a subtle red pulse is clear
        await flashBackground(this.emailTarget, 400, "#ff8080");
    }

    private validateStage(): boolean {
        switch (this.stateValue) {
            case 0: // Names
                return this.firstNameTarget.value.trim().length > 0 &&
                    this.lastNameTarget.value.trim().length > 0;

            case 1: // Email
                const email = this.emailTarget.value.trim();
                const isValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
                if (!isValid) {
                    // Use your rescued function for the red flash!
                    this.fn_passBackgroundColor(400, "#ff8080");
                }
                return isValid;

            case 2: // Password
                return this.passwordTarget.value.length >= 8; // Simple check for now

            default:
                return false;
        }
    }

    private hideInputBeauty() {
        this.inputBeautyRegATarget.classList.toggle("hidden", true);
        this.inputBeautyRegBTarget.classList.toggle("hidden", true)
    }

    private createDevGuids() {
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

        console.log("🛠️ Development Guides Injected");
    }

    // ---- functions from html data-action="" ----
    async fn_next(e: Event) {
        e.preventDefault();

        const currentStage = this.stateValue;

        // Stage 0: Names
        if (currentStage === 0) {
            if (this.firstNameTarget.value.trim() === "") {
                await flashBackground(this.firstNameTarget.parentElement, 300, "#ff8080");
                return;
            }
            if (this.lastNameTarget.value.trim() === "") {
                await flashBackground(this.lastNameTarget.parentElement, 300, "#ff8080");
                return;
            }
        }

        // Stage 1: Email
        else if (currentStage === 1) {
            const isEmailValid = await this.getEmail();
            if (!isEmailValid) {
                // Flash the input red or show error
                await flashBackground(this.emailTarget.parentElement,500, "#ff8080");
                this.emailTarget.focus();
                return; // EXIT HERE - do not increment stateValue
            }
        }

        // Stage 2: Password
        else if (currentStage === 2) {
            if (this.passwordTarget.value.length < 3) {
                await flashBackground(this.passwordTarget.parentElement, 400, "#ff8080");
                return;
            }

        }

        // ONLY increment if we haven't 'returned' early from a validation failure
        if (this.stateValue < 2) {
            this.stateValue++;
            this.hideInputBeauty();
        } else {
            // Final Submit Logic
            this.submitRegistration();
        }
    }

    fn_back(e: Event) {
        e.preventDefault();
        if (this.stateValue > 0) {
            this.stateValue--;
        }
    }

    fn_handleEnter(e: KeyboardEvent) {
        // Prevent reloading the page when the user hits enter
        e.preventDefault();

        if (this.canAdvance) { this.fn_next(e); }
    }

    private async fn_passBackgroundColor (duration: number = 300, color: string = "rgb(219, 248, 213)") {
        return new Promise((resolve) => {
            this.inputFormTarget.style = `background-color: ${color};`;
            setTimeout(() => {
                this.inputFormTarget.style = `background-color: ${'transparent'};`;
                resolve('done');
            }, duration);
        });
    }

    trackActivity() {
        this.totalKeystrokes++;
        if (DEBUG_fn_call) console.log(`Keystrokes: ${this.totalKeystrokes}`);
    }

    private get isTrustworthy(): boolean {
        // 1. The Honeypot Check
        if (this.userNameTarget.value !== "") return false;

        // 2. The Velocity Check
        const timeElapsed = (Date.now() - this.startTime) / 1000;

        // A human using Autocomplete might be fast,
        // but they still have to move the mouse or click 'Continue'
        const isBotLike = (this.totalKeystrokes < 3 && timeElapsed < 2.0);

        if (isBotLike && !this.hasMouseMoved) return false;

        return true;
    }


    private cleanupMouseTracker() {
        if (this.mouseMoveHandler) {
            window.removeEventListener("mousemove", this.mouseMoveHandler);
            this.mouseMoveHandler = null;
        }
    }

    fn_toggleShowPassword(e: Event): void {
        e.preventDefault();
        const isPassword = this.passwordTarget.type === "password";

        // Toggle input type
        this.passwordTarget.type = isPassword ? "text" : "password";

        // Toggle SVG Icons
        this.eyeBtn_openTarget.classList.toggle("hidden", isPassword);
        this.eyeBtn_closeTarget.classList.toggle("hidden", !isPassword);

        // Update Tooltips if user is hovering
        this.fn_updateTooltipVisibility(!isPassword);
    }

    fn_onEyeEnter(): void {
        const isPassword = this.passwordTarget.type === "password";
        this.fn_updateTooltipVisibility(isPassword);
    }

    fn_onEyeLeave(): void {
        this.tooltip_show_pwdTarget.classList.add("hidden");
        this.tooltip_hide_pwdTarget.classList.add("hidden");
    }

    private fn_updateTooltipVisibility(isPassword: boolean): void {
        this.tooltip_show_pwdTarget.classList.toggle("hidden", !isPassword);
        this.tooltip_hide_pwdTarget.classList.toggle("hidden", isPassword);
    }


    private toggleInputBeauty() {
        switch (this.stateValue) {
            case 0: {
                const isFirstLineEmpty = this.firstNameTarget.value.trim() === ""
                this.inputBeautyRegATarget.classList.toggle("hidden", isFirstLineEmpty)

                const isSecondLineEmpty = this.lastNameTarget.value.trim() === ""
                this.inputBeautyRegBTarget.classList.toggle("hidden", isSecondLineEmpty)

                break;
            }

            case 1: {
                const isEmpty = this.emailTarget.value.trim() === ""
                this.inputBeautyRegATarget.classList.toggle("hidden", isEmpty)
                break;
            }

            case 2: {
                const isEmpty = this.passwordTarget.value.trim() === ""
                this.inputBeautyRegATarget.classList.toggle("hidden", isEmpty)
                break;
            }
            default:
                break;
        }

    }



    // Ghost Protocol: Logging and Trapping BOTS.
    async handleBotInteraction() {
        if (DEBUG_fn_call) { console.warn("Ghost Protocol Active: Logging and Trapping."); }

        // 1. Send the data to Rails silently
        // We send a POST to registrations, but we include the honeyPot field
        try {
            await fetch("/registrations", {
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

        // 2. UI "Theater" (Make the bot think it's working)
        this.titleTarget.innerHTML = "Processing...";
        this.element.querySelectorAll(".signin__floating-label-wrap, .signin__input-wrap, .signin__actions").forEach(el => {
            (el as HTMLElement).style.display = "none";
        });

        // 3. Final Redirect
        // We wait a moment to make it feel "real"
        setTimeout(() => {
            Turbo.visit("/registrations/sent", { action: "replace" });
        }, 1500);
    }
    private getCsrfToken() {
        return (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement)?.content;
    }


}



//  id : 019a4330-3ce0-77a4-88a5-1228665919d2
//
//  *  data-controller="sessions"
//
//  /login
//

// DOCUMENTATION
// THE GHOST / BOT
// userName is an input field => a honeypot for bots
// if userName != '' === not a user, as the field is not visible in UI

import {Controller} from "@hotwired/stimulus"
import { visit } from "@hotwired/turbo"
import {t} from "@frontend/lib/i18n_js.ts"
import { flashBackground } from "@frontend/utils/ui_effects.ts";
import { ensureElementId } from "@frontend/utils/dom_helpers.ts";

type Stage = 0 | 1 | 2;
const DEBUG = false;
const DEBUG_fn_call = false;
const DEBUG_DOM = false;
const DEBUG_GUIDS = false;

export default class extends Controller<HTMLDivElement> {

    // ---- data-target(s) ----
    static targets = [
        "guides",
        "titleEmail",
        "inputBeauty",
        "inputForm",
        "input",
        "primaryBtn",
        "eyeBtn",
        "forgotBtn",
        "eyeBtn_open",
        "eyeBtn_close",
        "tooltip_show_pwd",
        "tooltip_hide_pwd",
        "userName"
    ]
    // TS declarations for targets (Stimulus auto-wires these):
    declare readonly guidesTarget: HTMLDivElement
    declare readonly titleEmailTarget: HTMLDivElement
    declare readonly hasTitleEmailTarget: boolean
    declare readonly inputBeautyTarget: HTMLDivElement
    declare readonly hasInputBeautyTarget: boolean
    declare readonly inputFormTarget: HTMLInputElement
    declare readonly hasInputFormTarget: boolean
    declare readonly inputTarget: HTMLInputElement
    declare readonly hasInputTarget: boolean
    declare primaryBtnTarget: HTMLButtonElement
    declare readonly hasPrimaryBtnTarget: boolean
    declare eyeBtnTarget: HTMLButtonElement
    declare eyeBtn_openTarget: SVGGElement
    declare eyeBtn_closeTarget: SVGGElement
    declare tooltip_show_pwdTarget: HTMLSpanElement
    declare tooltip_hide_pwdTarget: HTMLSpanElement
    declare forgotBtnTarget: HTMLDivElement
    declare readonly hasForgotBtnTarget: boolean

    // honeypot
    declare readonly userNameTarget: HTMLInputElement
    declare readonly hasUserNameTarget: boolean

    // ---- Values ----
    static values  = {
        id: String,
        state: Number, // data-signin-[state]-value="0"  // 0|1|2 (email -> password -> reset)
        Title_msg: String,
        UserEnterEmail: String,
        UserPassword: String,
        ProceedBtn: String,
        signIn_password_show: String,
        signIn_password_hide: String,
        placeholder_incorrect: String,
        placeholder_OnForgot: String,
        sup_email: String,
        sup_password: String,
        Reset_password_title: String,
        Alert_Email_sent: String,
        typingPassword: Boolean,
        showPassword: Boolean,
        onEyeHover: Boolean,
        resetPassword: Boolean,
        forgotCount: Number,
        email: String,
        inputField: String,
        isAuthenticated: Boolean,
        loading: Boolean,
    }
    // TS declarations for values (Stimulus makes getters/setters: <name>Value):
    declare readonly idValue: string
    declare readonly hasIdValue: boolean
    declare stateValue: Stage
    declare Title_msgValue: string
    declare UserEnterEmailValue: string
    declare UserPasswordValue: string
    declare ProceedBtnValue: string
    declare signIn_password_showValue: string
    declare signIn_password_hideValue: string
    declare placeholder_incorrectValue: string
    declare placeholder_OnForgotValue: string
    declare sup_emailValue: string
    declare sup_passwordValue: string
    declare Reset_password_titleValue: string
    declare Alert_Email_sentValue: string
    declare typingPasswordValue: boolean
    declare showPasswordValue: boolean
    declare onEyeHoverValue: boolean
    declare resetPasswordValue: boolean
    declare forgotCountValue: number
    declare emailValue: string
    declare inputFieldValue: string
    declare isAuthenticated: boolean
    declare loading: boolean


    // ---- LIFECYCLE ----
    initialize() {
        if (DEBUG_fn_call) console.log("Lifecycle: initialize - \"sessions\"");
        if (DEBUG_fn_call) this.#ensureInitialize();

        this.idValue = ensureElementId(this.element, "data-sessions-id-value");
        this.#ensureDefaults();
    }
    connect() {
        if (DEBUG_fn_call) console.log("Lifecycle: connect - \"sessions\"");
        if (DEBUG_GUIDS) {this.#createDevGuids();} else {this.guidesTarget.style.display = 'none';}

        this.onLocaleChanged = this.onLocaleChanged.bind(this);
        window.addEventListener("i18n:locale-changed", this.onLocaleChanged);

        this.render(); // Draw the initial state
    }
    stateValueChanged(value: number, previousValue: number) {
        if (DEBUG_fn_call) { console.log(`stateValueChanged(). Old State: ${previousValue}, New State: ${value}`); }

        this.render();
    }
    disconnect() {
        if (DEBUG_fn_call) console.log("Lifecycle: disconnect - \"sessions\"");

        window.removeEventListener("i18n:locale-changed", this.onLocaleChanged);

        this.#ensureDefaults();

        if (DEBUG) console.log("🔴 disconnect - \"sessions\"")
    }


    // ---- PUBLIC, data-action="..." ----
    async fn_onProceedBtnClick(e: Event) {
        if (DEBUG_fn_call) console.log("function call: async fn_onProceedBtnClick(Event)");

        //preventDefault - prevent reloading the page
        e.preventDefault();

        // GHOST PROTOCOL FIRST
        // Check this immediately, before looking at stateValue or doing anything else.
        const isBot = await this.#checkIsBot();
        if  (isBot) return;

        try {

            // 1. check if input is empty, if, return
            if (this.inputTarget.value === '') {
                return;
            }

            // 2. check email in a variable (add username check?) and proceed
            // -- if e-mail is ok => change state and return
            if (this.stateValue === 0 ) {
                const success = await this.getEmail();
                if (success) {
                    this.stateValue = 1 as Stage;
                }
                return; // Stop here; render() will take over the UI
            }

            //  3. check password
            //  If authentication successful navigate to app root
            if (this.stateValue === 1) {
                await this.getPassword("/sessions/verify_password");
                return;
            }

            //  4. if forgot password button clicked stateValue is 2, so all Proceed btn clicks comes through this,
            //  -- check if input is email, if, check if email is valid
            //  -- check if input is password and call function for password reset
            //  -- if successful, alter user db, reset view to sign in
            if (this.stateValue === 2) {
                if (this.inputTarget.type === "text"){
                    await this.getEmail();
                    return
                }
                if (this.inputTarget.type === "password") {
                    //$ rails routes | grep reset_passwords
                    // await this.getPassword("/reset_passwords");
                    await this.postJson("/reset_passwords", { login: this.emailValue })
                    this.stateValue = 0 as Stage;
                    return;
                }
            }

        } catch (error) {
            console.error(error, "An error occurred during submit.");
            console.error("Stimulus controller id:", this.idValue, ', fn_onProceedBtnClick()');
        }
    }
    fn_onInput() {
        if (DEBUG_fn_call) console.log("function call: fn_onInput()");

        this.toggleInputBeauty()
    }
    fn_onEyeEnter(e: MouseEvent) {
        if (DEBUG && DEBUG_fn_call) console.log("function call: fn_onEyeEnter()");

        this.onEyeHoverValue = true

        this.fn_toggleOnEyeBtnHint();

    }
    fn_onEyeLeave(e: MouseEvent) {
        if (DEBUG_fn_call) console.log("function call: fn_onEyeLeave()");

        this.onEyeHoverValue = false

        this.tooltip_show_pwdTarget.classList.toggle("hidden", true)
        this.tooltip_hide_pwdTarget.classList.toggle("hidden", true)
    }
    fn_toggleShowPassword(e: Event) {
        if (DEBUG && DEBUG_fn_call) console.log("function call: toggleShowPassword(e: Event)");
        e.preventDefault();

        // 1. Flip the type
        const isShowing = this.inputTarget.type === "text";
        this.inputTarget.type = isShowing ? "password" : "text";

        // 2. Update Icons based on the NEW state
        const nowShowing = this.inputTarget.type === "text";

        // If showing text, show the 'close' eye (to hide it)
        // If showing password, show the 'open' eye (to reveal it)
        this.eyeBtn_openTarget.classList.toggle("hidden", nowShowing);
        this.eyeBtn_closeTarget.classList.toggle("hidden", !nowShowing);

        this.fn_toggleOnEyeBtnHint();
    }
    fn_onForgotBtnClick = (e: Event) => {
        e.preventDefault();
        this.inputTarget.value = "";
        this.stateValue = 2 as Stage; // Triggers render()
    }


    // ---- PRIVATE ----
    #ensureInitialize() {
        if (DEBUG_fn_call) console.log("function call: this.#ensureInitialize()");

        if(DEBUG_DOM) console.log("🔹 Stimulus Controller \"sessions\" initialized. id: ", this.idValue);
        if(DEBUG_DOM) console.log("data-controller=\"sessions\" has idValue ? : ", this.hasIdValue);
        if(DEBUG_DOM) console.log("Stimulus Controller \"sessions\" element in DOM: ", this.element);
    }
    #ensureDefaults() {
        if (DEBUG_fn_call) console.log("function call: this.#ensureDefaults()");

        if (![0, 1, 2].includes(this.stateValue as Stage)) { this.stateValue = 0; }

        this.inputTarget.value = "";
        this.inputTarget.placeholder = t("sessions.placeholder_EmailUser");
        this.inputTarget.type = "email";
        this.inputTarget.autocomplete="email"
        this.inputTarget.inputMode="email"
        this.eyeBtnTarget.classList.toggle("hidden", false);

        this.UserEnterEmailValue = t("sessions.placeholder_EmailUser");
        this.UserPasswordValue = t("sessions.placeholder_Password");
        this.placeholder_incorrectValue = t("sessions.placeholder_incorrect");

        this.Title_msgValue = t("sessions.title_msg_default");
        this.ProceedBtnValue = t("sessions.proceed_btn");
        this.signIn_password_showValue = t("sessions.password_show");
        this.signIn_password_hideValue = t("sessions.password_hide");

        this.placeholder_OnForgotValue = t("sessions.placeholder_OnForgot");
        this.sup_emailValue = t("sessions.superscript_email");
        this.sup_passwordValue = t("sessions.superscript_password");
        this.Reset_password_titleValue = t("sessions.forgot_Reset_password");
        this.Alert_Email_sentValue = t("sessions.Alert_Email_sent");

        this.typingPasswordValue = false;
        this.showPasswordValue = false;
        this.onEyeHoverValue = false;
        this.resetPasswordValue = false;
        this.forgotCountValue = 0;
        this.emailValue = "";
        this.inputFieldValue = "";

        this.isAuthenticated = false;
        this.loading = false;


        // this.inputTarget.type = "password";
        // this.eyeBtn_openTarget.classList.remove("hidden");
        // this.eyeBtn_closeTarget.classList.add("hidden");

    }
    private onLocaleChanged = () => {
        if (DEBUG_fn_call) console.log("function call: this.onLocaleChanged()");

        // External Callback (Arrow style !) to register for this controller's locale changes

        if (DEBUG_fn_call) console.log("Locale changed, re-rendering...");
        // Refresh translations or placeholders when the language flips
        this.render();
    }
    private render() {
        if (DEBUG) console.log(`Rendering state: ${this.stateValue}`);

        // This line powers your .only-s0, .only-s1, .only-s2 selectors in SCSS
        this.element.setAttribute("data-sessions-state-value", this.stateValue.toString());

        this.toggleEyeBtnTarget();
        this.toggleForgotBtnTarget();
        this.toggleInputBeauty();

        requestAnimationFrame(() => {
            if (this.hasInputTarget) this.inputTarget.focus()
        })

        switch (this.stateValue) {
            case 0: // Email Stage
                this.inputTarget.type = "text";
                this.inputTarget.placeholder = this.UserEnterEmailValue;
                this.inputTarget.autocomplete = "email";

                // this.eyeBtnTarget.classList.add("hidden");
                // this.titleEmailTarget.classList.add("hidden");
                this.inputTarget.value = '';
                this.toggleForgotBtnTarget();
                break;

            case 1: // Password Stage
                this.inputTarget.value = '';
                this.inputTarget.type = "password";
                this.inputTarget.inputMode='password'
                this.inputTarget.placeholder = this.UserPasswordValue;
                this.inputTarget.autocomplete = "current-password";

                // Show email above the input
                this.titleEmailTarget.classList.remove("hidden");
                this.eyeBtnTarget.classList.remove("hidden");

                // Call the helper here too
                this.toggleForgotBtnTarget();
                break;

            case 2: // Forgot Password Stage
                this.inputTarget.type = "text";
                this.inputTarget.placeholder = this.placeholder_OnForgotValue;
                this.inputTarget.autocomplete = "off";
                this.toggleForgotBtnTarget();
                break;
        }

        // Common logic for all states
        this.toggleInputBeauty();
    }



    fn_onCreateAccount = (e: Event) => {
        if (DEBUG_fn_call) console.log("function call: fn_onCreateAccount(Event)");

        const el = e.currentTarget as HTMLElement
        const url = el.getAttribute("data-dom-url-param")
        if (url) visit(url)
    }
    async #checkIsBot(): Promise<boolean> {
        if (DEBUG_fn_call) console.log("function call: this.#checkIsBot()");

        // Honeypot check: If a bot filled this hidden field, stop immediately.
        if (this.hasUserNameTarget && this.userNameTarget.value !== "") {
            if (DEBUG_fn_call) console.warn("Trap Sprung!");

            await this.handleBotInteraction();
            return true;
        }
        return false;
    }
    private async getEmail() {
        try {
            const email = this.inputTarget.value.trim();
            if (!email) return false;

            const result = await this.postJson("/sessions/verify_email", { email });

            if (result && result.ok) {
                // 1. MUST set this first so the render() method has access to it
                this.emailValue = email;
                this.titleEmailTarget.innerHTML = email;
                return true;
                // 2. Now change the state, which triggers stateValueChanged -> render()
                // this.stateValue = 1 as Stage;
            } else {
                await this.fn_onErrorFallBack();
                return false;
            }
        } catch (e) {
            console.error("Error verifying email:", e);
            console.error("Stimulus controller id:", this.idValue);
            return false;
        }
    }
    private async getPassword(link: string) {
        try {

            const email = this.emailValue;
            const password = this.inputTarget.value.trim();
            this.inputTarget.value = "";

            if (!email || !password) return

            const result = await fetch(link, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    // This line is the "secret sauce" for Rails
                    'X-CSRF-Token': this.csrfToken()
                },
                body: JSON.stringify({ email, password })
            });

            const data = await result.json();

            // console.log ("result: ", result);
            // console.log("data: ", data);
            // console.log("data.redirect_to: ", data.redirect_to);

            if (result.ok && data.redirect_to) {
                this.inputTarget.value = "";
                this.inputTarget.placeholder = ""
                // Smooth transition to /admin or /account
                Turbo.visit(data.redirect_to);
                return;
            } else {
                this.forgotCountValue++;
                await this.fn_onErrorFallBack();
                return
            }

        } catch (e) {
            console.error("Error verifying password:", e);
            console.error("Stimulus controller id:", this.idValue);
            return
        }
    }
    private async postJson(url: string, params: Record<string, string>) {

        try {
            const res = await fetch(url, {
                method: "POST",
                headers: {
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                    "X-CSRF-Token": this.csrfToken(),
                },
                body: JSON.stringify(params),
                credentials: "same-origin",
            })

            let data: any;
            data = await res.json().catch(() => ({}));
            return data

        } catch (e) {
            console.log(e, "postJson failed. id: ", this.idValue);
        }

    }
    private csrfToken(): string {
        const el = document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement | null
        return el?.content || ""
    }
    private async fn_onErrorFallBack() {
        this.loading = false;

        // Flash red
        await flashBackground(this.inputTarget.parentElement, 400, "#ff8080");
        // await this.fn_passBackgroundColor(300, "#ff8080");

        this.inputTarget.placeholder = this.placeholder_incorrectValue;

        // 2. Wipe the data
        this.emailValue = "";
        this.inputTarget.value = "";

        // SECURITY CHOICE:
        // Always kick back to State 0. It's slightly annoying for humans
        // but makes brute-forcing twice as hard for bots.
        this.stateValue = 0 as Stage;
        this._init_state_0();

        this.toggleInputBeauty();
        this.loading = false;
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
    private toggleInputBeauty() {
        const isEmpty = this.inputTarget.value.trim() === ""
        this.inputBeautyTarget.classList.toggle("hidden", isEmpty)
    }
    private toggleEyeBtnTarget() {
        if (DEBUG && DEBUG_fn_call) console.log("function call: toggleEyeBtnTarget()");

        if (this.inputTarget.type === 'text' && this.stateValue === 0) {
            this.eyeBtnTarget.classList.toggle("hidden", true);
            // this.tooltip_pwdTarget.classList.toggle("hidden", true);

        }

        if (this.inputTarget.type === 'password' && this.stateValue === 1) {
            this.eyeBtnTarget.classList.toggle("hidden", false);
            // this.tooltip_pwdTarget.classList.toggle("hidden", false);
            // this.tooltip_hide_pwdTarget.classList.toggle("hidden", true)
        }

        this.fn_toggleOnEyeBtnHint();

    }
    fn_toggleOnEyeBtnHint() {
        if (!this.onEyeHoverValue) return; // Don't show if not hovering

        const isShowingText = this.inputTarget.type === "text";

        // If text is visible, we show the "Hide" tooltip
        // If password is dots, we show the "Show" tooltip
        this.tooltip_show_pwdTarget.classList.toggle("hidden", isShowingText);
        this.tooltip_hide_pwdTarget.classList.toggle("hidden", !isShowingText);
    }
    private toggleForgotBtnTarget() {
        // Only show the button if we are in the Password state (1) AND they have failed once
        const shouldShow = (this.stateValue === 1 && this.forgotCountValue > 0);

        // classList.toggle(className, force) -> if force is true, add; if false, remove.
        this.forgotBtnTarget.classList.toggle("hidden", !shouldShow);
    }
    #createDevGuids() {
        const classList = [
            "reg-gh0", "signi-gh1", "signi-gh2", "signi-gh3",
            "signi-gh4", "signi-gh5", "signi-gh6",
            "reg-v1", "reg-v2", "reg-v3"
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


    // ---- CACHING BOTS ----
    async handleBotInteraction() {
        if (DEBUG_fn_call) { console.warn("Ghost Protocol Active: Logging Password Bot."); }

        try {
            await fetch("/sessions", {
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

        this.element.querySelectorAll(".sessions__floating-label-wrap, .sessions__input-wrap, .sessions__actions").forEach(el => {
            (el as HTMLElement).style.display = "none";
        });

        setTimeout(() => {
            // This replaces the current page in the browser history
            Turbo.visit("/", { action: "replace" });
        }, 1500);
    }
    private getCsrfToken() {
        return (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement)?.content;
    }

}


//  id : 019a8764-fedb-7c5a-adb8-ec67b8d34490
//
//  *   data-controller="header-b"
//

import {Controller} from "@hotwired/stimulus"
import {t} from "@frontend/lib/i18n_js.ts"

const DEBUG = false;
const DEBUG_fn_call = false;

export default class extends Controller<HTMLDivElement> {
    //
    // // ---- Targets ----[data-header_b-target=]
    // static targets = [
    //     "menuHamburger",
    //     "logo",
    //     "title",
    //     "search",
    //     "input_container",
    //     "inputForm",
    //     "input",
    //     "search_close",
    //     "search_preferences",
    //     "searchResults",
    //     "svg_passive",
    //     "svg_active",
    //     "svg_Search_preferences_passive",
    //     "svg_Search_preferences_active",
    // ]
    // // -- declare
    // declare menuHamburgerTarget: HTMLDivElement
    // declare readonly hasMenuHamburgerTarget: boolean
    // declare logoTarget: HTMLDivElement
    // declare titleTarget: HTMLDivElement
    // declare searchTarget: HTMLDivElement
    // declare readonly input_containerTarget: HTMLDivElement
    // declare readonly hasInput_containerTarget: boolean
    // declare readonly inputFormTarget: HTMLFormElement
    // declare readonly hasInputFormTarget: boolean
    // declare readonly inputTarget: HTMLInputElement
    // declare readonly hasInputTarget: boolean
    // declare readonly search_closeTarget: HTMLDivElement
    // declare readonly hasSearch_closeTarget: boolean
    // declare readonly search_preferencesTarget: HTMLDivElement
    // declare readonly hasSearch_preferencesTarget: boolean
    // declare readonly searchResultsTarget: HTMLDivElement
    // declare readonly hasSearchResultsTarget: boolean
    // declare svg_passiveTarget: SVGGElement
    // declare svg_activeTarget: SVGGElement
    // declare svg_Search_preferences_passiveTarget: SVGGElement
    // declare svg_Search_preferences_activeTarget: SVGGElement
    //
    // // ---- Values ----
    // static values  = {
    //     id: String,
    //     on_mouseenter: Boolean,
    //     txt_search_placeholder: String
    // }
    // // -- declare
    // declare readonly idValue: string
    // declare readonly hasIdValue: boolean
    // declare on_mouseenterValue: boolean
    // declare txt_search_placeholderValue: string
    //
    // // ---- Stimulus Controller Lifecycle ----
    // initialize()  {
    //     if (DEBUG_fn_call) console.log("Stimulus Controller Lifecycle: initialize()");
    //     // this.ensureInitialize();
    //     // this.ensureElementHasIdValue();
    //     window.addEventListener("i18n:locale-changed", this.onLocaleChanged);
    //     window.addEventListener("click", this.onClickEvent);
    //     this.ensureDefaults();
    //     this.searchToggleOnInput();
    // }
    // connect() {
    //     // this.ensureConnect();
    //     this._init_state_0();
    //     this.focusInputSoon();
    //     this.render();
    // }
    // stateValueChanged() {
    //     this.render();
    // }
    // disconnect() {
    //     // this.ensureDisconnect()
    //     window.removeEventListener("i18n:locale-changed", this.onLocaleChanged);
    //     window.removeEventListener("click", this.onClickEvent);
    // }
    //
    // // ---- UPDATE THE VIEW ----
    // private render() {
    //     console.log("Rendering header_b Controller changes ...");
    // }
    //
    // // ---- Public actions (data-action) ----
    //
    // toggleSidebar() {
    //     console.log("Toggle Sidebar");
    // }
    //
    //
    //
    //
    //
    // fn_clickIcon() {
    //     console.log("Click Icon button");
    // }
    // fn_clickTitle() {
    //     console.log("Click Title button");
    // }
    //
    //
    //
    // // --- SEARCH ---
    // fn_onSearch_container_mouseenter(e: MouseEvent) {
    //     if (DEBUG_fn_call) console.log("function call: fn_onSearch_container_mouseenter()");
    //     this.on_mouseenterValue = true;
    //     // console.log("Mouse enter search input, ", this.on_mouseenterValue);
    // }
    // fn_onSearch_container_mouseleave(e: MouseEvent) {
    //     if (DEBUG_fn_call) console.log("function call: fn_onSearch_container_mouseleave()");
    //     this.on_mouseenterValue = false;
    // }
    // fn_onSearchSvg_mouseenter(){
    //     if (DEBUG_fn_call) console.log("function call: fn_onSearchSvg_mouseenter()");
    //     if (this.inputTarget.value.trim() !== ''){
    //         this.svg_passiveTarget.classList.toggle("hidden", true);
    //         this.svg_activeTarget.classList.toggle("hidden", false);
    //     }
    // }
    // fn_onSearchSvg_mouseleave() {
    //     if (DEBUG_fn_call) console.log("function call: fn_onSearchSvg_mouseleave()");
    //     if (!this.on_mouseenterValue) {
    //         this.svg_passiveTarget.classList.toggle("hidden", false);
    //         this.svg_activeTarget.classList.toggle("hidden", true);
    //     }
    // }
    // fn_onSearch_preferencesSvg_mouseenter(){
    //     if (DEBUG_fn_call) console.log("function call: fn_onSearch_preferencesSvg_mouseenter()");
    //     this.svg_Search_preferences_passiveTarget.classList.toggle("hidden", true);
    //     this.svg_Search_preferences_activeTarget.classList.toggle("hidden", false);
    // }
    // fn_onSearch_preferencesSvg_mouseleave(){
    //     if (DEBUG_fn_call) console.log("function call: fn_onSearch_preferencesSvg_mouseleave()");
    //     this.svg_Search_preferences_passiveTarget.classList.toggle("hidden", false);
    //     this.svg_Search_preferences_activeTarget.classList.toggle("hidden", true);
    // }
    // fn_onSearchSvg_click_event() {
    //     if (DEBUG_fn_call) console.log("function call: fn_onSearchSvg_click_event()");
    //     // this.svg_passiveTarget.classList.toggle("hidden", true);
    //     // this.svg_activeTarget.classList.toggle("hidden", false);
    //     // this.searchToggleOnInput();
    //     // this.focusInputSoon();
    //     this.input_containerTarget.classList.remove("hbfsic-passive")
    //     this.input_containerTarget.classList.add("hbfsic-active")
    //     this.svg_passiveTarget.classList.add("hidden")
    //     this.svg_activeTarget.classList.remove("hidden")
    //     this.inputTarget.focus()
    // }
    // fn_onSearch__input(){
    //     if (DEBUG_fn_call) console.log("function call: fn_onSearch__input()");
    //     console.log("this.inputTarget.value.trim(): ", this.inputTarget.value.trim());
    //     // if (this.inputTarget.value.trim() === '') this.fn_onSearchSvg_mouseleave()
    //     // else this.fn_onSearchSvg_mouseenter();
    //     // this.searchToggleOnInput();
    //
    //     const query = this.inputTarget.value.trim()
    //
    //     if (query === "") {
    //         this.searchResultsTarget.classList.add("hidden")
    //         this.searchResultsTarget.innerHTML = ""
    //         return
    //     }
    //
    //     // perform AJAX request
    //     fetch(`/search.json?header_search=${encodeURIComponent(query)}`)
    //         .then(response => response.text())
    //         .then(html => {
    //             this.searchResultsTarget.innerHTML = html
    //             this.searchResultsTarget.classList.remove("hidden")
    //         })
    //
    // }
    //
    // fn_onSearch__enter(event:any){
    //     if (DEBUG_fn_call) console.log("function call: fn_onSearch__enter()");
    //     event.preventDefault();
    //     this.fn_onSearch__input();
    // }
    // fn_onSearch_close() {
    //     if (DEBUG_fn_call) console.log("function call: fn_onSearch_close()");
    //     // this.fn_onSearchSvg_mouseleave();
    //     // this.inputTarget.value = "";
    //     // this.searchToggleOnInput();
    //     this.input_containerTarget.classList.add("hbfsic-passive")
    //     this.input_containerTarget.classList.remove("hbfsic-active")
    //     this.svg_passiveTarget.classList.remove("hidden")
    //     this.svg_activeTarget.classList.add("hidden")
    //     this.inputTarget.value = ""
    // }
    // fn_onSearch_preferences() {
    //     console.log("Show search preferences");
    // }
    // private searchToggleOnInput() {
    //     const isEmpty = this.inputTarget.value.trim() === ""
    //     this.input_containerTarget.classList.toggle("hbfsic-passive", isEmpty);
    //     this.input_containerTarget.classList.toggle("hbfsic-active", !isEmpty);
    //     this.searchResultsTarget.classList.toggle("hidden", isEmpty);
    //     this.search_closeTarget.classList.toggle("hidden", isEmpty);
    // }
    //
    //
    //
    //
    //
    // private focusInputSoon() {
    //     requestAnimationFrame(() => {
    //         if (this.hasInputTarget) this.inputTarget.focus()
    //     })
    // }
    //
    // // ---- Internal helpers ----
    // //initialize
    // private ensureInitialize() {
    //     console.log("🔹 Stimulus Controller \"header_b\" initialized. id: ", this.idValue);
    //     console.log("data-controller=\"header_b\" has idValue ? : ", this.hasIdValue);
    //     console.log("Stimulus Controller \"header_b\" element in DOM: ", this.element);
    // }
    // private ensureElementHasIdValue() {
    //     // Generate id if missing for controller identity [data-header-id-value]
    //     if (!this.hasIdValue) {
    //         const gen = (crypto as any).randomUUID?.() || `tmp-${Date.now()}`
    //         this.element.setAttribute("data-header_b-id-value", gen)
    //         ;(this as any).idValue = gen
    //     }
    // }
    // private onLocaleChanged = (_e: Event) => this.render();
    // private onClickEvent = (_e: MouseEvent) => {
    //     const target = _e.target as HTMLElement;
    //     console.log("target: ", target);
    //     if (!target.closest("#hbf__search__input, #hb_search__select")){
    //         this.fn_onSearch_close();
    //         console.log("Click event on search input");
    //     }
    // }
    //
    // private ensureDefaults() {
    //     if (DEBUG_fn_call) console.log("function call: ensureDefaults()");
    //
    //     this.txt_search_placeholderValue = t("layouts.Search.placeholder");
    //     this.on_mouseenterValue = false;
    // }
    // //connect
    // private ensureConnect() {
    //     console.log("🟢 connect header_b Stimulus Controller");
    // }
    // private _init_state_0() {
    //     if (DEBUG_fn_call) console.log("function call: _init_state_0()");
    //
    //     this.inputTarget.value = "";
    //     this.inputTarget.placeholder = this.txt_search_placeholderValue
    // }
    // //disconnect
    // private ensureDisconnect(){
    //     console.log("🔴 disconnect header_b Stimulus Controller");
    // }

}




//  id : 019a4336-9a3d-77f4-9ae0-3cdf74511993
//
//  Stimulus controller imports and register
//      [index.js]

import { Application } from "@hotwired/stimulus";

import LayoutsController from "./views/layouts_controller.ts"
import SessionsController from "./views/sessions_controller.ts";
import RegistrationController from "./views/registration_controller.ts"
import PasswordsController from "./views/passwords_controller.ts";
import UserWorkspaceController from "./views/user-workspace_controller.ts"

import i18nController from "./i18n_controller.ts";
import ModalController from "./modal_controller";
import DiagnosticsController from "./diagnostics_controller.ts";
import LoadingController from "./loading_controller.ts";
import HeaderAController from "./header_a_controller.ts"
import HeaderBController from "./header_b_controller.ts"
import RemovableController from "./removable_controller.ts"

import ActivityBarController from "./activity_bar_controller.ts"

import FlashController from "./layouts/flash_controller.ts"
import ActivityIconController from "./layouts/activity_icon_controller.ts"
// import ExplorerItemController from "./layouts/explorer_item_controller.ts"


window.Stimulus ||= Application.start();

window.Stimulus.register("layouts", LayoutsController);
window.Stimulus.register("sessions", SessionsController);
window.Stimulus.register("registration", RegistrationController);
window.Stimulus.register("passwords", PasswordsController);
window.Stimulus.register("user-workspace", UserWorkspaceController);

window.Stimulus.register("i18n", i18nController);
window.Stimulus.register("modal", ModalController);
window.Stimulus.register("diagnostics", DiagnosticsController);
window.Stimulus.register("loading", LoadingController);
window.Stimulus.register("header-a", HeaderAController);
window.Stimulus.register("header-b", HeaderBController);
window.Stimulus.register("removable", RemovableController);

window.Stimulus.register("activity-bar", ActivityBarController);
window.Stimulus.register("flash", FlashController);
window.Stimulus.register("activity-icon", ActivityIconController);
// window.Stimulus.register("flash", ExplorerItemController);



import { Controller } from "@hotwired/stimulus";

// data-controller="profile-menu"
export default class extends Controller {
  static targets = ["button", "menu"];
  static values = {
    outside: { type: String, default: "body" }
  }

  connect() {
    this._onWindowClick = this._onWindowClick.bind(this);
    window.addEventListener("click", this._onWindowClick, true);
  }

  disconnect() {
    window.removeEventListener("click", this._onWindowClick, true);
  }

  toggle() {
    const willOpen = !this.menuTarget.classList.contains("show");
    this.menuTarget.classList.toggle("show", willOpen);
    this.buttonTarget.setAttribute("aria-expanded", willOpen ? "true" : "false");
  }

  _onWindowClick(e) {
    const scopeEl = this.element.closest(this.outsideValue) || this.element;
    if (scopeEl.contains(e.target)) return;

    if (this.menuTarget.classList.contains("show")) {
      this.menuTarget.classList.remove("show");
      this.buttonTarget.setAttribute("aria-expanded", "false");
    }
  }
}

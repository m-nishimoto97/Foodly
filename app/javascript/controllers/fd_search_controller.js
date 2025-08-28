
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "empty"]
  static values = {
    itemSelector: String,
    titleSelector: String,
    debounce: { type: Number, default: 200 }
  }

  connect() {
    // selects the items
    const selector = this.itemSelectorValue || ".fd-grid .col-6"
    this.items = Array.from(this.element.querySelectorAll(selector))

    // Handlers
    this._keydownHandler = (e) => {
      if (e.key === "Enter") e.preventDefault() // doesnt let the summit button to be pressed
    }
    this._inputHandler = () => this._debounce(() => this.filterNow(), this.debounceValue)

    // Listeners
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener("keydown", this._keydownHandler)
      this.inputTarget.addEventListener("input", this._inputHandler)
    }
    this.filterNow()
  }

  disconnect() {
    if (this.hasInputTarget) {
      this.inputTarget.removeEventListener("keydown", this._keydownHandler)
      this.inputTarget.removeEventListener("input", this._inputHandler)
    }
    clearTimeout(this._debounceTimer)
  }

  // prevents the submission
  prevent(event) {
    event.preventDefault()
  }

  // Filter
  filter() {
    this._debounce(() => this.filterNow(), this.debounceValue)
  }

  filterNow() {
    const q = (this.hasInputTarget ? this.inputTarget.value : "").trim().toLowerCase()
    const titleSel = this.titleSelectorValue || ".fd-recipe-title"
    let visible = 0

    for (const col of this.items) {
      // searchs for the title in the column
      const scope = col
      const titleNode = scope.querySelector(titleSel)
      const title = (titleNode?.textContent || "").toLowerCase()
      const match = q === "" ? true : title.includes(q)

      // uses hidden to hide the column
      col.toggleAttribute("hidden", !match)
      if (match) visible++
    }

    // manages the empty message
    if (this.hasEmptyTarget) {
      if (visible === 0) {
        this.emptyTarget.classList.remove("d-none")
        this.emptyTarget.removeAttribute("hidden")
      } else {
        this.emptyTarget.classList.add("d-none")
        this.emptyTarget.setAttribute("hidden", "")
      }
    }
  }

  // ---- utils ----
  _debounce(fn, wait) {
    clearTimeout(this._debounceTimer)
    this._debounceTimer = setTimeout(fn, wait)
  }
}

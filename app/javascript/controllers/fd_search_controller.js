// app/javascript/controllers/fd_search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "empty"]
  static values = {
    itemSelector: String,        // e.g., ".fd-grid .col-6"
    titleSelector: String,       // e.g., ".fd-recipe-title"
    debounce: { type: Number, default: 200 }
  }

  connect() {
    // Cachea items una vez
    const selector = this.itemSelectorValue || ".fd-grid .col-6"
    this.items = Array.from(this.element.querySelectorAll(selector))

    // Handlers
    this._keydownHandler = (e) => {
      if (e.key === "Enter") e.preventDefault() // bloquea submit con Enter
    }
    this._inputHandler = () => this._debounce(() => this.filterNow(), this.debounceValue)

    // Listeners
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener("keydown", this._keydownHandler)
      this.inputTarget.addEventListener("input", this._inputHandler)
    }

    // Primera pasada (por si viene con params[:query])
    this.filterNow()
  }

  disconnect() {
    if (this.hasInputTarget) {
      this.inputTarget.removeEventListener("keydown", this._keydownHandler)
      this.inputTarget.removeEventListener("input", this._inputHandler)
    }
    clearTimeout(this._debounceTimer)
  }

  // Previene submit del form (asignado en data-action del form)
  prevent(event) {
    event.preventDefault()
  }

  // Por si prefieres action="input->fd-search#filter" en el input
  filter() {
    this._debounce(() => this.filterNow(), this.debounceValue)
  }

  filterNow() {
    const q = (this.hasInputTarget ? this.inputTarget.value : "").trim().toLowerCase()
    const titleSel = this.titleSelectorValue || ".fd-recipe-title"
    let visible = 0

    for (const col of this.items) {
      // Busca el título dentro del link .fd-card-link o en la columna
      const scope = col
      const titleNode = scope.querySelector(titleSel)
      const title = (titleNode?.textContent || "").toLowerCase()
      const match = q === "" ? true : title.includes(q)

      // Usa atributo [hidden] para ocultar/mostrar
      col.toggleAttribute("hidden", !match)
      if (match) visible++
    }

    // Estado vacío opcional
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

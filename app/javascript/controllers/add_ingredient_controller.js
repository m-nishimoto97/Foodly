import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input","container","modal","list","error"]

  connect() {
    this.addBtn = this.containerTarget.querySelector('[data-role="add-button"]')
    this.modalTarget.addEventListener("hidden.bs.modal", () => {
      this.inputTarget.classList.remove("wrong")
      this.errorTarget.textContent = ""
      this.inputTarget.value = ""
    })
  }

  add() {
    const value = this.inputTarget.value.trim()
    if (!value) { this.errorTarget.textContent = "Please type an ingredient"; this.inputTarget.classList.add("wrong"); return }

    const exists = this.listTargets.some(el => el.textContent.trim().toLowerCase() === value.toLowerCase())
    if (exists) { this.errorTarget.textContent = "This ingredient is already on the list"; this.inputTarget.classList.add("wrong"); this.inputTarget.value=""; return }

    const id = `ingredient-${value.toLowerCase().replace(/[^a-z0-9]+/gi,"-")}`

    const node = document.createElement("div")
    node.className = "d-flex ps-1"
    node.innerHTML = `
      <input type="checkbox" multiple class="input-none" id="${id}" name="recipe[name][]" value="${value}">
      <label for="${id}" class="ingredient-container d-flex flex-column align-items-center ingredient-label">
        <img src="https://image.pollinations.ai/prompt/${value}" class="ingredient rounded-circle">
        <p data-add-ingredient-target="list" class="text-center">${value}</p>
      </label>
    `

    // insert the button BEFORE the other one
    this.containerTarget.insertBefore(node, this.addBtn)

    this.inputTarget.classList.remove("wrong")
    this.errorTarget.textContent = ""
    this.inputTarget.value = ""
    const modal = bootstrap.Modal.getInstance(this.modalTarget)
    if (modal) modal.hide()
  }
}

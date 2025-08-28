import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="add-ingredient"
export default class extends Controller {
  static targets = ["input","container", "modal", "list", "modal", "error"]
  connect() {
    this.modalTarget.addEventListener("hidden.bs.modal", () => {
      this.inputTarget.classList.remove("wrong");
      this.errorTarget.innerText = ""
    })
  }

  add() {
    const value = this.inputTarget.value
    const exists = this.listTargets.some(item => item.innerText === value)
    console.log(this.inputTarget);

      if(!exists){
        this.containerTarget.insertAdjacentHTML(
          "beforeend", `<input type="checkbox" multiple class="input-none" id="ingredient-${value}" name="recipe[name][]" value="${value}">
          <label for="ingredient-${value}" class="d-flex flex-column align-items-center ingredient-label">
          <img src="https://cdn.pixabay.com/photo/2020/06/18/18/36/carrot-5314608_1280.jpg" class="ingredient rounded-circle">
          <p data-add-ingredient-target="list" class="text-center">${value}</p>
          </label>`
        )
        this.inputTarget.classList.remove("wrong")
        this.errorTarget.innerText = ""
        this.inputTarget.value = "";
        const modalInstance = bootstrap.Modal.getInstance(this.modalTarget)
        modalInstance.hide()
      }else{
        this.inputTarget.classList.add("wrong")
        this.errorTarget.innerText = "This ingredient is already on the list"
        this.inputTarget.value = "";
      }
  }
}

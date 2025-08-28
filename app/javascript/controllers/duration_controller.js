import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="duration"
export default class extends Controller {
  connect() {
    const btns = document.querySelectorAll(".form-check");
    btns.forEach((btn)=>{
      btn.addEventListener("click",()=>{
        const inputRadio = btn.querySelector("input")
        inputRadio.checked = true
      })
    })
  }

}

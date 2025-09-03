import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="scheduler"
export default class extends Controller {
  static targets = ["searchinput", "recipeInput", "divRecipeCards", "formScheduler"]
  static values = { url: String }

  submit() {
    const query = this.searchinputTarget.value
    fetch(`${this.urlValue}?query=${encodeURIComponent(query)}`, {
      headers: { Accept: "text/vnd.turbo-stream.html" }
    })
    .then(response => response.text())
    .then(html => Turbo.renderStreamMessage(html))
  }

  selectRecipe(event) {
    const cards = this.divRecipeCardsTarget.querySelectorAll(".card-recipe");
    cards.forEach(element => {
      element.classList.remove("card-highlight");
    });
    event.currentTarget.classList.add("card-highlight");
    this.recipeInputTarget.value = event.currentTarget.dataset.id;
  }

  reset() {
    this.formSchedulerTarget.reset()
  }

}

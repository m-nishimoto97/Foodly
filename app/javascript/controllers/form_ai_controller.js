import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-ai"
export default class extends Controller {
  static targets = ["customPeriodInput","hiddenPeriod"]
  connect() {
    this.setPeriodValue("7");
  }

  periodClick(event) {
    console.log(event.target.value );

    const value = event.target.value
    if (value === "other") {
      this.setPeriodValue("");
      this.customPeriodInputTarget.classList.remove("d-none");
    }
    else {
      this.setPeriodValue(value);
      this.customPeriodInputTarget.classList.add("d-none");
    }
  }

  setPeriodValue(value) {
    console.log("periodvalue");

    this.hiddenPeriodTarget.value = value;
  }
}

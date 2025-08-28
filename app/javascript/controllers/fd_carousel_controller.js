import { Controller } from "@hotwired/stimulus";

// data-controller="fd-carousel"
export default class extends Controller {
  static targets = ["track", "prev", "next"];

  connect() {
    if (!this.trackTarget.hasAttribute("tabindex")) {
      this.trackTarget.setAttribute("tabindex", "0");
    }
  }

  slideWidth() {
    return this.trackTarget.getBoundingClientRect().width || 0;
  }

  slides() {
    return Array.from(this.trackTarget.children);
  }

  maxIndex() {
    return Math.max(0, this.slides().length - 1);
  }

  currentIndex() {
    const w = this.slideWidth();
    return w ? Math.round(this.trackTarget.scrollLeft / w) : 0;
  }

  goToIndex(i) {
    this.trackTarget.scrollTo({ left: i * this.slideWidth(), behavior: "smooth" });
  }

  prev() {
    const i = this.currentIndex();
    this.goToIndex(i <= 0 ? this.maxIndex() : i - 1);
  }

  next() {
    const i = this.currentIndex();
    this.goToIndex(i >= this.maxIndex() ? 0 : i + 1);
  }

  keydown(e) {
    if (e.key === "ArrowLeft")  this.prev();
    if (e.key === "ArrowRight") this.next();
  }
}

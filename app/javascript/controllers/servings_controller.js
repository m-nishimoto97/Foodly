import { Controller } from "@hotwired/stimulus"

/**
 * servings_controller.js
 * Scales ingredient amounts shown in nodes marked with data-servings-target="amount"
 * The base amount is read from data-base-amount (e.g., "1 1/2 cup", "2-3 cloves", "to taste")
 * Requires an <input type="range"> (or number) target named "input" and optional "output"
 */
export default class extends Controller {
  static targets = ["input", "output", "amount"]
  static values  = { base: Number, hintSelector: String }

  // --- configuration for pluralization/units ---
  commonUnits = [
    // volumes
    "cup","cups","tbsp","tbsps","tablespoon","tablespoons","tsp","tsps","teaspoon","teaspoons",
    "ml","l","liter","liters",
    // weights
    "g","kg","gram","grams","kilogram","kilograms","oz","ounce","ounces","lb","pound","pounds",
    // count nouns
    "clove","cloves","egg","eggs","slice","slices","leaf","leaves","sprig","sprigs","piece","pieces",
    // misc
    "pinch","pinches","dash","dashes","stick","sticks","can","cans"
  ]

  // Units that should NOT pluralize even if qty > 1
  uncountableUnits = new Set(["g","kg","ml","l","oz","lb"])

  // Irregular plurals
  irregularPlural = new Map([
    ["leaf", "leaves"],
    ["loaf", "loaves"],
    ["tomato", "tomatoes"],
    ["potato", "potatoes"],
    ["person", "people"],
    ["tablespoon", "tablespoons"],
    ["teaspoon", "teaspoons"]
  ])

  connect() {
    this.hintEl = this.hintSelectorValue ? document.querySelector(this.hintSelectorValue) : null
    this.update()
  }

  // Called by input/change actions on the slider
  update() {
    const base = this.baseValue || 2
    const people = Number(this.inputTarget?.value || base)
    const factor = people / base

    if (this.outputTarget) this.outputTarget.value = String(people)

    this.amountTargets.forEach(el => {
      const raw = el.dataset.baseAmount || ""
      const parsed = this.parse(raw) // { qty/unit/rest/trailing } OR { min/max/unit/... } OR taste-note

      let line
      if (parsed.qty != null) {
        const scaled = parsed.qty * factor
        const unitOrRest = parsed.unit || this.extractUnitFromRest(parsed.rest) || ""
        line = `${this.formatQty(scaled)}${this.maybePlural(unitOrRest, scaled)}${this.cleanRest(parsed.rest)}${parsed.trailing}`
      } else if (parsed.min != null && parsed.max != null) {
        const min = parsed.min * factor
        const max = parsed.max * factor
        const mid = (min + max) / 2
        const unitOrRest = parsed.unit || this.extractUnitFromRest(parsed.rest) || ""
        line = `${this.formatQty(min)}–${this.formatQty(max)}${this.maybePlural(unitOrRest, mid)}${this.cleanRest(parsed.rest)}${parsed.trailing}`
      } else {
        // not parseable → keep original (but sanitized)
        line = this.finalTidy(this.sanitizeAmount(raw))
      }

      el.textContent = line.trim().replace(/\s+/g, " ")
    })
  }

  // ----------------- SANITIZE -----------------

  sanitizeAmount(str) {
    let s = String(str || "").trim()

    // 0) Normalize Unicode fraction slash (U+2044) to "/"
    s = s.replace(/\u2044/g, "/")

    // 1) Normalize common Unicode fraction glyphs to ASCII
    s = s.replace(/¼/g, "1/4").replace(/½/g, "1/2").replace(/¾/g, "3/4")

    // 2) Normalize dashes in ranges to hyphen
    s = s.replace(/[–—]/g, "-")

    // 3) Collapse spaces around slashes
    s = s.replace(/\s*\/\s*/g, "/")

    // 4) Collapse multiple spaces
    s = s.replace(/\s+/g, " ").trim()

    // 5) Remove duplicate fraction tails: keep the FIRST "/N"
    //    e.g., "6 1/2/2 cup" -> "6 1/2 cup", "1/2/4 cup" -> "1/2 cup"
    s = s.replace(/(\b\d+(?:\s+\d+\/\d+)?|\b\d+)(\/\d+)(?:\/\d+)+/g, "$1$2")

    // 6) Remove stray "/N" not attached to a number, e.g., "1/2 /2 cup" -> "1/2 cup"
    s = s.replace(/(^|[^\d])\/\d+(\b)/g, "$1")

    // 7) Remove slash directly before a unit: "1/2 /cup" -> "1/2 cup"
    s = s.replace(/\/(?=[a-zA-Z])/g, " ")

    // 8) Ensure mixed-number spacing: "6  1/2" -> "6 1/2"
    s = s.replace(/(\d)\s+(\d\/\d)/g, "$1 $2")

    // 9) Ensure unit sticks to the number: "6 1/2cup" -> "6 1/2 cup"
    s = s.replace(/(\d(?:\s+\d\/\d)?)([a-zA-Z]+)/g, "$1 $2")

    // 10) Final collapse
    s = s.replace(/\s+/g, " ").trim()
    return s
  }

  // ----------------- PARSE -----------------

  parse(str) {
    const s0 = this.sanitizeAmount(str)
    let s = s0.toLowerCase()

    // taste/pinch: not scaled numerically
    if (/(^|\s)(to taste|al gusto|a gusto|pinch|pizca)(\s|$)/i.test(s)) {
      return { qty: null, unit: null, rest: " to taste", trailing: "" }
    }

    // Extract trailing note e.g. "(finely chopped)" or "aprox."
    let trailing = "", main = s
    const note = s.match(/\s*(\([^)]+\)|-?\s*aprox\.?)\s*$/i)
    if (note) {
      trailing = " " + note[1]
      main = s.slice(0, note.index).trim()
    }

    // RANGE: "2-3 cups" | "1 1/2-2 cups" | "1-2"
    let m = main.match(/^(\d+(?:\s+\d\/\d)?|\d+(?:\.\d+)?)[ ]*-[ ]*(\d+(?:\s+\d\/\d)?|\d+(?:\.\d+)?)(?:\s+([a-z_]+))?(.*)$/i)
    if (m) {
      return {
        min: this.toNumber(m[1]),
        max: this.toNumber(m[2]),
        unit: (m[3] || "").trim(),
        rest: (m[4] || ""),
        trailing
      }
    }

    // SIMPLE: "1 1/2 cups" | "2.5 cup" | "3 eggs" | "250 g" | "6 1/2"
    m = main.match(/^(\d+(?:\s+\d\/\d)?|\d+(?:\.\d+)?)(?:\s+([a-z_]+))?(.*)$/i)
    if (m) {
      return {
        qty: this.toNumber(m[1]),
        unit: (m[2] || "").trim(),
        rest: (m[3] || ""),
        trailing
      }
    }

    // Fallback: nothing parseable
    return { qty: null, unit: null, rest: "", trailing: "" }
  }

  // Convert "1 1/2" | "1/2" | "2.5" → Number
  toNumber(t) {
    const s = String(t).trim()
    if (/\d+\s+\d\/\d/.test(s)) { // mixed number "6 1/2"
      const [a, b] = s.split(/\s+/)
      return (parseFloat(a) || 0) + this.frac(b)
    }
    if (s.includes("/")) return this.frac(s)
    return parseFloat(s)
  }

  frac(f) {
    const [n, d] = f.split("/")
    const num = parseFloat(n)
    const den = parseFloat(d)
    return den ? num / den : num
  }

  // ----------------- FORMAT / PLURAL -----------------

  // round to quarters; print as mixed number
  formatQty(x) {
    if (x == null || isNaN(x)) return ""
    const r = Math.round(x * 4) / 4
    const whole = Math.trunc(r)
    const frac = r - whole
    const fracStr =
      frac === 0   ? "" :
      frac === 0.25? "1/4" :
      frac === 0.5 ? "1/2" :
      frac === 0.75? "3/4" :
      r.toFixed(2).replace(/\.00$/, "")
    if (!whole && fracStr) return fracStr
    if (whole && fracStr)  return `${whole} ${fracStr}`
    return String(whole)
  }

  // tries to keep/repair the unit if it was in the "rest"
  extractUnitFromRest(rest) {
    if (!rest) return ""
    const tokens = rest.trim().split(/\s+/)
    // Look for known unit at the start of rest
    const candidate = tokens[0]?.toLowerCase() || ""
    if (this.commonUnits.includes(candidate)) return candidate
    return ""
  }

  cleanRest(rest) {
    if (!rest) return ""
    let t = String(rest).trim()
    // If rest begins with a known unit and we already printed the unit, drop duplicate
    const first = t.split(/\s+/)[0]?.toLowerCase()
    if (this.commonUnits.includes(first)) {
      t = t.replace(new RegExp(`^${first}\\b`, "i"), "").trim()
    }
    return t ? ` ${t}` : ""
  }

  maybePlural(unitRaw, qty) {
    const u = (unitRaw || "").trim()
    if (!u) return ""

    // If already ends with 's' and not a singular-only unit, keep as is
    const unit = u.toLowerCase()

    // quantities close to 1 should be singular (tolerance for rounding like 0.99–1.01)
    const isPlural = qty > 1.01

    // Uncountable units never pluralize (g, kg, ml, l, oz, lb)
    if (this.uncountableUnits.has(unit)) return ` ${u}`

    if (!isPlural) return ` ${u}`

    // Irregulars
    if (this.irregularPlural.has(unit)) return ` ${this.irregularPlural.get(unit)}`

    // Heuristics
    if (unit.endsWith("s")) return ` ${u}`               // already plural
    if (unit.endsWith("ch") || unit.endsWith("sh")) return ` ${u}es`
    if (unit.endsWith("x") || unit.endsWith("z")) return ` ${u}es`
    if (unit.endsWith("y") && !/[aeiou]y$/i.test(unit))  return ` ${u.slice(0, -1)}ies`
    if (unit.endsWith("f"))  return ` ${u.slice(0, -1)}ves`
    if (unit.endsWith("fe")) return ` ${u.slice(0, -2)}ves`
    return ` ${u}s`
  }

  // final pass to tidy double spaces etc.
  finalTidy(s) {
    return String(s || "").replace(/\s+/g, " ").trim()
  }
}

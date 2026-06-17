import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "theme"

export default class extends Controller {
  static targets = ["light", "dark"]

  connect() {
    this.#syncUI()
  }

  selectLight() {
    this.#apply("light")
  }

  selectDark() {
    this.#apply("dark")
  }

  #apply(theme) {
    document.documentElement.classList.toggle("dark", theme === "dark")
    localStorage.setItem(STORAGE_KEY, theme)
    this.#syncUI()
  }

  #syncUI() {
    const isDark = document.documentElement.classList.contains("dark")

    this.lightTarget.setAttribute("aria-pressed", String(!isDark))
    this.darkTarget.setAttribute("aria-pressed", String(isDark))
  }
}

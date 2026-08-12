import { Controller } from "@hotwired/stimulus"

// Maps pointer position around the avatar to one of 8 gaze directions (+ center).
const DIRECTIONS = [
  "right",
  "down-right",
  "down",
  "down-left",
  "left",
  "up-left",
  "up",
  "up-right",
]

export default class extends Controller {
  static targets = ["frame"]
  static values = {
    centerRadius: { type: Number, default: 40 },
  }

  connect() {
    this.current = "center"
    this.boundMove = (event) => this.#onMove(event)
    this.boundLeave = () => this.#onLeave()
    window.addEventListener("pointermove", this.boundMove, { passive: true })
    window.addEventListener("pointerleave", this.boundLeave)
    document.addEventListener("mouseleave", this.boundLeave)
  }

  disconnect() {
    window.removeEventListener("pointermove", this.boundMove)
    window.removeEventListener("pointerleave", this.boundLeave)
    document.removeEventListener("mouseleave", this.boundLeave)
  }

  #onLeave() {
    this.#setDirection("center")
  }

  #onMove(event) {
    const rect = this.frameTarget.getBoundingClientRect()
    const cx = rect.left + rect.width / 2
    const cy = rect.top + rect.height / 2
    const dx = event.clientX - cx
    const dy = event.clientY - cy
    const distance = Math.hypot(dx, dy)

    if (distance < this.centerRadiusValue) {
      this.#setDirection("center")
      return
    }

    // atan2: 0 = right, positive = clockwise in screen coords (y down)
    let angle = (Math.atan2(dy, dx) * 180) / Math.PI
    if (angle < 0) angle += 360

    const index = Math.round(angle / 45) % 8
    this.#setDirection(DIRECTIONS[index])
  }

  #setDirection(direction) {
    if (this.current === direction) return
    this.current = direction
    this.element.dataset.gaze = direction
  }
}

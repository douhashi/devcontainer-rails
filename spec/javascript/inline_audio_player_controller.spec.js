import { Application } from "@hotwired/stimulus"
import InlineAudioPlayerController from "../../app/frontend/controllers/inline_audio_player_controller"

describe("InlineAudioPlayerController", () => {
  let application
  let controller
  let element

  beforeEach(() => {
    // Custom elements mock for media-chrome
    customElements.define = jest.fn()

    // Setup DOM
    document.body.innerHTML = `
      <div
        data-controller="inline-audio-player"
        data-inline-audio-player-id-value="1"
        data-inline-audio-player-type-value="track"
        data-inline-audio-player-title-value="Test Track"
        data-inline-audio-player-url-value="http://example.com/audio.mp3"
      >
        <media-controller>
          <audio slot="media" src="http://example.com/audio.mp3"></audio>
        </media-controller>
      </div>
    `

    element = document.querySelector('[data-controller="inline-audio-player"]')

    // Setup Stimulus
    application = Application.start()
    application.register("inline-audio-player", InlineAudioPlayerController)

    controller = application.getControllerForElementAndIdentifier(element, "inline-audio-player")
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })

  describe("initialization", () => {
    it("should initialize with correct values", () => {
      expect(controller.idValue).toBe("1")
      expect(controller.typeValue).toBe("track")
      expect(controller.titleValue).toBe("Test Track")
      expect(controller.urlValue).toBe("http://example.com/audio.mp3")
    })

    it("should initialize the global store", () => {
      expect(window.inlineAudioPlayerStore).toBeDefined()
      expect(window.inlineAudioPlayerStore.currentPlayer).toBeNull()
    })
  })

  describe("play event handling", () => {
    let mediaController
    let audioElement

    beforeEach(() => {
      mediaController = element.querySelector("media-controller")
      audioElement = element.querySelector("audio")

      // Mock audio element methods
      audioElement.pause = jest.fn()
      audioElement.play = jest.fn()
      audioElement.paused = true
    })

    it("should handle play event", () => {
      const playEvent = new Event("play", { bubbles: true })
      mediaController.dispatchEvent(playEvent)

      expect(window.inlineAudioPlayerStore.currentPlayer).toBe(controller)
    })

    it("should pause other players when playing", () => {
      // Setup another player
      const otherElement = document.createElement("div")
      otherElement.innerHTML = `
        <media-controller>
          <audio slot="media" src="http://example.com/other.mp3"></audio>
        </media-controller>
      `
      otherElement.setAttribute("data-controller", "inline-audio-player")
      document.body.appendChild(otherElement)

      const otherController = application.getControllerForElementAndIdentifier(
        otherElement,
        "inline-audio-player"
      )

      const otherAudio = otherElement.querySelector("audio")
      otherAudio.pause = jest.fn()
      otherAudio.paused = false

      // Set the other player as current
      window.inlineAudioPlayerStore.currentPlayer = otherController

      // Play the first player
      const playEvent = new Event("play", { bubbles: true })
      mediaController.dispatchEvent(playEvent)

      // Other player should be paused
      expect(otherAudio.pause).toHaveBeenCalled()
      expect(window.inlineAudioPlayerStore.currentPlayer).toBe(controller)
    })
  })

  describe("pause event handling", () => {
    let mediaController

    beforeEach(() => {
      mediaController = element.querySelector("media-controller")
      window.inlineAudioPlayerStore.currentPlayer = controller
    })

    it("should clear current player on pause", () => {
      const pauseEvent = new Event("pause", { bubbles: true })
      mediaController.dispatchEvent(pauseEvent)

      expect(window.inlineAudioPlayerStore.currentPlayer).toBeNull()
    })
  })

  describe("disconnect", () => {
    it("should clean up on disconnect", () => {
      window.inlineAudioPlayerStore.currentPlayer = controller

      controller.disconnect()

      expect(window.inlineAudioPlayerStore.currentPlayer).toBeNull()
    })
  })

  describe("error handling", () => {
    let mediaController
    let audioElement

    beforeEach(() => {
      mediaController = element.querySelector("media-controller")
      audioElement = element.querySelector("audio")
      console.error = jest.fn()
    })

    it("should handle audio error events", () => {
      const errorEvent = new Event("error", { bubbles: true })
      audioElement.dispatchEvent(errorEvent)

      expect(console.error).toHaveBeenCalledWith(
        "Audio playback error:",
        expect.objectContaining({ id: "1", type: "track" })
      )
    })
  })

  describe("global event emission", () => {
    let mediaController

    beforeEach(() => {
      mediaController = element.querySelector("media-controller")
    })

    it("should emit custom audio:play event", () => {
      const eventListener = jest.fn()
      window.addEventListener("audio:play", eventListener)

      const playEvent = new Event("play", { bubbles: true })
      mediaController.dispatchEvent(playEvent)

      expect(eventListener).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: expect.objectContaining({
            id: "1",
            type: "track",
            title: "Test Track",
            url: "http://example.com/audio.mp3"
          })
        })
      )
    })

    it("should emit custom audio:pause event", () => {
      const eventListener = jest.fn()
      window.addEventListener("audio:pause", eventListener)

      const pauseEvent = new Event("pause", { bubbles: true })
      mediaController.dispatchEvent(pauseEvent)

      expect(eventListener).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: expect.objectContaining({
            id: "1",
            type: "track"
          })
        })
      )
    })
  })
})
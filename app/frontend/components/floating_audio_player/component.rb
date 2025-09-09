# frozen_string_literal: true

class FloatingAudioPlayer::Component < ApplicationViewComponent
  private

  def player_id
    "floating-audio-player"
  end

  def audio_id
    "floating-audio"
  end

  def container_classes
    [
      "fixed",
      "bottom-4",
      "right-4",
      "z-50",
      "hidden",
      "bg-gray-900",
      "text-white",
      "rounded-lg",
      "shadow-2xl",
      "p-4",
      "w-full",
      "sm:w-96",
      "transition-all",
      "duration-300",
      "transform",
      "translate-y-0"
    ].join(" ")
  end

  def plyr_config
    {
      controls: [ "play", "progress", "current-time" ],
      invertTime: false,
      clickToPlay: false,
      keyboard: { focused: false, global: false }
    }.to_json
  end

  def button_classes
    "p-2 rounded-full hover:bg-gray-800 transition-colors"
  end

  def close_button_classes
    "absolute top-2 right-2 p-1 rounded-full hover:bg-gray-800 transition-colors"
  end
end

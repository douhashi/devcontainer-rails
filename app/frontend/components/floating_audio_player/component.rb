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
      "bottom-0",
      "left-0",
      "right-0",
      "z-50",
      "hidden",
      "bg-gray-800",
      "text-white",
      "shadow-lg",
      "border-t",
      "border-gray-700",
      "w-full",
      "h-16",
      "flex",
      "items-center",
      "px-4",
      "sm:px-6",
      "transition-all",
      "duration-300",
      "transform",
      "translate-y-0"
    ].join(" ")
  end


  def button_classes
    "w-11 h-11 flex items-center justify-center rounded-full hover:bg-gray-700 transition-colors"
  end

  def close_button_classes
    "w-8 h-8 flex items-center justify-center rounded-full hover:bg-gray-700 transition-colors"
  end

  def track_info_classes
    "flex-shrink-0 min-w-0 mr-4"
  end

  def controls_section_classes
    "flex-1 flex items-center justify-center"
  end

  def button_group_classes
    "flex items-center justify-center gap-2"
  end

  def close_section_classes
    "flex-shrink-0 ml-4"
  end
end

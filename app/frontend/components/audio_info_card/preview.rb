module AudioInfoCard
  class Preview < ApplicationViewComponentPreview
    def default
      render_with_template(
        template: "audio_info_card/preview/default"
      )
    end

    def with_pending_status
      audio = Audio.new(
        id: 1,
        status: "pending",
        created_at: 1.hour.ago,
        updated_at: 1.hour.ago,
        metadata: {}
      )
      render(AudioInfoCard::Component.new(audio:))
    end

    def with_processing_status
      audio = Audio.new(
        id: 1,
        status: "processing",
        created_at: 2.hours.ago,
        updated_at: 30.minutes.ago,
        metadata: {}
      )
      render(AudioInfoCard::Component.new(audio:))
    end

    def with_completed_status
      audio = Audio.new(
        id: 1,
        status: "completed",
        created_at: 1.day.ago,
        updated_at: 1.day.ago,
        metadata: { "duration" => 180 }
      )
      render(AudioInfoCard::Component.new(audio:))
    end

    def with_failed_status
      audio = Audio.new(
        id: 1,
        status: "failed",
        created_at: 3.hours.ago,
        updated_at: 2.hours.ago,
        metadata: {}
      )
      render(AudioInfoCard::Component.new(audio:))
    end

    def with_long_duration
      audio = Audio.new(
        id: 1,
        status: "completed",
        created_at: 2.days.ago,
        updated_at: 2.days.ago,
        metadata: { "duration" => 3665 }  # 61:05
      )
      render(AudioInfoCard::Component.new(audio:))
    end

    def without_audio
      render(AudioInfoCard::Component.new(audio: nil))
    end
  end
end

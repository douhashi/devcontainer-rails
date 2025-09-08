class GenerateMusicJob < ApplicationJob
  queue_as :default

  MAX_POLLING_ATTEMPTS = 20
  POLLING_INTERVAL = 30.seconds
  SAMPLE_PROMPT = "Create a relaxing lo-fi hip-hop beat for studying"

  retry_on Kie::Errors::NetworkError, wait: :exponentially_longer, attempts: 3
  retry_on Kie::Errors::RateLimitError, wait: :exponentially_longer, attempts: 5

  def perform(music_generation_id)
    @music_generation = MusicGeneration.find(music_generation_id)
    @service = KieService.new

    return if @music_generation.status.completed? || @music_generation.status.failed?

    if @music_generation.status.pending?
      start_generation
    elsif @music_generation.status.processing?
      poll_task_status
    end
  rescue StandardError => e
    handle_error(e)
  end

  private

  def start_generation
    ActiveRecord::Base.transaction do
      @music_generation.processing!

      prompt = @music_generation.prompt.presence || SAMPLE_PROMPT
      task_id = @service.generate_music(prompt: prompt, model: @music_generation.generation_model)

      @music_generation.metadata["task_id"] = task_id
      @music_generation.metadata["polling_attempts"] = 0

      @music_generation.metadata["status_history"] ||= []
      @music_generation.metadata["status_history"] << {
        "status" => "pending_to_processing",
        "timestamp" => Time.current.iso8601,
        "task_id" => task_id
      }

      @music_generation.task_id = task_id
      @music_generation.save!

      Rails.logger.info "Started music generation for MusicGeneration ##{@music_generation.id} with task_id: #{task_id}, prompt: #{prompt.truncate(100)}"
    end

    self.class.set(wait: POLLING_INTERVAL).perform_later(@music_generation.id)
  end

  def poll_task_status
    return if check_polling_limit

    task_id = @music_generation.task_id
    status_response = @service.get_task_status(task_id)

    normalized_status = status_response["status"].to_s.downcase

    Rails.logger.info "Status transition for MusicGeneration ##{@music_generation.id}: #{normalized_status} (raw: #{status_response['status']})"

    case normalized_status
    when "processing", "first_success"
      handle_processing_status
    when "completed", "success"
      handle_completed_status(status_response)
    when "failed"
      handle_failed_status(status_response)
    else
      Rails.logger.warn "Unknown task status: #{status_response['status']} for MusicGeneration ##{@music_generation.id}"
      Rails.logger.warn "Full response: #{status_response.inspect}"
      handle_processing_status
    end
  end

  def check_polling_limit
    polling_attempts = @music_generation.metadata["polling_attempts"].to_i

    if polling_attempts >= MAX_POLLING_ATTEMPTS
      @music_generation.metadata["error"] = "音楽生成がタイムアウトしました（10分経過）。処理に時間がかかっています。"
      @music_generation.fail!
      Rails.logger.error "Polling timeout for MusicGeneration ##{@music_generation.id} after #{polling_attempts} attempts"
      return true
    end
    false
  end

  def handle_processing_status
    @music_generation.metadata["polling_attempts"] = @music_generation.metadata["polling_attempts"].to_i + 1
    @music_generation.save!

    Rails.logger.info "MusicGeneration ##{@music_generation.id} still processing, attempt #{@music_generation.metadata['polling_attempts']}"
    self.class.set(wait: POLLING_INTERVAL).perform_later(@music_generation.id)
  end

  def handle_completed_status(status_response)
    music_data_array = @service.extract_all_music_data(status_response)

    if music_data_array.empty?
      raise StandardError, "No audio data in completed task response"
    end

    ActiveRecord::Base.transaction do
      music_data_array.each_with_index do |music_data, index|
        create_track_from_music_data(music_data, index)
      end

      @music_generation.metadata["status_history"] ||= []
      @music_generation.metadata["status_history"] << {
        "status" => "processing_to_completed",
        "timestamp" => Time.current.iso8601,
        "track_count" => music_data_array.size
      }

      @music_generation.complete!

      Rails.logger.info "Successfully completed music generation for MusicGeneration ##{@music_generation.id} with #{music_data_array.size} tracks"
    end
  end

  def create_track_from_music_data(music_data, variant_index)
    track = @music_generation.tracks.build(
      content: @music_generation.content,
      variant_index: variant_index,
      status: :pending,
      metadata: {}
    )

    temp_file = Tempfile.new([ "track_audio_#{variant_index}", ".mp3" ])
    begin
      audio_path = @service.download_audio(music_data[:audio_url], temp_file.path)

      File.open(audio_path, "rb") do |file|
        track.audio = file
      end

      track.metadata["audio_url"] = music_data[:audio_url]
      track.metadata["music_title"] = music_data[:title] if music_data[:title].present?
      track.metadata["music_tags"] = music_data[:tags] if music_data[:tags].present?
      track.metadata["model_name"] = music_data[:model_name] if music_data[:model_name].present?
      track.metadata["generated_prompt"] = music_data[:generated_prompt] if music_data[:generated_prompt].present?
      track.metadata["audio_id"] = music_data[:audio_id] if music_data[:audio_id].present?

      if music_data[:duration].present?
        track.duration = music_data[:duration].to_i
      else
        analyze_and_store_duration(track, audio_path)
      end

      track.status = :completed
      track.save!

      Rails.logger.info "Created Track ##{track.id} (variant #{variant_index}) for MusicGeneration ##{@music_generation.id} with title: #{music_data[:title]}"
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def analyze_and_store_duration(track, audio_path)
    analysis_service = AudioAnalysisService.new
    duration = analysis_service.analyze_duration(audio_path)
    track.duration = duration

    Rails.logger.info "Analyzed duration for Track ##{track.id}: #{duration} seconds"
  rescue StandardError => e
    Rails.logger.error "Failed to analyze duration for Track ##{track.id}: #{e.message}"
  end

  def handle_failed_status(status_response)
    error_message = status_response["error"] || "Unknown error"

    @music_generation.metadata["error"] = error_message

    @music_generation.metadata["status_history"] ||= []
    @music_generation.metadata["status_history"] << {
      "status" => "processing_to_failed",
      "timestamp" => Time.current.iso8601,
      "error" => error_message
    }

    @music_generation.fail!

    Rails.logger.error "Music generation failed for MusicGeneration ##{@music_generation.id}: #{error_message}"
  end

  def handle_error(error)
    Rails.logger.error "Error in GenerateMusicJob for MusicGeneration ##{@music_generation.id}: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")

    @music_generation.metadata["error"] = "Job error: #{error.message}"
    @music_generation.fail!
  end
end

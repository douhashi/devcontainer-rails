class GenerateTrackJob < ApplicationJob
  queue_as :default

  MAX_POLLING_ATTEMPTS = 20
  POLLING_INTERVAL = 30.seconds
  SAMPLE_PROMPT = "Create a relaxing lo-fi hip-hop beat for studying"

  retry_on Kie::Errors::NetworkError, wait: :exponentially_longer, attempts: 3
  retry_on Kie::Errors::RateLimitError, wait: :exponentially_longer, attempts: 5

  def perform(track_id)
    @track = Track.find(track_id)
    @service = KieService.new

    return if @track.status.completed? || @track.status.failed?

    if @track.status.pending?
      start_generation
    elsif @track.status.processing?
      poll_task_status
    end
  rescue StandardError => e
    handle_error(e)
  end

  private

  def start_generation
    ActiveRecord::Base.transaction do
      @track.status = :processing

      prompt = @track.content&.audio_prompt.presence || SAMPLE_PROMPT
      task_id = @service.generate_music(prompt: prompt)
      @track.metadata["task_id"] = task_id
      @track.metadata["polling_attempts"] = 0
      @track.save!

      Rails.logger.info "Started music generation for Track ##{@track.id} with task_id: #{task_id}, prompt: #{prompt.truncate(100)}"
    end

    self.class.set(wait: POLLING_INTERVAL).perform_later(@track.id)
  end

  def poll_task_status
    return if check_polling_limit

    task_id = @track.metadata["task_id"]
    status_response = @service.get_task_status(task_id)

    # Normalize status to lowercase for comparison
    normalized_status = status_response["status"].to_s.downcase

    case normalized_status
    when "processing"
      handle_processing_status
    when "completed", "success"
      handle_completed_status(status_response)
    when "failed"
      handle_failed_status(status_response)
    else
      Rails.logger.warn "Unknown task status: #{status_response['status']} for Track ##{@track.id}"
      Rails.logger.warn "Full response: #{status_response.inspect}"
      handle_processing_status
    end
  end

  def check_polling_limit
    polling_attempts = @track.metadata["polling_attempts"].to_i

    if polling_attempts >= MAX_POLLING_ATTEMPTS
      @track.metadata["error"] = "音楽生成がタイムアウトしました（10分経過）。処理に時間がかかっています。"
      @track.status = :failed
      @track.save!
      Rails.logger.error "Polling timeout for Track ##{@track.id} after #{polling_attempts} attempts"
      return true
    end
    false
  end

  def handle_processing_status
    @track.metadata["polling_attempts"] = @track.metadata["polling_attempts"].to_i + 1
    @track.save!

    Rails.logger.info "Track ##{@track.id} still processing, attempt #{@track.metadata['polling_attempts']}"
    self.class.set(wait: POLLING_INTERVAL).perform_later(@track.id)
  end

  def handle_completed_status(status_response)
    audio_url = status_response.dig("output", "audio_url")

    if audio_url.blank?
      raise StandardError, "No audio URL in completed task response"
    end

    ActiveRecord::Base.transaction do
      download_and_attach_audio(audio_url)

      @track.metadata["audio_url"] = audio_url
      @track.status = :completed
      @track.save!

      Rails.logger.info "Successfully completed music generation for Track ##{@track.id}"
    end
  end

  def handle_failed_status(status_response)
    error_message = status_response["error"] || "Unknown error"

    @track.metadata["error"] = error_message
    @track.status = :failed
    @track.save!

    Rails.logger.error "Music generation failed for Track ##{@track.id}: #{error_message}"
  end

  def download_and_attach_audio(audio_url)
    temp_file = Tempfile.new([ "track_audio", ".mp3" ])
    audio_path = @service.download_audio(audio_url, temp_file.path)

    File.open(audio_path, "rb") do |file|
      @track.audio = file
    end

    # Analyze duration after audio attachment
    analyze_and_store_duration(audio_path)

    @track.save!

    temp_file.close
    temp_file.unlink
  rescue => e
    Rails.logger.error "Failed to attach audio for Track ##{@track.id}: #{e.message}"
    raise
  end

  def analyze_and_store_duration(audio_path)
    analysis_service = AudioAnalysisService.new
    duration = analysis_service.analyze_duration(audio_path)
    @track.duration = duration

    Rails.logger.info "Analyzed duration for Track ##{@track.id}: #{duration} seconds"
  rescue StandardError => e
    Rails.logger.error "Failed to analyze duration for Track ##{@track.id}: #{e.message}"
    # Continue without duration - not a critical failure
  end

  def handle_error(error)
    Rails.logger.error "Error in GenerateTrackJob for Track ##{@track.id}: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")

    @track.metadata["error"] = "Job error: #{error.message}"
    @track.status = :failed
    @track.save!
  end
end

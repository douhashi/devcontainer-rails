class GenerateMusicGenerationJob < ApplicationJob
  queue_as :default

  MAX_POLLING_ATTEMPTS = 30
  INITIAL_POLLING_INTERVAL = 5
  MAX_POLLING_INTERVAL = 30

  def perform(music_generation_id)
    @music_generation = MusicGeneration.find(music_generation_id)

    # Skip if already completed or failed
    return if @music_generation.status.in?([ "completed", "failed" ])

    @music_generation.processing!
    @kie_service = KieService.new

    generate_music
    poll_for_completion
    process_completed_generation
  rescue ActiveRecord::RecordNotFound => e
    # Re-raise RecordNotFound so it's not caught by generic error handler
    raise e
  rescue StandardError => e
    handle_error(e)
  end

  private

  def generate_music
    # Use generation_model from music_generation if set, otherwise use default
    model = @music_generation.generation_model.presence || KieService::DEFAULT_MODEL

    # Prepare request parameters
    request_params = {
      prompt: @music_generation.prompt,
      model: model,
      instrumental: true,
      wait_audio: false
    }

    # Save request parameters
    @music_generation.update!(request_params: request_params)

    # Call KieService to generate music
    task_id = @kie_service.generate_music(**request_params.symbolize_keys)

    # Update task_id
    @music_generation.update!(task_id: task_id)
  end

  def poll_for_completion
    attempts = 0

    loop do
      attempts += 1
      task_data = @kie_service.get_task_status(@music_generation.task_id)

      if task_data
        status = task_data["status"]
        normalized_status = status.to_s.downcase

        # Log the received status for debugging
        Rails.logger.debug "Received status: '#{status}' (normalized: '#{normalized_status}') on attempt #{attempts}"

        # Check for completion (SUCCESS or legacy completed/success)
        if normalized_status.in?([ "success", "completed" ])
          @task_data = task_data
          Rails.logger.info "Music generation completed with status: #{status}"
          break
        # Check for KIE API specific error statuses
        elsif normalized_status.in?([ "create_task_failed", "generate_audio_failed", "sensitive_word_error" ])
          error_message = task_data["error"] || "Generation failed: #{status}"
          Rails.logger.error "Music generation failed with status: #{status}, error: #{error_message}"
          raise Kie::Errors::TaskFailedError, error_message
        # Check for legacy failed status
        elsif normalized_status == "failed"
          error_message = task_data["error"] || "Generation failed"
          Rails.logger.error "Music generation failed with legacy status: #{status}, error: #{error_message}"
          raise Kie::Errors::TaskFailedError, error_message
        # Continue polling for pending and partial completion statuses
        elsif normalized_status.in?([ "pending", "first_success", "text_success" ])
          Rails.logger.debug "Continuing polling - status: #{status}"
        else
          Rails.logger.warn "Unknown status received from KIE API: '#{status}' - continuing polling"
        end
      else
        Rails.logger.warn "Received nil task_data from KIE API on attempt #{attempts}"
      end

      if attempts >= MAX_POLLING_ATTEMPTS
        Rails.logger.error "Polling timeout exceeded after #{attempts} attempts"
        raise Kie::Errors::TimeoutError, "Polling timeout exceeded"
      end

      # Exponential backoff with jitter
      interval = calculate_polling_interval(attempts)
      Rails.logger.debug "Polling attempt #{attempts}, waiting #{interval} seconds"
      sleep(interval)
    end
  end

  def calculate_polling_interval(attempt)
    # Exponential backoff: interval = min(initial * 2^(attempt-1), max_interval)
    # Add jitter to prevent thundering herd
    base_interval = [ INITIAL_POLLING_INTERVAL * (2 ** (attempt - 1)), MAX_POLLING_INTERVAL ].min
    jitter = rand * 0.3 * base_interval # Add up to 30% jitter
    (base_interval + jitter).round(2)
  end

  def process_completed_generation
    # Save the full API response
    @music_generation.update!(api_response: @task_data)

    # Extract all music data
    music_data_array = @kie_service.extract_all_music_data(@task_data)

    # Create tracks for each music variant
    music_data_array.each_with_index do |music_data, index|
      create_track_from_music_data(music_data, index)
    end

    # Mark generation as completed
    @music_generation.complete!
  rescue StandardError => e
    Rails.logger.error "Failed to complete music generation: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n") if e.backtrace
    raise
  end

  def create_track_from_music_data(music_data, variant_index)
    Rails.logger.debug "Creating track #{variant_index} with music_data: #{music_data.inspect}"

    track = @music_generation.tracks.create!(
      content: @music_generation.content,
      variant_index: variant_index,
      status: :processing,
      duration_sec: music_data[:duration]&.to_i,
      metadata: {
        "music_title" => music_data[:title],
        "music_tags" => music_data[:tags],
        "model_name" => music_data[:model_name],
        "generated_prompt" => music_data[:generated_prompt],
        "audio_id" => music_data[:audio_id],
        "task_id" => @music_generation.task_id
      }
    )

    Rails.logger.debug "Track #{track.id} created successfully"

    # Download and attach audio
    if music_data[:audio_url].present?
      download_and_attach_audio(track, music_data[:audio_url])
    end

    track.update!(status: :completed)
    Rails.logger.debug "Track #{track.id} marked as completed"
  rescue StandardError => e
    Rails.logger.error "Failed to create track from music data: #{e.message}"
    Rails.logger.error "Music data was: #{music_data.inspect}"
    track&.update!(status: :failed) if track&.persisted?
    raise
  end

  def download_and_attach_audio(track, audio_url)
    temp_file_path = Rails.root.join("tmp", "track_#{track.id}_#{Time.current.to_i}.mp3")

    @kie_service.download_audio(audio_url, temp_file_path)

    File.open(temp_file_path, "rb") do |file|
      track.audio = file
      track.save!
    end
  rescue StandardError => e
    Rails.logger.error "Failed to attach audio to track #{track.id}: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n") if e.backtrace
    raise
  ensure
    FileUtils.rm_f(temp_file_path) if temp_file_path && File.exist?(temp_file_path)
  end

  def handle_error(error)
    if @music_generation
      Rails.logger.error "Failed to generate music for MusicGeneration ##{@music_generation.id}: #{error.message}"
      Rails.logger.error error.backtrace.join("\n") if error.backtrace
      @music_generation.fail!
    else
      Rails.logger.error "Failed to generate music: #{error.message}"
      Rails.logger.error error.backtrace.join("\n") if error.backtrace
    end
  end
end

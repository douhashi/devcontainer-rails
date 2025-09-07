class GenerateAudioJob < ApplicationJob
  queue_as :default

  def perform(audio_id)
    @audio = Audio.find(audio_id)

    return if @audio.status.completed? || @audio.status.failed?

    if @audio.status.pending?
      start_generation
    elsif @audio.status.processing?
      check_generation_status
    end
  rescue StandardError => e
    handle_error(e)
  end

  private

  def start_generation
    Rails.logger.info "Starting audio generation for Audio ##{@audio.id}"

    begin
      # Select tracks using AudioCompositionService
      composition_service = AudioCompositionService.new(@audio.content)
      composition_result = composition_service.select_tracks

      # Update audio status and store metadata
      ActiveRecord::Base.transaction do
        @audio.status = :processing
        @audio.metadata = @audio.metadata.merge(composition_result.except(:selected_tracks))
        @audio.metadata["selected_track_ids"] = composition_result[:selected_tracks].map(&:id)
        @audio.save!
      end

      # Concatenate audio files
      concatenation_service = AudioConcatenationService.new(composition_result[:selected_tracks])
      output_path = generate_output_path

      concatenated_file_path = concatenation_service.concatenate(output_path)

      # Attach the concatenated audio file
      attach_audio_file(concatenated_file_path)

      # Mark as completed
      complete_generation

    rescue AudioCompositionService::InsufficientTracksError => e
      handle_composition_error(e)
    rescue AudioConcatenationService::ConcatenationError, AudioConcatenationService::MissingAudioFileError => e
      handle_concatenation_error(e)
    end
  end

  def check_generation_status
    # For this implementation, we don't have async processing status to check
    # This method is here for consistency with the job pattern, but since
    # our concatenation is synchronous, we don't need to implement polling
    Rails.logger.info "Audio ##{@audio.id} is already processing"
  end

  def attach_audio_file(file_path)
    File.open(file_path, "rb") do |file|
      @audio.audio = file
    end

    # Analyze duration if possible
    analyze_and_store_duration(file_path)

    @audio.save!

    # Clean up temporary file
    File.unlink(file_path) if File.exist?(file_path)

    Rails.logger.info "Successfully attached audio file for Audio ##{@audio.id}"
  end

  def analyze_and_store_duration(audio_path)
    analysis_service = AudioAnalysisService.new
    duration = analysis_service.analyze_duration(audio_path)
    @audio.metadata["duration"] = duration

    Rails.logger.info "Analyzed duration for Audio ##{@audio.id}: #{duration} seconds"
  rescue StandardError => e
    Rails.logger.error "Failed to analyze duration for Audio ##{@audio.id}: #{e.message}"
    # Continue without duration - not a critical failure
  end

  def complete_generation
    @audio.status = :completed
    @audio.save!

    Rails.logger.info "Successfully completed audio generation for Audio ##{@audio.id}"
  end

  def generate_output_path
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    Rails.root.join("tmp", "audio_#{@audio.id}_#{timestamp}.mp3")
  end

  def handle_composition_error(error)
    Rails.logger.error "Audio composition failed for Audio ##{@audio.id}: #{error.message}"

    @audio.metadata["error"] = "Track selection failed: #{error.message}"
    @audio.status = :failed
    @audio.save!
  end

  def handle_concatenation_error(error)
    Rails.logger.error "Audio concatenation failed for Audio ##{@audio.id}: #{error.message}"

    @audio.metadata["error"] = "Audio concatenation failed: #{error.message}"
    @audio.status = :failed
    @audio.save!
  end

  def handle_error(error)
    if @audio
      Rails.logger.error "Error in GenerateAudioJob for Audio ##{@audio.id}: #{error.message}"
      Rails.logger.error error.backtrace.join("\n")

      @audio.metadata["error"] = "Job error: #{error.message}"
      @audio.status = :failed
      @audio.save!
    else
      Rails.logger.error "Error in GenerateAudioJob: #{error.message}"
      raise error
    end
  end
end

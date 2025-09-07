# frozen_string_literal: true

require "net/http"
require "uri"
require "fileutils"
require "json"
require "logger"
require "time"

module Kie
  class MusicDownloader
    DEFAULT_OUTPUT_DIR = "./downloads"
    DEFAULT_MAX_RETRIES = 3

    attr_reader :output_dir, :max_retries

    def initialize(output_dir: DEFAULT_OUTPUT_DIR, max_retries: DEFAULT_MAX_RETRIES)
      @output_dir = output_dir
      @max_retries = max_retries
    end

    def sanitize_filename(filename)
      filename.gsub(%r{[/\\:*?"<>|]}, "_")
    end

    def download_file(url, filename, retries = 0)
      FileUtils.mkdir_p(output_dir)
      file_path = File.join(output_dir, filename)

      uri = URI(url)

      begin
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
          request = Net::HTTP::Get.new(uri)
          response = http.request(request)

          raise "HTTP Error: #{response.code}" unless response.code == "200"

          File.binwrite(file_path, response.body)
          return true
        end
      rescue StandardError
        return false unless retries < max_retries - 1

        sleep(2**retries)
        download_file(url, filename, retries + 1)
      end
    end

    def download_tracks(task_result, task_id)
      downloaded = 0
      # task_result is the data portion from the API response
      # Tracks are in response.sunoData array
      tracks = task_result.dig("response", "sunoData") || []

      tracks.each_with_index do |track, index|
        next unless track && track["audioUrl"]

        title = track["title"] || track["id"] || "untitled"
        sanitized_title = sanitize_filename(title)
        filename = "#{sanitized_title}_#{task_id}_#{index + 1}.mp3"

        downloaded += 1 if download_file(track["audioUrl"], filename)
      end

      downloaded
    end

    def save_metadata(task_result, task_id, prompt, model)
      FileUtils.mkdir_p(output_dir)
      metadata_file = File.join(output_dir, "metadata-#{task_id}.json")

      # task_result is the data portion from the API response
      # Tracks are in response.sunoData array
      tracks = task_result.dig("response", "sunoData") || []

      metadata = {
        "task_id" => task_id,
        "prompt" => prompt,
        "model" => model,
        "tracks" => tracks,
        "generated_at" => Time.now.iso8601
      }

      existing_metadata = (JSON.parse(File.read(metadata_file)) if File.exist?(metadata_file))

      if existing_metadata.is_a?(Array)
        existing_metadata << metadata
        File.write(metadata_file, JSON.pretty_generate(existing_metadata))
      elsif existing_metadata.is_a?(Hash)
        File.write(metadata_file, JSON.pretty_generate([ existing_metadata, metadata ]))
      else
        File.write(metadata_file, JSON.pretty_generate(metadata))
      end
    end

    def download_with_progress(task_result:, task_id:, prompt:, model:, logger: nil)
      logger ||= Logger.new(nil)

      # task_result is the data portion from the API response
      # Tracks are in response.sunoData array
      tracks = task_result.dig("response", "sunoData") || []

      # Log the structure for debugging
      logger.debug(
        "Task result structure: #{task_result.class} - " \
        "#{task_result.is_a?(Hash) ? task_result.keys : 'not a hash'}"
      )
      logger.debug("Tracks found: #{tracks.length}")

      total = tracks.count { |t| t && t["audioUrl"] }

      logger.info("Starting download of #{total} track(s) to #{output_dir}")

      downloaded = 0
      tracks.each_with_index do |track, index|
        next unless track && track["audioUrl"]

        title = track["title"] || track["id"] || "untitled"
        sanitized_title = sanitize_filename(title)
        filename = "#{sanitized_title}_#{task_id}_#{index + 1}.mp3"

        logger.info("Downloading track #{index + 1}/#{total}: #{title}")

        if download_file(track["audioUrl"], filename)
          downloaded += 1
          logger.info("Successfully downloaded: #{filename}")
        else
          logger.error("Failed to download: #{filename}")
        end
      end

      logger.info("Downloaded #{downloaded}/#{total} tracks")

      save_metadata(task_result, task_id, prompt, model)
      logger.info("Metadata saved to #{File.join(output_dir, "metadata-#{task_id}.json")}")

      {
        downloaded: downloaded,
        total: total,
        metadata_saved: true
      }
    end
  end
end

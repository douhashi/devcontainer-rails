# frozen_string_literal: true

require "kie/errors"
require "logger"

module Kie
  class TaskPoller
    DEFAULT_INTERVAL = 10
    DEFAULT_MAX_WAIT_TIME = 600

    attr_reader :client, :task_id, :interval, :max_wait_time, :logger

    def initialize(client:, task_id:, interval: DEFAULT_INTERVAL, max_wait_time: DEFAULT_MAX_WAIT_TIME, logger: nil)
      @client = client
      @task_id = task_id
      @interval = interval
      @max_wait_time = max_wait_time
      @logger = logger || Logger.new(nil)
    end

    def poll_until_complete
      start_time = Time.now

      logger.info("Polling task #{task_id} with interval #{interval}s, max wait time #{max_wait_time}s")

      loop do
        elapsed_time = Time.now - start_time

        if elapsed_time > max_wait_time
          raise TimeoutError, "Task #{task_id} did not complete within #{max_wait_time} seconds"
        end

        status_data = client.get_task_status(task_id)
        status = status_data["status"]
        progress = status_data["progress"]

        # Verbose mode: show API response structure
        logger.debug("API Response: #{status_data.to_json}") if logger.level == Logger::DEBUG

        logger.debug("Status: #{status}, Progress: #{progress}%")

        case status
        when "SUCCESS", "COMPLETED"
          logger.info("Task completed successfully")
          return status_data
        when "FAILED", "ERROR"
          error_message = status_data["error"] || "Task failed without error message"
          raise TaskFailedError, "Task #{task_id} failed: #{error_message}"
        when "PENDING", "PROCESSING", "IN_PROGRESS"
          logger.debug("Task still in progress, waiting #{interval} seconds...")
          sleep(interval)
        when "TEXT_SUCCESS"
          logger.info("Prompt processed successfully, generating music...")
          sleep(interval)
        when "FIRST_SUCCESS"
          logger.info("First track generated, continuing...")
          sleep(interval)
        else
          logger.warn("Unrecognized status: #{status}, continuing to poll...")
          sleep(interval)
        end
      end
    end
  end
end

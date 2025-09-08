namespace :solid_queue do
  desc "Display SolidQueue status and job counts"
  task status: :environment do
    puts "\n=== Queue Status ==="
    puts "Active Job Adapter: #{Rails.application.config.active_job.queue_adapter}"

    begin
      # Job counts by status
      if defined?(SolidQueue::Job)
        total_jobs = SolidQueue::Job.count
        pending_jobs = SolidQueue::Job.where(finished_at: nil).count
        finished_jobs = SolidQueue::Job.where.not(finished_at: nil).count
        failed_jobs = SolidQueue::FailedExecution.count if defined?(SolidQueue::FailedExecution)

        puts "Total Jobs: #{total_jobs}"
        puts "Pending Jobs: #{pending_jobs}"
        puts "Finished Jobs: #{finished_jobs}"
        puts "Failed Jobs: #{failed_jobs}"

        if pending_jobs > 0
          puts "\nPending Jobs by Queue:"
          SolidQueue::Job.where(finished_at: nil)
                          .group(:queue_name)
                          .count
                          .each { |queue, count| puts "  #{queue}: #{count}" }
        end
      else
        puts "SolidQueue::Job model not available"
      end
    rescue => e
      puts "Error retrieving job status: #{e.message}"
    end

    puts "\nQueue Configuration:"
    puts "Database: #{Rails.configuration.solid_queue&.connects_to || 'Not configured'}"
    puts "Config file: config/queue.yml"
  end

  desc "Display SolidQueue worker status"
  task workers: :environment do
    puts "\n=== Worker Status ==="

    begin
      if defined?(SolidQueue::Process)
        workers = SolidQueue::Process.where(kind: "Worker")
        puts "Active Workers: #{workers.count}"

        if workers.exists?
          puts "\nWorker Details:"
          workers.each do |worker|
            puts "  PID: #{worker.pid}, Last Heartbeat: #{worker.last_heartbeat_at&.strftime('%Y-%m-%d %H:%M:%S')}"
          end
        else
          puts "No active workers found"
        end
      else
        puts "SolidQueue::Process model not available"
      end
    rescue => e
      puts "Error retrieving worker status: #{e.message}"
    end

    puts "\nTo start workers manually:"
    puts "  bin/jobs --processes=1 --threads=3"
    puts "  bundle exec rake solid_queue:start"
  end

  desc "Display failed jobs"
  task failed: :environment do
    puts "\n=== Failed Jobs ==="

    begin
      if defined?(SolidQueue::FailedExecution)
        failed_executions = SolidQueue::FailedExecution.includes(:job).order(created_at: :desc).limit(10)

        if failed_executions.exists?
          puts "Recent Failed Jobs (last 10):"
          failed_executions.each do |failed_execution|
            job = failed_execution.job
            puts "  ID: #{job.id}, Class: #{job.class_name}, Queue: #{job.queue_name}"
            puts "    Failed at: #{failed_execution.created_at&.strftime('%Y-%m-%d %H:%M:%S')}"
            puts "    Error: #{failed_execution.error.to_s.truncate(100)}" if failed_execution.error
            puts ""
          end
        else
          puts "No failed jobs found"
        end
      else
        puts "SolidQueue::FailedExecution model not available"
      end
    rescue => e
      puts "Error retrieving failed jobs: #{e.message}"
    end
  end

  desc "Clear all jobs (development only)"
  task clear: :environment do
    if Rails.env.development?
      begin
        if defined?(SolidQueue::Job)
          count = SolidQueue::Job.count
          SolidQueue::Job.delete_all
          puts "Cleared #{count} jobs from queue"
        end
      rescue => e
        puts "Error clearing jobs: #{e.message}"
      end
    else
      puts "This task can only be run in development environment"
    end
  end

  desc "Process pending jobs (useful for troubleshooting)"
  task process_pending: :environment do
    begin
      if defined?(SolidQueue::Job)
        pending_jobs = SolidQueue::Job.where(finished_at: nil).limit(5)

        if pending_jobs.exists?
          puts "Found #{pending_jobs.count} pending jobs"
          pending_jobs.each do |job|
            puts "  Job #{job.id} (#{job.class_name}) in queue '#{job.queue_name}'"
          end

          puts "\nStart workers to process remaining jobs:"
          puts "  bin/dev (starts all services including workers)"
          puts "  bin/jobs (starts workers only)"
        else
          puts "No pending jobs to process"
        end
      end
    rescue => e
      puts "Error processing jobs: #{e.message}"
    end
  end
end

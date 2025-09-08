namespace :music_generation do
  desc "Requeue pending MusicGeneration records"
  task requeue_pending: :environment do
    puts "Finding pending MusicGeneration records..."

    pending_music_generations = MusicGeneration.pending
    count = pending_music_generations.count

    if count == 0
      puts "No pending MusicGeneration records found."
      exit 0
    end

    puts "Found #{count} pending MusicGeneration records:"
    pending_music_generations.each do |mg|
      puts "  - MusicGeneration ##{mg.id} (Content ##{mg.content_id})"
    end

    print "\nDo you want to requeue these records? (y/N): "
    answer = STDIN.gets.chomp.downcase

    unless answer == "y" || answer == "yes"
      puts "Aborted."
      exit 0
    end

    success_count = 0
    error_count = 0

    pending_music_generations.find_each do |music_generation|
      begin
        GenerateMusicJob.perform_later(music_generation.id)
        puts "✓ Requeued MusicGeneration ##{music_generation.id}"
        success_count += 1
      rescue => e
        puts "✗ Failed to requeue MusicGeneration ##{music_generation.id}: #{e.message}"
        error_count += 1
      end
    end

    puts "\n" + "="*50
    puts "Requeue completed:"
    puts "  Success: #{success_count}"
    puts "  Failed: #{error_count}"
  end

  desc "Clean up stale SolidQueue jobs"
  task cleanup_stale_jobs: :environment do
    puts "Cleaning up stale SolidQueue jobs..."

    # Delete jobs for non-existent GenerateTrackJob class
    stale_jobs = SolidQueue::Job.where("class_name = ?", "GenerateTrackJob")
    count = stale_jobs.count

    if count == 0
      puts "No stale GenerateTrackJob records found."
    else
      puts "Found #{count} stale GenerateTrackJob records."
      print "Do you want to delete these jobs? (y/N): "
      answer = STDIN.gets.chomp.downcase

      if answer == "y" || answer == "yes"
        stale_jobs.destroy_all
        puts "✓ Deleted #{count} stale jobs."
      else
        puts "Aborted."
      end
    end
  end

  desc "Show MusicGeneration status summary"
  task status: :environment do
    puts "\nMusicGeneration Status Summary:"
    puts "="*50

    total = MusicGeneration.count
    pending = MusicGeneration.pending.count
    processing = MusicGeneration.where(status: :processing).count
    completed = MusicGeneration.completed.count
    failed = MusicGeneration.where(status: :failed).count

    puts "Total: #{total}"
    puts "  Pending: #{pending}"
    puts "  Processing: #{processing}"
    puts "  Completed: #{completed}"
    puts "  Failed: #{failed}"

    if pending > 0
      puts "\nPending MusicGenerations:"
      MusicGeneration.pending.includes(:content).each do |mg|
        puts "  - ##{mg.id} (Content ##{mg.content_id}: #{mg.content.theme})"
      end
    end
  end
end

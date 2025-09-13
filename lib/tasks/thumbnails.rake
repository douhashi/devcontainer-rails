namespace :thumbnails do
  desc "Generate YouTube thumbnails for all eligible artworks"
  task generate_all: :environment do
    puts "=" * 60
    puts "YouTube Thumbnail Generation"
    puts "=" * 60

    total_count = Artwork.count
    eligible_count = 0
    processed_count = 0
    already_has_count = 0
    failed_count = 0
    failed_artworks = []

    puts "\nAnalyzing #{total_count} artworks..."
    puts "-" * 40

    Artwork.find_each.with_index do |artwork, index|
      print "\rProcessing: #{index + 1}/#{total_count}"

      begin
        if artwork.youtube_thumbnail_eligible?
          eligible_count += 1

          if artwork.has_youtube_thumbnail?
            already_has_count += 1
            puts "\n  [SKIP] Artwork ##{artwork.id}: Already has thumbnail"
          else
            puts "\n  [PROCESSING] Artwork ##{artwork.id}: Generating thumbnail..."
            DerivativeProcessingJob.perform_now(artwork)
            processed_count += 1
            puts "  [SUCCESS] Artwork ##{artwork.id}: Thumbnail generated"
          end
        end
      rescue => e
        failed_count += 1
        failed_artworks << { id: artwork.id, error: e.message }
        puts "\n  [ERROR] Artwork ##{artwork.id}: #{e.message}"
      end
    end

    puts "\n\n" + "=" * 60
    puts "Summary"
    puts "=" * 60
    puts "Total artworks:        #{total_count}"
    puts "Eligible (1920x1080):  #{eligible_count}"
    puts "Already has thumbnail: #{already_has_count}"
    puts "Newly generated:       #{processed_count}"
    puts "Failed:                #{failed_count}"

    if failed_artworks.any?
      puts "\n" + "-" * 40
      puts "Failed Artworks:"
      failed_artworks.each do |failure|
        puts "  - Artwork ##{failure[:id]}: #{failure[:error]}"
      end
    end

    puts "=" * 60
    puts "Completed!"
  end

  desc "Check YouTube thumbnail status for all artworks"
  task status: :environment do
    puts "=" * 60
    puts "YouTube Thumbnail Status Report"
    puts "=" * 60

    total_count = Artwork.count
    eligible_count = 0
    has_thumbnail_count = 0
    needs_generation_count = 0

    artworks_needing_generation = []

    Artwork.includes(:content).find_each do |artwork|
      if artwork.youtube_thumbnail_eligible?
        eligible_count += 1

        if artwork.has_youtube_thumbnail?
          has_thumbnail_count += 1
        else
          needs_generation_count += 1
          artworks_needing_generation << artwork
        end
      end
    end

    puts "\nTotal artworks:           #{total_count}"
    puts "Eligible (1920x1080):     #{eligible_count}"
    puts "Has YouTube thumbnail:    #{has_thumbnail_count}"
    puts "Needs thumbnail:          #{needs_generation_count}"

    if artworks_needing_generation.any?
      puts "\n" + "-" * 40
      puts "Artworks needing thumbnail generation:"
      artworks_needing_generation.each do |artwork|
        content_info = artwork.content ? "Content: #{artwork.content.theme}" : "No content"
        puts "  - Artwork ##{artwork.id} (#{content_info})"
      end

      puts "\n" + "-" * 40
      puts "To generate thumbnails for these artworks, run:"
      puts "  bin/rails thumbnails:generate_all"
    else
      puts "\n✓ All eligible artworks have YouTube thumbnails!"
    end

    puts "=" * 60
  end

  desc "Generate YouTube thumbnail for a specific artwork"
  task :generate_one, [ :artwork_id ] => :environment do |_task, args|
    artwork_id = args[:artwork_id]

    unless artwork_id
      puts "Error: Please provide an artwork ID"
      puts "Usage: bin/rails thumbnails:generate_one[ARTWORK_ID]"
      exit 1
    end

    artwork = Artwork.find_by(id: artwork_id)

    unless artwork
      puts "Error: Artwork with ID #{artwork_id} not found"
      exit 1
    end

    puts "=" * 60
    puts "YouTube Thumbnail Generation for Artwork ##{artwork.id}"
    puts "=" * 60

    if !artwork.youtube_thumbnail_eligible?
      puts "\nArtwork is not eligible for YouTube thumbnail generation."
      puts "Image dimensions: #{artwork.image.metadata['width']}x#{artwork.image.metadata['height']}"
      puts "Required dimensions: 1920x1080"
      exit 1
    end

    if artwork.has_youtube_thumbnail?
      puts "\nArtwork already has a YouTube thumbnail."
      puts "Thumbnail URL: #{artwork.youtube_thumbnail_url}"
      puts "\nTo regenerate, first remove the existing thumbnail."
      exit 0
    end

    puts "\nGenerating YouTube thumbnail..."

    begin
      DerivativeProcessingJob.perform_now(artwork)
      puts "✓ Thumbnail generated successfully!"
      puts "Thumbnail URL: #{artwork.reload.youtube_thumbnail_url}"
    rescue => e
      puts "✗ Failed to generate thumbnail: #{e.message}"
      puts "\nBacktrace:"
      puts e.backtrace.join("\n")
      exit 1
    end

    puts "=" * 60
    puts "Completed!"
  end

  desc "Remove YouTube thumbnails for all artworks (useful for testing)"
  task clear_all: :environment do
    print "Are you sure you want to remove all YouTube thumbnails? (y/N): "
    response = STDIN.gets.chomp.downcase

    unless response == "y" || response == "yes"
      puts "Cancelled."
      exit 0
    end

    puts "\nRemoving YouTube thumbnails..."

    removed_count = 0
    Artwork.find_each do |artwork|
      if artwork.has_youtube_thumbnail?
        attacher = artwork.image_attacher
        derivatives = attacher.derivatives.dup
        derivatives.delete(:youtube_thumbnail)
        attacher.set_derivatives(derivatives)
        artwork.save!
        removed_count += 1
        puts "  - Removed thumbnail for Artwork ##{artwork.id}"
      end
    end

    puts "\n✓ Removed #{removed_count} YouTube thumbnails"
  end
end

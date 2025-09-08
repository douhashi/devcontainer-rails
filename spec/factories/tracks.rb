FactoryBot.define do
  factory :track do
    association :content
    status { :pending }
    metadata { {} }

    trait :pending do
      status { :pending }
    end

    trait :processing do
      status { :processing }
    end

    trait :completed do
      status { :completed }
      duration_sec { 180 }
      metadata do
        {
          "kie_response" => {
            "url" => "https://example.com/track.mp3",
            "duration" => 180,
            "format" => "mp3"
          }
        }
      end
    end

    trait :with_audio do
      after(:build) do |track|
        # Create a temp file instead of StringIO for proper MIME type handling
        require 'tempfile'
        temp_file = Tempfile.new([ 'test_track', '.mp3' ])
        temp_file.write("fake audio content")
        temp_file.rewind

        # Define methods needed for Shrine
        temp_file.define_singleton_method(:original_filename) { "test_track.mp3" }
        temp_file.define_singleton_method(:content_type) { "audio/mpeg" }

        track.audio = temp_file
        temp_file.close
      end
    end

    trait :failed do
      status { :failed }
      metadata do
        {
          "error" => "Generation failed",
          "error_code" => "KIE_001"
        }
      end
    end

    trait :with_short_duration do
      duration_sec { 90 }
    end

    trait :with_long_duration do
      duration_sec { 300 }
    end

    trait :with_very_long_duration do
      duration_sec { 3665 } # Over 1 hour
    end
  end
end

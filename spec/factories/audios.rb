FactoryBot.define do
  factory :audio do
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
    end

    trait :failed do
      status { :failed }
    end

    trait :with_metadata do
      metadata { { selected_tracks: [ 1, 2, 3 ], total_duration_min: 180, tracks_used: 3 } }
    end

    trait :with_audio do
      after(:build) do |audio|
        # Create a StringIO to simulate audio file
        require 'stringio'
        audio_file = StringIO.new("fake audio content")

        # Add required methods for Shrine
        audio_file.define_singleton_method(:original_filename) { "test_audio.mp3" }
        audio_file.define_singleton_method(:content_type) { "audio/mpeg" }

        audio.audio = audio_file
      end
    end
  end
end

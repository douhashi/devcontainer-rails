FactoryBot.define do
  factory :music_generation do
    association :content
    task_id { SecureRandom.hex(16) }
    status { :pending }
    prompt { "Create a lo-fi hip hop beat with a mellow mood" }
    generation_model { "V4_5PLUS" }
    api_response { nil }

    trait :processing do
      status { :processing }
    end

    trait :completed do
      status { :completed }
      api_response do
        {
          "data" => {
            "sunoData" => [
              {
                "id" => "song_id_1",
                "title" => "Song 1",
                "audio_url" => "https://example.com/song1.mp3",
                "duration" => 120
              },
              {
                "id" => "song_id_2",
                "title" => "Song 2",
                "audio_url" => "https://example.com/song2.mp3",
                "duration" => 125
              }
            ]
          }
        }
      end
    end

    trait :failed do
      status { :failed }
    end
  end
end

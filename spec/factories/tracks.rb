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
      duration { 180 }
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
      duration { 90 }
    end

    trait :with_long_duration do
      duration { 300 }
    end

    trait :with_very_long_duration do
      duration { 3665 } # Over 1 hour
    end
  end
end

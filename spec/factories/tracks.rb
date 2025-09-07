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
  end
end

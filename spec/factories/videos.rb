FactoryBot.define do
  factory :video do
    association :content
    status { :pending }
    resolution { "1920x1080" }
    file_size { 50_000_000 }
    duration_seconds { 180 }

    trait :pending do
      status { :pending }
    end

    trait :processing do
      status { :processing }
    end

    trait :completed do
      status { :completed }
      resolution { "1920x1080" }
      file_size { 50_000_000 }
      duration_seconds { 180 }
    end

    trait :failed do
      status { :failed }
      error_message { "ffmpeg command failed" }
    end
  end
end

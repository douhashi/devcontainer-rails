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
  end
end

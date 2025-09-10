FactoryBot.define do
  factory :youtube_credential do
    association :user
    access_token { "ya29.test_access_token_#{SecureRandom.hex(20)}" }
    refresh_token { "1//test_refresh_token_#{SecureRandom.hex(20)}" }
    expires_at { 1.hour.from_now }
    scope { "youtube.readonly yt-analytics.readonly" }

    trait :expired do
      expires_at { 1.hour.ago }
    end

    trait :needs_refresh do
      expires_at { 3.minutes.from_now }
    end
  end
end

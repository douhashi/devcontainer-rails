FactoryBot.define do
  factory :youtube_metadata do
    association :content
    title { "Sample YouTube Title" }
    description_en { "This is a sample English description for YouTube video." }
    description_ja { "これはYouTube動画のサンプル日本語説明です。" }
    hashtags { "#lofi #bgm #music" }
    status { :draft }

    trait :ready do
      status { :ready }
    end

    trait :published do
      status { :published }
    end

    trait :with_long_title do
      title { "A" * 100 }
    end

    trait :with_long_descriptions do
      description_en { "A" * 5000 }
      description_ja { "あ" * 5000 }
    end

    trait :with_long_hashtags do
      hashtags { "#" + "a" * 497 }
    end
  end
end

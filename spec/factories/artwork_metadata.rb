FactoryBot.define do
  factory :artwork_metadata do
    association :content
    positive_prompt { "beautiful landscape, digital art, vibrant colors, highly detailed, professional artwork" }
    negative_prompt { "blurry, low quality, distorted, pixelated, amateur, watermark" }
  end
end

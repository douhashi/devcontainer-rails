FactoryBot.define do
  factory :artwork do
    association :content

    # デフォルトでFHD画像を設定（正常系テスト用）
    after(:build) do |artwork|
      if artwork.image.blank?
        fixture_path = Rails.root.join('spec', 'fixtures', 'files', 'images', 'fhd_placeholder.jpg')

        uploaded_file = Rack::Test::UploadedFile.new(
          fixture_path,
          'image/jpeg'
        )
        artwork.image = uploaded_file
      end
    end
  end
end

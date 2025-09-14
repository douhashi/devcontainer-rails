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

    trait :with_fhd_image do
      after(:build) do |artwork|
        fixture_path = Rails.root.join('spec', 'fixtures', 'files', 'images', 'fhd_placeholder.jpg')
        uploaded_file = Rack::Test::UploadedFile.new(fixture_path, 'image/jpeg')
        artwork.image = uploaded_file
      end
    end

    trait :with_hd_image do
      after(:build) do |artwork|
        fixture_path = Rails.root.join('spec', 'fixtures', 'files', 'images', 'hd_placeholder.jpg')
        uploaded_file = Rack::Test::UploadedFile.new(fixture_path, 'image/jpeg')
        artwork.image = uploaded_file
      end
    end


    trait :with_youtube_thumbnail do
      thumbnail_generation_status { :completed }

      after(:create) do |artwork|
        # 実際のサムネイルderivativeを作成
        begin
          # 一時的なサムネイル画像を作成
          temp_thumbnail = Tempfile.new([ 'thumbnail', '.jpg' ])

          # FHD画像からサムネイルを生成
          service = ThumbnailGenerationService.new
          artwork.image.open do |input_file|
            service.generate(
              input_path: input_file.path,
              output_path: temp_thumbnail.path
            )
          end

          # derivativeとして保存
          File.open(temp_thumbnail.path) do |file|
            attacher = artwork.image_attacher
            derivatives = { youtube_thumbnail: attacher.upload(file, :store) }
            attacher.set_derivatives(derivatives)
            artwork.save!
          end
        rescue => e
          Rails.logger.warn "Failed to create test YouTube thumbnail: #{e.message}"
        ensure
          temp_thumbnail&.close
          temp_thumbnail&.unlink
        end
      end
    end
  end
end

FactoryBot.define do
  factory :artwork do
    association :content

    trait :with_image do
      after(:build) do |artwork|
        # Use TestImageHelper to create a proper test image
        tempfile = Tempfile.new([ 'test', '.jpg' ])

        # Include TestImageHelper module methods
        helper = Object.new.extend(TestImageHelper)
        helper.create_test_image_with_size(tempfile.path, 800, 600)

        uploaded_file = Rack::Test::UploadedFile.new(
          tempfile,
          'image/jpeg',
          original_filename: 'valid_image.jpg'
        )
        artwork.image = uploaded_file
      end
    end

    after(:build) do |artwork|
      # Use TestImageHelper to create a proper test image
      tempfile = Tempfile.new([ 'test', '.jpg' ])

      # Include TestImageHelper module methods
      helper = Object.new.extend(TestImageHelper)
      helper.create_test_image_with_size(tempfile.path, 800, 600)

      uploaded_file = Rack::Test::UploadedFile.new(
        tempfile,
        'image/jpeg',
        original_filename: 'valid_image.jpg'
      )
      artwork.image = uploaded_file
    end
  end
end

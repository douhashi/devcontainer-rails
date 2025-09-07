require 'rails_helper'

RSpec.describe Artwork, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:content) }
  end

  describe 'validations' do
    let(:content) { create(:content) }

    describe 'image presence' do
      it 'is invalid without an image' do
        artwork = Artwork.new(content: content, image: nil)
        expect(artwork).not_to be_valid
        expect(artwork.errors[:image]).to include("can't be blank")
      end
    end

    describe 'image format validation' do
      it 'accepts JPEG files' do
        artwork = Artwork.new(content: content)
        artwork.image = image_file('valid_image.jpg', 'image/jpeg')
        expect(artwork).to be_valid
      end

      it 'accepts PNG files' do
        artwork = Artwork.new(content: content)
        artwork.image = image_file('valid_image.png', 'image/png')
        expect(artwork).to be_valid
      end

      it 'accepts GIF files' do
        artwork = Artwork.new(content: content)
        artwork.image = image_file('valid_image.gif', 'image/gif')
        expect(artwork).to be_valid
      end

      it 'rejects non-image files' do
        artwork = Artwork.new(content: content)
        artwork.image = text_file('invalid_file.txt', 'text/plain')
        expect(artwork).not_to be_valid
        expect(artwork.errors[:image]).to include(/type must be one of/)
      end
    end

    describe 'image size validation' do
      it 'rejects files over 10MB' do
        artwork = Artwork.new(content: content)
        artwork.image = large_image_file('large_image.jpg', 'image/jpeg')
        expect(artwork).not_to be_valid
        expect(artwork.errors[:image]).to include(/size must not be greater than/)
      end
    end
  end

  describe 'content relationship' do
    let(:content) { create(:content) }
    let!(:artwork) { create(:artwork, content: content) }

    it 'belongs to content' do
      expect(artwork.content).to eq(content)
    end

    it 'is destroyed when content is destroyed' do
      expect { content.destroy }.to change(Artwork, :count).by(-1)
    end
  end

  private

  def image_file(filename, mime_type)
    file = Rack::Test::UploadedFile.new(
      StringIO.new(minimal_jpeg_data),
      mime_type,
      original_filename: filename
    )
    file
  end

  def text_file(filename, mime_type)
    file = Rack::Test::UploadedFile.new(
      StringIO.new('This is text content'),
      mime_type,
      original_filename: filename
    )
    file
  end

  def large_image_file(filename, mime_type)
    large_data = minimal_jpeg_data * (11.megabytes / minimal_jpeg_data.length + 1)
    file = Rack::Test::UploadedFile.new(
      StringIO.new(large_data),
      mime_type,
      original_filename: filename
    )
    file
  end

  # Minimal valid JPEG data (1x1 pixel)
  def minimal_jpeg_data
    [
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
      0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
      0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
      0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
      0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
      0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
      0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
      0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x11, 0x08, 0x00, 0x01,
      0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
      0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0xFF, 0xC4,
      0x00, 0x14, 0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xDA, 0x00, 0x0C,
      0x03, 0x01, 0x00, 0x02, 0x11, 0x03, 0x11, 0x00, 0x3F, 0x00, 0x80, 0xFF, 0xD9
    ].pack('C*')
  end
end

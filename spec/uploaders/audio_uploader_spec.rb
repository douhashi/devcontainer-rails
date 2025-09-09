require 'rails_helper'

RSpec.describe AudioUploader do
  describe 'validations' do
    let(:track) { create(:track) }
    let(:mp3_file) {
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/files/sample.mp3'),
        'audio/mpeg'
      )
    }
    let(:wav_file) {
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/files/sample.wav'),
        'audio/wav'
      )
    }
    let(:txt_file) {
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/files/sample.txt'),
        'text/plain'
      )
    }
    let(:large_file) {
      Tempfile.new([ 'large', '.mp3' ]).tap do |file|
        # Write valid MP3 header first
        file.write("\xFF\xFB\x90\x00")
        # Then fill the rest with data
        file.write('x' * (101.megabytes - 4))
        file.rewind
      end
    }

    after do
      large_file.close if large_file && !large_file.closed?
      large_file.unlink if large_file
    end

    describe 'file format validation' do
      it 'accepts MP3 files' do
        track.audio = mp3_file
        expect(track).to be_valid
      end

      it 'accepts WAV files' do
        track.audio = wav_file
        expect(track).to be_valid
      end

      it 'rejects non-audio files' do
        track.audio = txt_file
        expect(track).not_to be_valid
        expect(track.errors[:audio].first).to match(/type must be one of/)
      end
    end

    describe 'file size validation' do
      it 'accepts files up to 100MB' do
        track.audio = mp3_file
        expect(track).to be_valid
      end

      it 'rejects files larger than 100MB' do
        track.audio = large_file
        expect(track).not_to be_valid
        expect(track.errors[:audio].first).to match(/size must not be greater than/)
      end
    end
  end

  describe 'metadata extraction' do
    let(:track) { create(:track) }
    let(:mp3_file) {
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/files/sample.mp3'),
        'audio/mpeg'
      )
    }

    it 'extracts and stores file metadata' do
      track.audio = mp3_file
      track.save!

      expect(track.audio_data).to be_present
      expect(track.audio.metadata['filename']).to eq('sample.mp3')
      expect(track.audio.metadata['size']).to be_a(Integer)
      expect(track.audio.metadata['mime_type']).to eq('audio/mpeg')
    end
  end
end

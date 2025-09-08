require 'rails_helper'

RSpec.describe AudioCompositionService do
  let(:content) { create(:content, duration_min: 10) }
  let!(:completed_track1) { create(:track, content: content, status: :completed, duration_sec: 180) }
  let!(:completed_track2) { create(:track, content: content, status: :completed, duration_sec: 150) }
  let!(:completed_track3) { create(:track, content: content, status: :completed, duration_sec: 200) }
  let!(:completed_track4) { create(:track, content: content, status: :completed, duration_sec: 120) }
  let!(:completed_track5) { create(:track, content: content, status: :completed, duration_sec: 190) }
  let!(:pending_track) { create(:track, content: content, status: :pending) }
  let!(:failed_track) { create(:track, content: content, status: :failed) }

  let(:service) { described_class.new(content) }

  describe 'initialization' do
    it 'sets content' do
      expect(service.content).to eq(content)
    end
  end

  describe '#select_tracks' do
    context 'with sufficient completed tracks' do
      it 'selects tracks for the specified duration' do
        result = service.select_tracks

        expect(result).to be_a(Hash)
        expect(result[:selected_tracks]).to be_an(Array)
        expect(result[:total_duration]).to be >= content.duration_min * 60
        expect(result[:tracks_used]).to be > 0
      end

      it 'only selects completed tracks' do
        result = service.select_tracks
        selected_track_ids = result[:selected_tracks].map { |t| t.id }

        completed_track_ids = [ completed_track1.id, completed_track2.id, completed_track3.id, completed_track4.id, completed_track5.id ]
        expect(selected_track_ids).to all(be_in(completed_track_ids))
      end

      it 'does not select duplicate tracks' do
        result = service.select_tracks
        selected_track_ids = result[:selected_tracks].map { |t| t.id }

        expect(selected_track_ids.uniq).to eq(selected_track_ids)
      end

      it 'meets minimum duration requirement' do
        result = service.select_tracks
        target_duration = content.duration_min * 60

        expect(result[:total_duration]).to be >= target_duration
      end
    end

    context 'with insufficient completed tracks' do
      let(:content_with_few_tracks) { create(:content, duration_min: 60) }
      let!(:single_track) { create(:track, content: content_with_few_tracks, status: :completed, duration_sec: 120) }
      let(:service_with_few_tracks) { described_class.new(content_with_few_tracks) }

      it 'raises error when not enough tracks' do
        expect {
          service_with_few_tracks.select_tracks
        }.to raise_error(AudioCompositionService::InsufficientTracksError)
      end
    end

    context 'with no completed tracks' do
      let(:content_no_tracks) { create(:content, duration_min: 10) }
      let(:service_no_tracks) { described_class.new(content_no_tracks) }

      it 'raises error when no completed tracks' do
        expect {
          service_no_tracks.select_tracks
        }.to raise_error(AudioCompositionService::InsufficientTracksError)
      end
    end
  end

  describe '#available_tracks' do
    it 'returns only completed tracks' do
      available = service.send(:available_tracks)

      expect(available.count).to eq(5)
      expect(available).to all(have_attributes(status: 'completed'))
    end

    it 'excludes pending, processing, and failed tracks' do
      available = service.send(:available_tracks)

      expect(available).not_to include(pending_track)
      expect(available).not_to include(failed_track)
    end
  end

  describe 'logging' do
    it 'logs selection results' do
      expect(Rails.logger).to receive(:info).with(/Selected \d+ tracks/)

      service.select_tracks
    end
  end
end

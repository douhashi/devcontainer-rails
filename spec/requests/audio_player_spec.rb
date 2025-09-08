# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Audio Player in Track List", type: :request do
  let(:content) { create(:content) }

  describe "GET /tracks" do
    context "with completed tracks having audio" do
      let!(:track_with_audio) { create(:track, :completed, content: content) }
      let!(:track_without_audio) { create(:track, :completed, content: content) }

      it "displays audio player for tracks with audio" do
        # Mock audio for all Track instances
        allow_any_instance_of(Track).to receive(:audio).and_return(double(present?: true, url: "https://example.com/test.mp3"))

        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('data-controller="audio-player"')
        expect(response.body).to include('data-audio-player-target="player"')
      end

      it "does not display audio player for tracks without audio" do
        # Mock audio absent for all Track instances
        allow_any_instance_of(Track).to receive(:audio).and_return(double(present?: false))

        get tracks_path

        expect(response).to have_http_status(:success)
        # Should not have any audio player
        expect(response.body).not_to include('data-controller="audio-player"')
      end
    end

    context "with failed tracks" do
      let!(:failed_track) { create(:track, :failed, content: content) }

      it "does not display audio player" do
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('data-controller="audio-player"')
      end
    end

    context "with pending tracks" do
      let!(:pending_track) { create(:track, :pending, content: content) }

      it "does not display audio player" do
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('data-controller="audio-player"')
      end
    end

    context "with processing tracks" do
      let!(:processing_track) { create(:track, :processing, content: content) }

      it "does not display audio player" do
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('data-controller="audio-player"')
      end
    end
  end
end

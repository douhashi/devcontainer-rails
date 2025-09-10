# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Audio Player in Track List", type: :request do
  let(:user) { create(:user) }

  before do
    # Use post to sign in via Devise's form
    post user_session_path, params: { user: { email: user.email, password: 'password' } }
  end

  let(:content) { create(:content) }

  describe "GET /tracks" do
    context "audio player functionality" do
      let!(:track_with_audio) { create(:track, :completed, content: content) }
      let!(:track_without_audio) { create(:track, :completed, content: content) }

      it "displays audio player interface correctly based on track audio status" do
        # Test with audio present
        allow_any_instance_of(Track).to receive(:audio).and_return(double(present?: true, url: "https://example.com/test.mp3"))
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('プレイヤー')
        # PlayButton is now used instead of AudioPlayer
        expect(response.body).to include('button')
        expect(response.body).to include('play-button')

        # Test with audio absent
        allow_any_instance_of(Track).to receive(:audio).and_return(double(present?: false))
        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('音声なし')
        expect(response.body).not_to include('play-button')
      end
    end

    context "track status-based audio player display" do
      it "does not show audio player for non-completed tracks and shows appropriate status" do
        # Test failed, pending, and processing tracks
        failed_track = create(:track, :failed, content: content)
        pending_track = create(:track, :pending, content: content)
        processing_track = create(:track, :processing, content: content)

        get tracks_path

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('play-button')
        expect(response.body).to include('処理中...')
      end
    end
  end
end

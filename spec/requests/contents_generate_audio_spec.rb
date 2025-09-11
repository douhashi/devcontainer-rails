require 'rails_helper'

RSpec.describe "Contents generate_audio", type: :request do
  let(:user) { create(:user) }

  before do
    # Use post to sign in via Devise's form
    post user_session_path, params: { user: { email: user.email, password: 'password' } }
  end

  let(:content) { create(:content, duration_min: 10) }
  let!(:completed_track1) { create(:track, content: content, status: :completed, duration_sec: 180) }
  let!(:completed_track2) { create(:track, content: content, status: :completed, duration_sec: 150) }

  describe "POST /contents/:id/generate_audio" do
    context "with valid prerequisites" do
      it "creates audio and queues generation job" do
        expect {
          post generate_audio_content_path(content)
        }.to change { content.reload.audio }.from(nil)
         .and change { enqueued_jobs.size }.by(1)

        expect(response).to redirect_to(content_path(content))
        expect(flash[:notice]).to include("Audio generation has been started")
        expect(content.audio).to be_present
        expect(content.audio.pending?).to be true
      end

      it "queues GenerateAudioJob" do
        expect {
          post generate_audio_content_path(content)
        }.to have_enqueued_job(GenerateAudioJob)

        audio = content.reload.audio
        expect(GenerateAudioJob).to have_been_enqueued.with(audio.id)
      end

      context "without artwork" do
        it "still creates audio and queues generation job" do
          # Artworkなしでも音源生成が可能
          expect {
            post generate_audio_content_path(content)
          }.to change { content.reload.audio }.from(nil)
           .and change { enqueued_jobs.size }.by(1)

          expect(response).to redirect_to(content_path(content))
          expect(flash[:notice]).to include("Audio generation has been started")
        end
      end
    end

    context "when audio already completed" do
      let!(:completed_audio) { create(:audio, content: content, status: :completed) }

      it "returns error message" do
        post generate_audio_content_path(content)

        expect(response).to redirect_to(content_path(content))
        expect(flash[:alert]).to include("Audio has already been generated")
      end

      it "does not queue new job" do
        expect {
          post generate_audio_content_path(content)
        }.not_to have_enqueued_job(GenerateAudioJob)
      end
    end

    context "when prerequisites not met" do
      it "handles various prerequisite failures with appropriate HTTP responses" do
        # Without completed tracks
        content_no_tracks = create(:content, duration_min: 10)

        post generate_audio_content_path(content_no_tracks)
        expect(response).to redirect_to(content_path(content_no_tracks))
        expect(flash[:alert]).to include("No completed tracks available")

        # With insufficient completed tracks
        content_few_tracks = create(:content, duration_min: 10)
        create(:track, content: content_few_tracks, status: :completed, duration_sec: 180)

        post generate_audio_content_path(content_few_tracks)
        expect(response).to redirect_to(content_path(content_few_tracks))
        expect(flash[:alert]).to include("At least 2 completed tracks")
      end

      it "allows generation without artwork" do
        # アートワークなしでも2個以上の完了したトラックがあれば生成可能
        content_no_artwork = create(:content, duration_min: 10)
        create_list(:track, 2, content: content_no_artwork, status: :completed, duration_sec: 180)

        expect {
          post generate_audio_content_path(content_no_artwork)
        }.to change { content_no_artwork.reload.audio }.from(nil)

        expect(response).to redirect_to(content_path(content_no_artwork))
        expect(flash[:notice]).to include("Audio generation has been started")
      end
    end

    context "when content not found" do
      it "returns 404 or redirects with error" do
        post "/contents/99999/generate_audio"
        expect(response.status).to be_in([ 404, 302 ])
      end
    end

    context "when job queueing fails" do
      before do
        allow(GenerateAudioJob).to receive(:perform_later).and_raise(StandardError, "Queue error")
      end

      it "handles error gracefully" do
        post generate_audio_content_path(content)

        expect(response).to redirect_to(content_path(content))
        expect(flash[:alert]).to include("Failed to start audio generation")
      end
    end
  end
end

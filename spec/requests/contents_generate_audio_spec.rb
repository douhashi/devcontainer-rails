require 'rails_helper'

RSpec.describe "Contents generate_audio", type: :request do
  let(:content) { create(:content, duration: 10) }
  let!(:artwork) { create(:artwork, content: content) }
  let!(:completed_track1) { create(:track, content: content, status: :completed, duration: 180) }
  let!(:completed_track2) { create(:track, content: content, status: :completed, duration: 150) }

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
      context "without artwork" do
        let(:content_no_artwork) { create(:content, duration: 10) }
        let!(:track1) { create(:track, content: content_no_artwork, status: :completed, duration: 180) }
        let!(:track2) { create(:track, content: content_no_artwork, status: :completed, duration: 150) }

        it "returns error message" do
          post generate_audio_content_path(content_no_artwork)

          expect(response).to redirect_to(content_path(content_no_artwork))
          expect(flash[:alert]).to include("Artwork must be configured")
        end

        it "does not create audio record" do
          expect {
            post generate_audio_content_path(content_no_artwork)
          }.not_to change { content_no_artwork.reload.audio }
        end
      end

      context "without completed tracks" do
        let(:content_no_tracks) { create(:content, duration: 10) }
        let!(:artwork) { create(:artwork, content: content_no_tracks) }

        it "returns error message" do
          post generate_audio_content_path(content_no_tracks)

          expect(response).to redirect_to(content_path(content_no_tracks))
          expect(flash[:alert]).to include("No completed tracks available")
        end
      end

      context "with insufficient completed tracks" do
        let(:content_few_tracks) { create(:content, duration: 10) }
        let!(:artwork) { create(:artwork, content: content_few_tracks) }
        let!(:single_track) { create(:track, content: content_few_tracks, status: :completed, duration: 180) }

        it "returns error message" do
          post generate_audio_content_path(content_few_tracks)

          expect(response).to redirect_to(content_path(content_few_tracks))
          expect(flash[:alert]).to include("At least 2 completed tracks")
        end
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

  describe "private methods" do
    let(:controller) { ContentsController.new }

    before do
      controller.instance_variable_set(:@content, content)
    end

    describe "#audio_generation_prerequisites_met?" do
      context "with all prerequisites" do
        it "returns true" do
          expect(controller.send(:audio_generation_prerequisites_met?)).to be true
        end
      end

      context "without artwork" do
        before do
          artwork.destroy!
          content.reload
          controller.instance_variable_set(:@content, content)
        end

        it "returns false" do
          expect(controller.send(:audio_generation_prerequisites_met?)).to be false
        end
      end

      context "without completed tracks" do
        before do
          content.tracks.update_all(status: :pending)
        end

        it "returns false" do
          expect(controller.send(:audio_generation_prerequisites_met?)).to be false
        end
      end

      context "with insufficient tracks" do
        before { completed_track2.destroy! }

        it "returns false" do
          expect(controller.send(:audio_generation_prerequisites_met?)).to be false
        end
      end
    end

    describe "#audio_generation_error_message" do
      context "without artwork" do
        before do
          artwork.destroy!
          content.reload
          controller.instance_variable_set(:@content, content)
        end

        it "includes artwork error" do
          message = controller.send(:audio_generation_error_message)
          expect(message).to include("Artwork must be configured")
        end
      end

      context "without completed tracks" do
        before do
          content.tracks.update_all(status: :pending)
          artwork.destroy!
          content.reload
          controller.instance_variable_set(:@content, content)
        end

        it "includes multiple errors" do
          message = controller.send(:audio_generation_error_message)
          expect(message).to include("No completed tracks available")
          expect(message).to include("Artwork must be configured")
        end
      end
    end
  end
end

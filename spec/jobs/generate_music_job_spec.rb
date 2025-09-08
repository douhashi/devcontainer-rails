require "rails_helper"

RSpec.describe GenerateMusicJob, type: :job do
  let(:content) { create(:content, audio_prompt: "Create a relaxing lo-fi beat") }
  let(:music_generation) { create(:music_generation, content: content, task_id: "test-task-123", prompt: "Create a relaxing lo-fi beat", generation_model: "V3_5") }
  let(:kie_service) { instance_double(KieService) }

  before do
    allow(KieService).to receive(:new).and_return(kie_service)
  end

  describe "#perform" do
    context "when music generation is pending" do
      it "starts generation and transitions to processing" do
        allow(kie_service).to receive(:generate_music).and_return("new-task-123")

        expect(GenerateMusicJob).to receive(:set).with(wait: 30.seconds).and_return(
          double(perform_later: nil)
        )

        described_class.new.perform(music_generation.id)

        music_generation.reload
        expect(music_generation.status.processing?).to be true
        expect(music_generation.task_id).to eq("new-task-123")
        expect(music_generation.metadata["task_id"]).to eq("new-task-123")
        expect(music_generation.metadata["polling_attempts"]).to eq(0)
      end
    end

    context "when music generation is processing" do
      before do
        music_generation.processing!
        music_generation.metadata["polling_attempts"] = 5
        music_generation.save!
      end

      context "when task is still processing" do
        it "increments polling attempts and reschedules" do
          allow(kie_service).to receive(:get_task_status).and_return(
            { "status" => "processing" }
          )

          expect(GenerateMusicJob).to receive(:set).with(wait: 30.seconds).and_return(
            double(perform_later: nil)
          )

          described_class.new.perform(music_generation.id)

          music_generation.reload
          expect(music_generation.metadata["polling_attempts"]).to eq(6)
          expect(music_generation.status.processing?).to be true
        end
      end

      context "when task is completed" do
        let(:suno_data) do
          [
            {
              "audioUrl" => "https://example.com/audio1.mp3",
              "title" => "Track 1",
              "tags" => "lo-fi, chill",
              "duration" => 180,
              "modelName" => "V3_5",
              "prompt" => "Create a relaxing lo-fi beat",
              "audioId" => "audio-1"
            },
            {
              "audioUrl" => "https://example.com/audio2.mp3",
              "title" => "Track 2",
              "tags" => "lo-fi, ambient",
              "duration" => 185,
              "modelName" => "V3_5",
              "prompt" => "Create a relaxing lo-fi beat",
              "audioId" => "audio-2"
            }
          ]
        end

        let(:task_response) do
          {
            "status" => "completed",
            "response" => {
              "sunoData" => suno_data
            }
          }
        end

        it "creates multiple tracks with variant indexes" do
          allow(kie_service).to receive(:get_task_status).and_return(task_response)
          allow(kie_service).to receive(:extract_all_music_data).and_return(
            suno_data.map do |data|
              {
                audio_url: data["audioUrl"],
                title: data["title"],
                tags: data["tags"],
                duration: data["duration"],
                model_name: data["modelName"],
                generated_prompt: data["prompt"],
                audio_id: data["audioId"]
              }
            end
          )
          # Mock audio download
          allow(kie_service).to receive(:download_audio) do |url, path|
            # Create a dummy audio file at the path
            FileUtils.cp(Rails.root.join("spec/fixtures/files/sample.mp3"), path)
            path
          end

          expect {
            described_class.new.perform(music_generation.id)
          }.to change { music_generation.tracks.count }.by(2)

          music_generation.reload
          expect(music_generation.status.completed?).to be true

          tracks = music_generation.tracks.order(:variant_index)
          expect(tracks[0].variant_index).to eq(0)
          expect(tracks[0].metadata["music_title"]).to eq("Track 1")
          expect(tracks[0].metadata["audio_id"]).to eq("audio-1")
          expect(tracks[0].duration).to eq(180)

          expect(tracks[1].variant_index).to eq(1)
          expect(tracks[1].metadata["music_title"]).to eq("Track 2")
          expect(tracks[1].metadata["audio_id"]).to eq("audio-2")
          expect(tracks[1].duration).to eq(185)
        end
      end

      context "when task fails" do
        it "updates status to failed" do
          allow(kie_service).to receive(:get_task_status).and_return(
            { "status" => "failed", "error" => "Generation failed" }
          )

          described_class.new.perform(music_generation.id)

          music_generation.reload
          expect(music_generation.status.failed?).to be true
          expect(music_generation.metadata["error"]).to eq("Generation failed")
        end
      end

      context "when polling limit is exceeded" do
        before do
          music_generation.metadata["polling_attempts"] = 20
          music_generation.save!
        end

        it "fails the generation with timeout error" do
          described_class.new.perform(music_generation.id)

          music_generation.reload
          expect(music_generation.status.failed?).to be true
          expect(music_generation.metadata["error"]).to include("タイムアウト")
        end
      end
    end

    context "when music generation is already completed" do
      before { music_generation.complete! }

      it "returns without processing" do
        expect(kie_service).not_to receive(:generate_music)
        expect(kie_service).not_to receive(:get_task_status)

        described_class.new.perform(music_generation.id)
      end
    end

    context "when music generation is already failed" do
      before { music_generation.fail! }

      it "returns without processing" do
        expect(kie_service).not_to receive(:generate_music)
        expect(kie_service).not_to receive(:get_task_status)

        described_class.new.perform(music_generation.id)
      end
    end

    context "error handling" do
      it "handles exceptions and marks generation as failed" do
        allow(kie_service).to receive(:generate_music).and_raise(StandardError, "API Error")

        described_class.new.perform(music_generation.id)

        music_generation.reload
        expect(music_generation.status.failed?).to be true
        expect(music_generation.metadata["error"]).to include("API Error")
      end
    end
  end
end

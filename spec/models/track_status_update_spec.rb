require "rails_helper"

RSpec.describe Track, type: :model do
  describe "status update and broadcasting" do
    let(:content) { create(:content) }
    let(:track) { create(:track, content: content, status: :pending) }

    before do
      # Mock ApplicationController.render to avoid turbo_frame_tag error
      allow(ApplicationController).to receive(:render).and_return("<html>mock track</html>")
    end

    describe "status transitions with broadcast" do
      context "when status changes from pending to processing" do
        it "broadcasts status update with correct channel" do
          # Enable broadcasting for this test
          allow(Rails.env).to receive(:test?).and_return(false)

          expect(ActionCable.server).to receive(:broadcast).with(
            "content_#{content.id}_tracks",
            {
              action: "replace",
              target: "track_#{track.id}",
              html: "<html>mock track</html>"
            }
          )

          track.update!(status: :processing)
        end

        it "calls broadcast_status_update_if_changed callback" do
          expect(track).to receive(:broadcast_status_update_if_changed).and_call_original
          track.update!(status: :processing)
        end

        it "detects status change with saved_change_to_status?" do
          track.update!(status: :processing)
          expect(track.saved_change_to_status?).to be true
        end
      end

      context "when status changes from processing to completed" do
        before do
          track.update!(status: :processing)
        end

        it "broadcasts both status update and completion notification" do
          allow(Rails.env).to receive(:test?).and_return(false)

          expect(ActionCable.server).to receive(:broadcast).with(
            "content_#{content.id}_tracks",
            hash_including(action: "replace", target: "track_#{track.id}")
          )

          expect(ActionCable.server).to receive(:broadcast).with(
            "content_#{content.id}_notifications",
            hash_including(action: "append", target: "notifications")
          )

          track.update!(status: :completed)
        end
      end

      context "when status changes from processing to failed" do
        before do
          track.update!(status: :processing)
        end

        it "broadcasts both status update and completion notification" do
          allow(Rails.env).to receive(:test?).and_return(false)

          expect(ActionCable.server).to receive(:broadcast).with(
            "content_#{content.id}_tracks",
            hash_including(action: "replace", target: "track_#{track.id}")
          )

          expect(ActionCable.server).to receive(:broadcast).with(
            "content_#{content.id}_notifications",
            hash_including(action: "append", target: "notifications")
          )

          track.update!(status: :failed)
        end
      end

      context "when non-status attributes change" do
        it "does not broadcast" do
          expect(ActionCable.server).not_to receive(:broadcast)
          track.update!(duration_sec: 120)
        end
      end
    end

    describe "broadcast channel names" do
      it "uses correct channel name for track updates" do
        expected_channel = "content_#{content.id}_tracks"

        allow(Rails.env).to receive(:test?).and_return(false)
        expect(ActionCable.server).to receive(:broadcast).with(
          expected_channel,
          hash_including(action: "replace")
        )

        track.update!(status: :processing)
      end

      it "uses correct channel name for notifications" do
        track.update!(status: :processing)
        expected_track_channel = "content_#{content.id}_tracks"
        expected_notification_channel = "content_#{content.id}_notifications"

        allow(Rails.env).to receive(:test?).and_return(false)

        # Expect both broadcasts: status update and completion notification
        expect(ActionCable.server).to receive(:broadcast).with(
          expected_track_channel,
          hash_including(action: "replace")
        )

        expect(ActionCable.server).to receive(:broadcast).with(
          expected_notification_channel,
          hash_including(action: "append")
        )

        track.update!(status: :completed)
      end
    end
  end
end

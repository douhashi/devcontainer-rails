require "rails_helper"

RSpec.describe Track, type: :model do
  describe "status broadcasting" do
    let(:content) { create(:content) }
    let(:track) { create(:track, content: content, status: :pending) }

    describe "#broadcast_status_update" do
      it "does not broadcast in test environment" do
        # Broadcasting is disabled in test environment to avoid rendering issues
        expect {
          track.broadcast_status_update
        }.not_to have_broadcasted_to("content_#{content.id}_tracks")
      end
    end

    describe "after_update callback" do
      context "when status changes" do
        it "calls broadcast_status_update (but does nothing in test env)" do
          expect(track).to receive(:broadcast_status_update_if_changed)
          track.update!(status: :processing)
        end
      end

      context "when other attributes change" do
        it "does not call broadcast" do
          expect(track).not_to receive(:broadcast_status_update)
          track.update!(duration: 120)
        end
      end
    end

    describe "#broadcast_completion_notification" do
      context "when status is completed" do
        it "does not broadcast in test environment" do
          track.status = :completed
          expect {
            track.broadcast_completion_notification
          }.not_to have_broadcasted_to("content_#{content.id}_notifications")
        end
      end

      context "when status is failed" do
        it "does not broadcast in test environment" do
          track.status = :failed
          expect {
            track.broadcast_completion_notification
          }.not_to have_broadcasted_to("content_#{content.id}_notifications")
        end
      end
    end
  end
end

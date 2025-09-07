require "rails_helper"

RSpec.describe Track, type: :model do
  describe "status broadcasting" do
    let(:content) { create(:content) }
    let(:track) { create(:track, content: content, status: :pending) }

    describe "#broadcast_status_update" do
      it "broadcasts status update to content channel" do
        # Stub turbo_frame_tag helper for partial rendering
        allow(ApplicationController).to receive(:render).and_return("<html>mock</html>")

        expect {
          track.broadcast_status_update
        }.to have_broadcasted_to("content_#{content.id}_tracks").with { |data|
          expect(data[:action]).to eq("replace")
          expect(data[:target]).to eq("track_#{track.id}")
          expect(data[:html]).to be_present
        }
      end
    end

    describe "after_update callback" do
      context "when status changes" do
        it "broadcasts the update" do
          expect(track).to receive(:broadcast_status_update)
          track.update!(status: :processing)
        end
      end

      context "when other attributes change" do
        it "does not broadcast" do
          expect(track).not_to receive(:broadcast_status_update)
          track.update!(duration: 120)
        end
      end
    end

    describe "#broadcast_completion_notification" do
      before do
        # Stub ApplicationController.render for partial rendering
        allow(ApplicationController).to receive(:render).and_return("<html>mock toast</html>")
      end

      context "when status is completed" do
        it "broadcasts success toast notification" do
          track.status = :completed
          expect {
            track.broadcast_completion_notification
          }.to have_broadcasted_to("content_#{content.id}_notifications").with { |data|
            expect(data[:action]).to eq("append")
            expect(data[:target]).to eq("notifications")
            expect(data[:html]).to be_present
          }
        end
      end

      context "when status is failed" do
        it "broadcasts error toast notification" do
          track.status = :failed
          expect {
            track.broadcast_completion_notification
          }.to have_broadcasted_to("content_#{content.id}_notifications").with { |data|
            expect(data[:action]).to eq("append")
            expect(data[:target]).to eq("notifications")
            expect(data[:html]).to be_present
          }
        end
      end
    end
  end
end

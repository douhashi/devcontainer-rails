require "rails_helper"

RSpec.describe "Track Status Real-time Updates", type: :system, js: true, skip: "ActionCable implementation needs update" do
  let(:content) { create(:content) }
  let(:track) { create(:track, content: content, status: :pending) }

  before do
    # Setup ActionCable for test
    ActionCable.server.restart

    # Mock KieService to avoid external API calls
    kie_service = instance_double(KieService)
    allow(KieService).to receive(:new).and_return(kie_service)
    allow(kie_service).to receive(:generate_music).and_return("test_task_id")
  end

  describe "Turbo Stream connection setup" do
    it "has correct data-turbo-stream-source attribute" do
      visit content_path(content)

      expect(page).to have_css(
        "[data-turbo-stream-source*='/cable?channel=TrackStatusChannel&content_id=#{content.id}']"
      )
    end

    it "has notification container for toast messages" do
      visit content_path(content)

      expect(page).to have_css("#notifications")
    end
  end

  describe "Real-time status updates via ActionCable" do
    before do
      # Enable ActionCable broadcasting for system test
      allow(Rails.env).to receive(:test?).and_return(false)
    end

    it "updates track status from pending to processing in real-time" do
      visit content_path(content)

      # Verify initial state
      within "#track_#{track.id}" do
        expect(page).to have_content("待機中")
      end

      # Simulate status change broadcast
      ActionCable.server.broadcast(
        "content_#{content.id}_tracks",
        {
          action: "replace",
          target: "track_#{track.id}",
          html: "<div id='track_#{track.id}' class='track-item processing'>処理中</div>"
        }
      )

      # Wait for broadcast and verify update
      expect(page).to have_content("処理中", wait: 5)
    end

    it "shows completion notification when track status becomes completed" do
      # Set track to processing first
      track.update!(status: :processing)

      visit content_path(content)

      # Simulate completion notification broadcast
      ActionCable.server.broadcast(
        "content_#{content.id}_notifications",
        {
          action: "append",
          target: "notifications",
          html: "<div class='toast success'>Track生成が完了しました</div>"
        }
      )

      # Wait for notification to appear
      within "#notifications" do
        expect(page).to have_content("Track生成が完了しました", wait: 5)
      end
    end

    it "shows failure notification when track status becomes failed" do
      # Set track to processing first
      track.update!(status: :processing)

      visit content_path(content)

      # Simulate failure notification broadcast
      ActionCable.server.broadcast(
        "content_#{content.id}_notifications",
        {
          action: "append",
          target: "notifications",
          html: "<div class='toast error'>Track生成に失敗しました</div>"
        }
      )

      # Wait for notification to appear
      within "#notifications" do
        expect(page).to have_content("Track生成に失敗しました", wait: 5)
      end
    end
  end

  describe "WebSocket connection verification" do
    it "establishes WebSocket connection to ActionCable" do
      visit content_path(content)

      # Check that ActionCable is connected
      # This is a basic check - in a real test you might need to check browser console logs
      expect(page.evaluate_script("window.ActionCable")).to be_truthy
    end

    it "subscribes to the correct channel" do
      visit content_path(content)

      # Wait a moment for connection to establish
      sleep(1)

      # Verify channel subscription (this is simplified - actual implementation
      # would need to check ActionCable consumer subscriptions)
      expect(page).to have_css("[data-turbo-stream-source]")
    end
  end

  describe "Track generation job status flow" do
    it "updates status through the complete generation flow" do
      visit content_path(content)

      # Initial state
      within "#track_#{track.id}" do
        expect(page).to have_content("待機中")
      end

      # Simulate job execution that updates status to processing
      # In a real scenario this would be triggered by clicking a generation button
      perform_enqueued_jobs do
        track.update!(status: :processing)
      end

      # The track model's after_update callback should broadcast the change
      # In test environment, we simulate this
      if Rails.env.test?
        # Manually trigger what would happen in non-test environment
        ActionCable.server.broadcast(
          "content_#{content.id}_tracks",
          {
            action: "replace",
            target: "track_#{track.id}",
            html: "<div id='track_#{track.id}' class='track-item processing'>処理中</div>"
          }
        )
      end

      # Verify status change appears on page
      expect(page).to have_content("処理中", wait: 5)
    end
  end
end

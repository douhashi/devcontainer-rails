# frozen_string_literal: true

require "rails_helper"

RSpec.describe "AudioUsedTracksTable", type: :system, js: true, playwright: true do
  let(:content) { create(:content, theme: "テストテーマ", duration_min: 10) }

  describe "Content detail page with used tracks table" do
    context "with tracks that have audio files" do
      let(:track_with_audio) { create(:track, content: content, status: :completed, duration_sec: 180) }
      let(:track_without_audio) { create(:track, content: content, status: :completed, duration_sec: 200) }

      let!(:audio) do
        # Mock audio file for first track
        track_with_audio.audio = Rack::Test::UploadedFile.new(
          Rails.root.join("spec/fixtures/files/audio/sample.mp3"),
          "audio/mpeg"
        )
        track_with_audio.save!

        create(:audio,
               content: content,
               status: :completed,
               metadata: { "selected_track_ids" => [ track_with_audio.id, track_without_audio.id ] })
      end

      it "displays player icon for tracks with audio" do
        visit content_path(content)

        # Ensure the table with used tracks is visible
        expect(page).to have_content("使用Track一覧")

        # Find the specific used tracks table section
        used_tracks_section = find("h3", text: "使用Track一覧").ancestor("div.mt-4")

        within(used_tracks_section) do
          within("table tbody") do
            rows = all("tr")

            # First row (track with audio) should have player button
            within(rows[0]) do
              # Check that the player column has a button (not a dash)
              within(all("td")[3]) do  # Player column is 4th column (0-indexed)
                expect(page).to have_css("[data-controller='inline-audio-player']")
                expect(page).not_to have_css("span.text-gray-500", text: "-")
              end
            end

            # Second row (track without audio) should have dash
            within(rows[1]) do
              within(all("td")[3]) do  # Player column
                expect(page).to have_css("span.text-gray-500", text: "-")
                expect(page).not_to have_css("button")
              end
            end
          end
        end
      end
    end
  end
end

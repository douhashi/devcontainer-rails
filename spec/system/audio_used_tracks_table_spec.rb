# frozen_string_literal: true

require "rails_helper"

RSpec.describe "AudioUsedTracksTable", type: :system, js: true do
  include_context "ログイン済み"

  let(:content) { create(:content, theme: "テストテーマ", duration_min: 10) }

  describe "Content detail page with used tracks table" do
    context "when audio with selected tracks exists" do
      let(:tracks) do
        [
          create(:track, content: content, status: :completed, duration_sec: 180),
          create(:track, content: content, status: :completed, duration_sec: 200),
          create(:track, content: content, status: :completed, duration_sec: 150)
        ]
      end

      let!(:audio) do
        create(:audio,
               content: content,
               status: :completed,
               metadata: { "selected_track_ids" => tracks.map(&:id) })
      end

      it "displays used tracks table with correct information" do
        visit content_path(content)

        # Check that the audio section exists
        expect(page).to have_css(".bg-gray-800", text: "音源生成")

        # Check that used tracks table is displayed
        expect(page).to have_content("使用Track一覧")

        # Check table headers - uppercase in actual output
        within("table") do
          expect(page).to have_content("TRACK NO.")
          expect(page).to have_content("曲の長さ")
          expect(page).to have_content("プレイヤー")
          expect(page).to have_content("アクション")
        end

        # Check track numbers
        expect(page).to have_content("#1")
        expect(page).to have_content("#2")
        expect(page).to have_content("#3")

        # Check track durations
        expect(page).to have_content("3:00")  # 180 seconds
        expect(page).to have_content("3:20")  # 200 seconds
        expect(page).to have_content("2:30")  # 150 seconds
      end

      it "displays table with scrollable area for many tracks" do
        # Create more tracks to test scrollability
        additional_tracks = create_list(:track, 10, content: content, status: :completed, duration_sec: 180)
        all_track_ids = (tracks + additional_tracks).map(&:id)
        audio.update!(metadata: { "selected_track_ids" => all_track_ids })

        visit content_path(content)

        # Check that the scrollable container exists
        expect(page).to have_css(".max-h-96.overflow-y-auto")

        # Check that all track numbers are present
        (1..13).each do |i|
          expect(page).to have_content("##{i}")
        end
      end
    end

    context "when audio exists but is not completed" do
      let!(:audio) do
        create(:audio,
               content: content,
               status: :processing,
               metadata: { "selected_track_ids" => [ 1, 2, 3 ] })
      end

      it "does not display used tracks table" do
        visit content_path(content)

        expect(page).to have_css(".bg-gray-800", text: "音源生成")
        expect(page).not_to have_content("使用Track一覧")
      end
    end

    context "when audio is completed but has no selected tracks" do
      let!(:audio) do
        create(:audio,
               content: content,
               status: :completed,
               metadata: { "selected_track_ids" => [] })
      end

      it "does not display used tracks table" do
        visit content_path(content)

        expect(page).to have_css(".bg-gray-800", text: "音源生成")
        expect(page).not_to have_content("使用Track一覧")
      end
    end

    context "when no audio exists" do
      it "does not display used tracks table" do
        visit content_path(content)

        expect(page).to have_css(".bg-gray-800", text: "音源生成")
        expect(page).not_to have_content("使用Track一覧")
      end
    end

    context "with tracks that have audio files" do
      let(:track_with_audio) { create(:track, content: content, status: :completed, duration_sec: 180) }
      let(:track_without_audio) { create(:track, content: content, status: :completed, duration_sec: 200) }

      let!(:audio) do
        # Mock audio file for first track
        track_with_audio.audio = Rack::Test::UploadedFile.new(
          Rails.root.join("spec/fixtures/files/sample.mp3"),
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

        within("table tbody") do
          rows = all("tr")

          # First row should have player icon
          within(rows[0]) do
            expect(page).to have_css("svg.text-blue-400")
          end

          # Second row should have dash
          within(rows[1]) do
            expect(page).to have_css("span.text-gray-500", text: "-")
          end
        end
      end
    end

    context "with deleted tracks in selected_track_ids" do
      let(:existing_tracks) { create_list(:track, 2, content: content, status: :completed, duration_sec: 180) }
      let(:deleted_track) { create(:track, content: content, status: :completed, duration_sec: 200) }

      let!(:audio) do
        all_track_ids = existing_tracks.map(&:id) + [ deleted_track.id ]
        audio = create(:audio,
                      content: content,
                      status: :completed,
                      metadata: { "selected_track_ids" => all_track_ids })

        # Delete the track after creating audio
        deleted_track.destroy!

        audio
      end

      it "displays only existing tracks without errors" do
        visit content_path(content)

        expect(page).to have_content("使用Track一覧")

        # Should only show 2 tracks (existing ones)
        expect(page).to have_content("#1")
        expect(page).to have_content("#2")
        expect(page).not_to have_content("#3")
      end
    end
  end
end

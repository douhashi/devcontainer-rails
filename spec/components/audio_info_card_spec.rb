require "rails_helper"

RSpec.describe AudioInfoCard::Component, type: :component do
  subject(:component) { described_class.new(audio:) }

  describe "#render" do
    context "when audio exists" do
      let(:audio) do
        create(:audio,
               status: "completed",
               metadata: { duration: 180 },
               created_at: Time.zone.parse("2025-01-15 10:00:00"),
               updated_at: Time.zone.parse("2025-01-15 10:05:00"))
      end

      it "renders audio information card" do
        render_inline(component)

        expect(page).to have_css(".audio-info-card")
        expect(page).to have_text("音源情報")
      end

      it "does not display status badge" do
        render_inline(component)

        expect(page).not_to have_text("完了")
        expect(page).not_to have_css(".status-badge")
      end

      it "displays formatted duration" do
        render_inline(component)

        expect(page).to have_text("3:00")
      end

      it "displays processing time" do
        render_inline(component)

        expect(page).to have_text("作成時間:")
        expect(page).to have_text("5分0秒")
      end

      it "does not display delete icon button in info card" do
        render_inline(component)

        # AudioInfoCard内に削除ボタンは表示されない
        expect(page).not_to have_css("[data-turbo-method='delete']")
      end

      context "when audio has used tracks" do
        let(:content) { create(:content) }
        let(:track1) { create(:track, content: content, duration_sec: 180) }
        let(:track2) { create(:track, content: content, duration_sec: 240) }
        let(:track3) { create(:track, content: content, duration_sec: 300) }
        let(:audio) do
          create(:audio,
                 content: content,
                 status: "completed",
                 metadata: {
                   duration: 720,
                   selected_track_ids: [ track1.id, track2.id, track3.id ]
                 })
        end

        before do
          track1
          track2
          track3
        end

        it "displays total duration of used tracks" do
          render_inline(component)

          # 180 + 240 + 300 = 720秒 = 12分
          expect(page).to have_text("12:00")
        end
      end
    end

    context "when audio is nil" do
      let(:audio) { nil }

      it "renders empty state message" do
        render_inline(component)

        expect(page).to have_css(".empty-state")
        expect(page).to have_text("音源未生成")
        expect(page).to have_text("音源を生成するには「音源生成」ボタンをクリックしてください")
      end

      it "does not display delete button" do
        render_inline(component)

        expect(page).not_to have_css("[data-turbo-method='delete']")
      end
    end
  end

  describe "#formatted_duration" do
    let(:audio) { build(:audio, metadata:) }

    context "when audio has no used tracks" do
      context "when duration exists in metadata" do
        let(:metadata) { { duration: 125 } }

        it "returns formatted time from metadata" do
          expect(component.formatted_duration).to eq("2:05")
        end
      end

      context "when duration is nil" do
        let(:metadata) { {} }

        it "returns placeholder" do
          expect(component.formatted_duration).to eq("-")
        end
      end

      context "when duration is zero" do
        let(:metadata) { { duration: 0 } }

        it "returns 0:00" do
          expect(component.formatted_duration).to eq("0:00")
        end
      end

      context "when duration is over an hour" do
        let(:metadata) { { duration: 3665 } }

        it "returns formatted time with hours" do
          expect(component.formatted_duration).to eq("61:05")
        end
      end
    end

    context "when audio has used tracks" do
      let(:content) { create(:content) }
      let(:track1) { create(:track, content: content, duration_sec: 180) }
      let(:track2) { create(:track, content: content, duration_sec: 240) }
      let(:audio) do
        create(:audio,
               content: content,
               metadata: {
                 duration: 420,
                 selected_track_ids: [ track1.id, track2.id ]
               })
      end

      before do
        track1
        track2
      end

      it "returns total duration of used tracks" do
        expect(component.formatted_duration).to eq("7:00")
      end
    end

    context "when used tracks have nil duration_sec" do
      let(:content) { create(:content) }
      let(:track1) { create(:track, content: content, duration_sec: 180) }
      let(:track2) { create(:track, content: content, duration_sec: nil) }
      let(:audio) do
        create(:audio,
               content: content,
               metadata: {
                 duration: 180,
                 selected_track_ids: [ track1.id, track2.id ]
               })
      end

      before do
        track1
        track2
      end

      it "skips tracks with nil duration" do
        expect(component.formatted_duration).to eq("3:00")
      end
    end
  end

  describe "#formatted_date" do
    let(:audio) { build(:audio, created_at: Time.zone.parse("2025-01-15 14:30:00")) }

    it "returns Japanese formatted date" do
      expect(component.formatted_date(audio.created_at)).to eq("2025年01月15日 14:30")
    end
  end

  describe "#status_symbol" do
    let(:audio) { build(:audio, status:) }

    context "when status is pending" do
      let(:status) { "pending" }

      it "returns pending symbol" do
        expect(component.status_symbol).to eq(:pending)
      end
    end

    context "when status is processing" do
      let(:status) { "processing" }

      it "returns processing symbol" do
        expect(component.status_symbol).to eq(:processing)
      end
    end

    context "when status is completed" do
      let(:status) { "completed" }

      it "returns completed symbol" do
        expect(component.status_symbol).to eq(:completed)
      end
    end

    context "when status is failed" do
      let(:status) { "failed" }

      it "returns failed symbol" do
        expect(component.status_symbol).to eq(:failed)
      end
    end
  end
end

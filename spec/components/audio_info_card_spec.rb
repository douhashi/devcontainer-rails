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

      it "displays status badge" do
        render_inline(component)

        expect(page).to have_text("完了")
      end

      it "displays formatted duration" do
        render_inline(component)

        expect(page).to have_text("3:00")
      end

      it "displays formatted created_at" do
        render_inline(component)

        expect(page).to have_text("2025年01月15日 10:00")
      end

      it "displays formatted updated_at" do
        render_inline(component)

        expect(page).to have_text("2025年01月15日 10:05")
      end

      it "displays delete button" do
        render_inline(component)

        expect(page).to have_css("[data-turbo-method='delete']")
        expect(page).to have_text("削除")
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

    context "when duration exists in metadata" do
      let(:metadata) { { duration: 125 } }

      it "returns formatted time" do
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

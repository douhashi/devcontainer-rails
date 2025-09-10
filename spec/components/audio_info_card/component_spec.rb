require "rails_helper"

RSpec.describe AudioInfoCard::Component, type: :component do
  let(:content) { create(:content) }
  let(:audio) { create(:audio, content: content) }
  let(:component) { described_class.new(audio: audio) }

  describe "#formatted_duration" do
    context "when audio has duration in metadata" do
      before do
        audio.metadata = { "duration" => 180 }
      end

      it "returns formatted time string" do
        expect(component.formatted_duration).to eq("3:00")
      end
    end

    context "when duration is less than a minute" do
      before do
        audio.metadata = { "duration" => 45 }
      end

      it "returns formatted time with leading zero for seconds" do
        expect(component.formatted_duration).to eq("0:45")
      end
    end

    context "when duration is zero" do
      before do
        audio.metadata = { "duration" => 0 }
      end

      it "returns 0:00" do
        expect(component.formatted_duration).to eq("0:00")
      end
    end

    context "when metadata is nil" do
      before do
        audio.metadata = nil
      end

      it "returns dash" do
        expect(component.formatted_duration).to eq("-")
      end
    end

    context "when duration is not present in metadata" do
      before do
        audio.metadata = { "other_key" => "value" }
      end

      it "returns dash" do
        expect(component.formatted_duration).to eq("-")
      end
    end
  end

  describe "#processing_time" do
    context "when audio has different created_at and updated_at" do
      before do
        audio.created_at = Time.zone.parse("2025-01-10 10:00:00")
        audio.updated_at = Time.zone.parse("2025-01-10 10:02:30")
      end

      it "returns the difference in seconds" do
        expect(component.processing_time).to eq("2分30秒")
      end
    end

    context "when processing time is less than a minute" do
      before do
        audio.created_at = Time.zone.parse("2025-01-10 10:00:00")
        audio.updated_at = Time.zone.parse("2025-01-10 10:00:45")
      end

      it "returns only seconds" do
        expect(component.processing_time).to eq("45秒")
      end
    end

    context "when processing time is exactly one minute" do
      before do
        audio.created_at = Time.zone.parse("2025-01-10 10:00:00")
        audio.updated_at = Time.zone.parse("2025-01-10 10:01:00")
      end

      it "returns 1分0秒" do
        expect(component.processing_time).to eq("1分0秒")
      end
    end

    context "when created_at and updated_at are the same" do
      before do
        time = Time.zone.parse("2025-01-10 10:00:00")
        audio.created_at = time
        audio.updated_at = time
      end

      it "returns 0秒" do
        expect(component.processing_time).to eq("0秒")
      end
    end

    context "when audio is nil" do
      let(:component) { described_class.new(audio: nil) }

      it "returns dash" do
        expect(component.processing_time).to eq("-")
      end
    end

    context "when audio is not persisted" do
      let(:audio) { build(:audio, content: content) }

      it "returns dash" do
        expect(component.processing_time).to eq("-")
      end
    end
  end

  describe "#formatted_date" do
    it "formats datetime in Japanese" do
      datetime = Time.zone.parse("2025-01-10 15:30:00")
      expect(component.formatted_date(datetime)).to eq("2025年01月10日 15:30")
    end

    it "returns dash for nil datetime" do
      expect(component.formatted_date(nil)).to eq("-")
    end
  end

  describe "#status_symbol" do
    context "when audio is nil" do
      let(:component) { described_class.new(audio: nil) }

      it "returns :not_started" do
        expect(component.status_symbol).to eq(:not_started)
      end
    end

    context "when audio status is pending" do
      before { audio.status = "pending" }

      it "returns :pending" do
        expect(component.status_symbol).to eq(:pending)
      end
    end

    context "when audio status is processing" do
      before { audio.status = "processing" }

      it "returns :processing" do
        expect(component.status_symbol).to eq(:processing)
      end
    end

    context "when audio status is completed" do
      before { audio.status = "completed" }

      it "returns :completed" do
        expect(component.status_symbol).to eq(:completed)
      end
    end

    context "when audio status is failed" do
      before { audio.status = "failed" }

      it "returns :failed" do
        expect(component.status_symbol).to eq(:failed)
      end
    end

    context "when audio status is unknown" do
      before { audio.status = "unknown" }

      it "returns :not_started" do
        expect(component.status_symbol).to eq(:not_started)
      end
    end
  end

  describe "#delete_path" do
    context "when audio exists" do
      it "returns the delete path" do
        # ViewComponentのrender_inlineを使ってコンポーネントをレンダリング
        rendered = render_inline(component)
        expect(component.delete_path).to eq("/contents/#{content.id}/audio.#{audio.id}")
      end
    end

    context "when audio is nil" do
      let(:component) { described_class.new(audio: nil) }

      it "returns nil" do
        expect(component.delete_path).to be_nil
      end
    end
  end
end

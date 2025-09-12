require "rails_helper"

RSpec.describe MusicGenerationStatusSummary::Component, type: :component do
  let(:content) { create(:content, duration_min: 10) }
  let(:component) { described_class.new(content_record: content) }

  describe "#status_counts" do
    context "MusicGenerationが存在する場合" do
      before do
        create_list(:music_generation, 2, content: content, status: :pending)
        create_list(:music_generation, 3, content: content, status: :processing)
        create_list(:music_generation, 4, content: content, status: :completed)
        create_list(:music_generation, 1, content: content, status: :failed)
      end

      it "各ステータスの件数を正しく集計する" do
        expect(component.status_counts).to eq(
          "pending" => 2,
          "processing" => 3,
          "completed" => 4,
          "failed" => 1
        )
      end
    end

    context "MusicGenerationが存在しない場合" do
      it "空のハッシュを返す" do
        expect(component.status_counts).to eq({})
      end
    end

    context "特定のステータスが0件の場合" do
      before do
        create_list(:music_generation, 2, content: content, status: :completed)
      end

      it "存在するステータスのみを返す" do
        expect(component.status_counts).to eq("completed" => 2)
      end
    end
  end

  describe "#pending_count" do
    context "pendingステータスが存在する場合" do
      before do
        create_list(:music_generation, 3, content: content, status: :pending)
      end

      it "pendingの件数を返す" do
        expect(component.pending_count).to eq(3)
      end
    end

    context "pendingステータスが存在しない場合" do
      it "0を返す" do
        expect(component.pending_count).to eq(0)
      end
    end
  end

  describe "#processing_count" do
    context "processingステータスが存在する場合" do
      before do
        create_list(:music_generation, 2, content: content, status: :processing)
      end

      it "processingの件数を返す" do
        expect(component.processing_count).to eq(2)
      end
    end

    context "processingステータスが存在しない場合" do
      it "0を返す" do
        expect(component.processing_count).to eq(0)
      end
    end
  end

  describe "#completed_count" do
    context "completedステータスが存在する場合" do
      before do
        create_list(:music_generation, 5, content: content, status: :completed)
      end

      it "completedの件数を返す" do
        expect(component.completed_count).to eq(5)
      end
    end

    context "completedステータスが存在しない場合" do
      it "0を返す" do
        expect(component.completed_count).to eq(0)
      end
    end
  end

  describe "#failed_count" do
    context "failedステータスが存在する場合" do
      before do
        create_list(:music_generation, 1, content: content, status: :failed)
      end

      it "failedの件数を返す" do
        expect(component.failed_count).to eq(1)
      end
    end

    context "failedステータスが存在しない場合" do
      it "0を返す" do
        expect(component.failed_count).to eq(0)
      end
    end
  end

  describe "#total_count" do
    context "MusicGenerationが存在する場合" do
      before do
        create_list(:music_generation, 2, content: content, status: :pending)
        create_list(:music_generation, 3, content: content, status: :completed)
      end

      it "全件数を返す" do
        expect(component.total_count).to eq(5)
      end
    end

    context "MusicGenerationが存在しない場合" do
      it "0を返す" do
        expect(component.total_count).to eq(0)
      end
    end
  end

  describe "#status_config" do
    it "各ステータスの表示設定を返す" do
      config = component.status_config

      expect(config[:pending]).to include(
        label: "待機中",
        icon: "clock",
        color_class: "text-gray-500 bg-gray-100"
      )

      expect(config[:processing]).to include(
        label: "処理中",
        icon: "spinner",
        color_class: "text-yellow-600 bg-yellow-100"
      )

      expect(config[:completed]).to include(
        label: "完了",
        icon: "check-circle",
        color_class: "text-green-600 bg-green-100"
      )

      expect(config[:failed]).to include(
        label: "失敗",
        icon: "exclamation-circle",
        color_class: "text-red-600 bg-red-100"
      )
    end
  end

  describe "rendering" do
    it "コンポーネントが正常にレンダリングされる" do
      render_inline(component)
      expect(page).to have_css(".music-generation-status-summary")
    end

    it "各ステータスの件数が表示される" do
      create(:music_generation, content: content, status: :pending)
      create_list(:music_generation, 2, content: content, status: :processing)
      create_list(:music_generation, 3, content: content, status: :completed)

      render_inline(component)

      expect(page).to have_text("待機中: 1件")
      expect(page).to have_text("処理中: 2件")
      expect(page).to have_text("完了: 3件")
    end

    it "0件のステータスも表示される" do
      create(:music_generation, content: content, status: :completed)

      render_inline(component)

      expect(page).to have_text("待機中: 0件")
      expect(page).to have_text("処理中: 0件")
      expect(page).to have_text("完了: 1件")
      expect(page).to have_text("失敗: 0件")
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe MusicGenerationTable::Component, type: :component do
  let(:music_generations) { MusicGeneration.none }
  let(:show_pagination) { true }
  let(:empty_message) { nil }
  let(:component) do
    params = {
      music_generations: music_generations,
      show_pagination: show_pagination
    }
    params[:empty_message] = empty_message if empty_message
    described_class.new(**params)
  end

  describe "初期化" do
    context "必須パラメータのみの場合" do
      let(:component) { described_class.new(music_generations: music_generations) }

      it "デフォルト値が設定される" do
        expect(component.show_pagination).to be true
        expect(component.empty_message).to eq "音楽生成リクエストがありません"
      end
    end

    context "オプションパラメータを指定した場合" do
      let(:show_pagination) { false }
      let(:empty_message) { "カスタムメッセージ" }

      it "指定した値が設定される" do
        expect(component.show_pagination).to be false
        expect(component.empty_message).to eq "カスタムメッセージ"
      end
    end
  end

  describe "Track単位表示" do
    let(:content) { create(:content) }

    context "複数のMusicGenerationとTracksがある場合" do
      let!(:music_generation1) { create(:music_generation, content: content, status: :completed) }
      let!(:music_generation2) { create(:music_generation, content: content, status: :completed) }
      let!(:track1_1) { create(:track, music_generation: music_generation1, content: content, status: :completed, duration_sec: 180, created_at: 1.hour.ago) }
      let!(:track1_2) { create(:track, music_generation: music_generation1, content: content, status: :completed, duration_sec: 200, created_at: 30.minutes.ago) }
      let!(:track2_1) { create(:track, music_generation: music_generation2, content: content, status: :completed, duration_sec: 150, created_at: 10.minutes.ago) }

      let(:music_generations) { MusicGeneration.includes(:tracks).order(created_at: :desc) }
      let(:component) { described_class.new(music_generations: music_generations) }
      let(:rendered) { render_inline(component) }

      it "全てのTrackが個別の行として表示される" do
        # Track番号が作成日時順で表示されることを確認
        # MusicGeneration1に2つ、MusicGeneration2に1つあるため
        expect(rendered).to have_css("td", text: "#1", count: 2)  # 各MusicGenerationで#1が存在
        expect(rendered).to have_css("td", text: "#2", count: 1)  # MusicGeneration1にのみ#2が存在
      end

      it "Track番号が作成日時順で正しく付与される" do
        # Track番号が各Track行に正しい順序で表示されることを確認
        # MusicGeneration1のTrack
        track_row_1_1 = rendered.at_css("tr[data-track-id='#{track1_1.id}']")
        expect(track_row_1_1).to have_content("#1")

        track_row_1_2 = rendered.at_css("tr[data-track-id='#{track1_2.id}']")
        expect(track_row_1_2).to have_content("#2")

        # MusicGeneration2のTrack
        track_row_2_1 = rendered.at_css("tr[data-track-id='#{track2_1.id}']")
        expect(track_row_2_1).to have_content("#1")
      end

      it "MusicGenerationのIDが各Track行に表示されない" do
        # 生成リクエストIDが表示されないことを確認
        expect(rendered).not_to have_content("生成リクエストID")
      end

      it "各Trackの曲の長さが適切に表示される" do
        # duration_secが適切にフォーマットされて表示される
        expect(rendered).to have_content("3:00") # track1_1: 180秒
        expect(rendered).to have_content("3:20") # track1_2: 200秒
        expect(rendered).to have_content("2:30") # track2_1: 150秒
      end

      it "同一MusicGenerationのTrackがグループ化されて表示される" do
        # グループ化用のdata属性が適用されることを確認
        expect(rendered).to have_css("tr[data-generation-id='#{music_generation1.id}']", count: 2)
        expect(rendered).to have_css("tr[data-generation-id='#{music_generation2.id}']", count: 1)
      end
    end

    context "MusicGenerationにTrackがない場合" do
      let!(:music_generation) { create(:music_generation, content: content, status: :failed) }
      let(:music_generations) { MusicGeneration.includes(:tracks).where(id: music_generation.id) }
      let(:component) { described_class.new(music_generations: music_generations) }
      let(:rendered) { render_inline(component) }

      it "MusicGenerationのみ表示されTrackなしのメッセージが表示される" do
        expect(rendered).to have_css("[data-generation-id='#{music_generation.id}']")
        expect(rendered).to have_content("Trackがありません")
      end
    end
  end

  describe "レンダリング" do
    subject { rendered_content }
    let(:rendered_content) { render_inline(component) }

    context "Track単位でテーブル表示される場合" do
      let(:content) { create(:content) }
      let!(:music_generation1) { create(:music_generation, content: content, status: :completed) }
      let!(:track1) { create(:track, music_generation: music_generation1, content: content) }
      let!(:track2) { create(:track, music_generation: music_generation1, content: content) }
      let(:music_generations) { MusicGeneration.includes(:tracks).where(id: music_generation1.id) }

      it "テーブルが表示される" do
        expect(subject).to have_css("table.min-w-full")
      end

      it "Track単位用のヘッダー行が表示される" do
        expect(subject).not_to have_css("thead tr th", text: "生成リクエストID")
        expect(subject).not_to have_css("thead tr th", text: "Track ID")
        expect(subject).to have_css("thead tr th", text: "Track No.")
        expect(subject).to have_css("thead tr th", text: "曲の長さ")
        expect(subject).to have_css("thead tr th", text: "プレイヤー")
        expect(subject).to have_css("thead tr th", text: "アクション")
      end

      it "Track単位で行が表示される" do
        expect(subject).to have_css("tbody tr", count: 2)
        expect(subject).to have_css("tbody tr[data-track-id='#{track1.id}']")
        expect(subject).to have_css("tbody tr[data-track-id='#{track2.id}']")
      end

      it "テーブルに固定高さとスクロール設定が適用される" do
        expect(subject).to have_css(".max-h-96.overflow-y-auto")
      end
    end

    context "MusicGenerationが空の場合" do
      let(:music_generations) { MusicGeneration.none }

      it "空状態メッセージが表示される" do
        expect(subject).to have_css(".empty-state")
        expect(subject).to have_text("音楽生成リクエストがありません")
      end

      it "テーブルが表示されない" do
        expect(subject).not_to have_css("table")
      end

      context "カスタムメッセージを指定した場合" do
        let(:empty_message) { "生成リクエストがまだありません" }

        it "カスタムメッセージが表示される" do
          expect(subject).to have_css(".empty-state")
          expect(subject).to have_text("生成リクエストがまだありません")
        end
      end
    end

    context "ページネーション表示" do
      let(:content) { create(:content) }
      let(:music_generations) { MusicGeneration.where(content: content).page(1) }

      before do
        create_list(:music_generation, 35, content: content)
      end

      context "show_paginationがtrueの場合" do
        let(:show_pagination) { true }

        it "ページネーション領域が表示される" do
          allow_any_instance_of(MusicGenerationTable::Component).to receive(:paginate).and_return("<div class='pagination'>paginated</div>".html_safe)
          expect(subject).to have_css(".pagination-wrapper")
        end
      end

      context "show_paginationがfalseの場合" do
        let(:show_pagination) { false }

        it "ページネーション領域が表示されない" do
          expect(subject).not_to have_css(".pagination-wrapper")
        end
      end
    end

    context "レスポンシブ対応" do
      let(:content) { create(:content) }
      let(:music_generation) { create(:music_generation, content: content) }
      let(:music_generations) { MusicGeneration.where(id: music_generation.id) }

      it "縦スクロール可能なコンテナに含まれる" do
        expect(subject).to have_css(".overflow-y-auto")
      end
    end

    context "アクセシビリティ" do
      let(:content) { create(:content) }
      let(:music_generation) { create(:music_generation, content: content) }
      let(:music_generations) { MusicGeneration.where(id: music_generation.id) }

      it "ヘッダーセルにscope属性が設定される" do
        expect(subject).to have_css('th[scope="col"]')
      end
    end
  end
end

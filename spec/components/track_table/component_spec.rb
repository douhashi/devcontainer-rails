# frozen_string_literal: true

require "rails_helper"

RSpec.describe TrackTable::Component, type: :component do
  let(:tracks) { Track.none }
  let(:show_pagination) { true }
  let(:show_content_column) { true }
  let(:empty_message) { nil }
  let(:component) do
    params = {
      tracks: tracks,
      show_pagination: show_pagination,
      show_content_column: show_content_column
    }
    params[:empty_message] = empty_message if empty_message
    described_class.new(**params)
  end

  describe "初期化" do
    context "必須パラメータのみの場合" do
      let(:component) { described_class.new(tracks: tracks) }

      it "デフォルト値が設定される" do
        expect(component.show_pagination).to be true
        expect(component.show_content_column).to be true
        expect(component.empty_message).to eq "データがありません"
      end
    end

    context "オプションパラメータを指定した場合" do
      let(:show_pagination) { false }
      let(:show_content_column) { false }
      let(:empty_message) { "カスタムメッセージ" }

      it "指定した値が設定される" do
        expect(component.show_pagination).to be false
        expect(component.show_content_column).to be false
        expect(component.empty_message).to eq "カスタムメッセージ"
      end
    end
  end

  describe "レンダリング" do
    subject { rendered_content }
    let(:rendered_content) { render_inline(component) }

    context "Trackが存在する場合" do
      let(:content) { create(:content) }
      let(:track1) { create(:track, content: content, metadata: { "music_title" => "Track 1" }) }
      let(:track2) { create(:track, content: content, metadata: { "music_title" => "Track 2" }) }
      let(:tracks) { Track.where(id: [ track1.id, track2.id ]) }

      it "テーブルが表示される" do
        expect(subject).to have_css("table.min-w-full")
      end

      it "ヘッダー行が表示される" do
        expect(subject).to have_css("thead tr th", text: "ID")
        expect(subject).to have_css("thead tr th", text: "タイトル")
        expect(subject).not_to have_css("thead tr th", text: "ステータス")
        expect(subject).to have_css("thead tr th", text: "作成日時")
        expect(subject).to have_css("thead tr th", text: "プレイヤー")
      end

      it "Content列が表示される" do
        expect(subject).to have_css("thead tr th", text: "Content")
      end

      it "Track行が表示される" do
        expect(subject).to have_css("tbody tr", count: 2)
        expect(subject).to have_css("tbody tr#track_#{track1.id}")
        expect(subject).to have_css("tbody tr#track_#{track2.id}")
      end

      context "show_content_columnがfalseの場合" do
        let(:show_content_column) { false }

        it "Content列が表示されない" do
          expect(subject).not_to have_css("thead tr th", text: "Content")
        end
      end
    end

    context "Trackが空の場合" do
      let(:tracks) { Track.none }

      it "空状態メッセージが表示される" do
        expect(subject).to have_css(".empty-state")
        expect(subject).to have_text("データがありません")
      end

      it "テーブルが表示されない" do
        expect(subject).not_to have_css("table")
      end

      context "カスタムメッセージを指定した場合" do
        let(:empty_message) { "Trackがまだありません" }

        it "カスタムメッセージが表示される" do
          expect(subject).to have_css(".empty-state")
          expect(subject).to have_text("Trackがまだありません")
        end
      end
    end

    context "ページネーション表示" do
      let(:content) { create(:content) }
      let(:tracks) { Track.where(content: content).page(1) }

      before do
        create_list(:track, 35, content: content)
      end

      context "show_paginationがtrueの場合" do
        let(:show_pagination) { true }

        it "ページネーション領域が表示される" do
          # paginateメソッドをモック
          allow_any_instance_of(TrackTable::Component).to receive(:paginate).and_return("<div class='pagination'>paginated</div>".html_safe)
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
      let(:track) { create(:track, content: content) }
      let(:tracks) { Track.where(id: track.id) }

      it "横スクロール可能なコンテナに含まれる" do
        expect(subject).to have_css(".overflow-x-auto")
      end
    end

    context "アクセシビリティ" do
      let(:content) { create(:content) }
      let(:track) { create(:track, content: content) }
      let(:tracks) { Track.where(id: track.id) }

      it "ヘッダーセルにscope属性が設定される" do
        expect(subject).to have_css('th[scope="col"]')
      end
    end
  end

  describe "TrackRow::Componentとの統合" do
    let(:content) { create(:content) }
    let(:track) { create(:track, content: content, metadata: { "music_title" => "Test Track" }) }
    let(:tracks) { Track.where(id: track.id) }
    let(:rendered_content) { render_inline(component) }

    it "TrackRow::Componentが使用される" do
      allow(TrackRow::Component).to receive(:new).with(track: track, show_content_column: show_content_column).and_call_original
      rendered_content
      expect(TrackRow::Component).to have_received(:new).with(track: track, show_content_column: show_content_column)
    end
  end
end

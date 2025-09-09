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

  describe "レンダリング" do
    subject { rendered_content }
    let(:rendered_content) { render_inline(component) }

    context "MusicGenerationが存在する場合" do
      let(:content) { create(:content) }
      let(:music_generation1) { create(:music_generation, content: content, status: :completed) }
      let(:music_generation2) { create(:music_generation, content: content, status: :pending) }
      let(:music_generations) { MusicGeneration.where(id: [ music_generation1.id, music_generation2.id ]) }

      it "テーブルが表示される" do
        expect(subject).to have_css("table.min-w-full")
      end

      it "ヘッダー行が表示される" do
        expect(subject).to have_css("thead tr th", text: "ID")
        expect(subject).to have_css("thead tr th", text: "ステータス")
        expect(subject).to have_css("thead tr th", text: "曲の長さ")
        expect(subject).to have_css("thead tr th", text: "Track数")
        expect(subject).to have_css("thead tr th", text: "作成日時")
        expect(subject).to have_css("thead tr th", text: "アクション")
      end

      it "MusicGeneration行が表示される" do
        expect(subject).to have_css("tbody tr", count: 2)
        expect(subject).to have_css("tbody tr#music_generation_#{music_generation1.id}")
        expect(subject).to have_css("tbody tr#music_generation_#{music_generation2.id}")
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

      it "横スクロール可能なコンテナに含まれる" do
        expect(subject).to have_css(".overflow-x-auto")
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

  describe "MusicGenerationRow::Componentとの統合" do
    let(:content) { create(:content) }
    let(:music_generation) { create(:music_generation, content: content) }
    let(:music_generations) { MusicGeneration.where(id: music_generation.id) }
    let(:rendered_content) { render_inline(component) }

    it "MusicGenerationRow::Componentが使用される" do
      allow(MusicGenerationRow::Component).to receive(:new).with(music_generation: music_generation).and_call_original
      rendered_content
      expect(MusicGenerationRow::Component).to have_received(:new).with(music_generation: music_generation)
    end
  end
end

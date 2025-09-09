# frozen_string_literal: true

require "rails_helper"

RSpec.describe MusicGenerationCard::Component, type: :component do
  let(:content) { create(:content) }
  let(:music_generation) { create(:music_generation, content: content, status: status, created_at: 1.hour.ago) }
  let(:component) { described_class.new(music_generation: music_generation) }

  before do
    create_list(:track, 2, music_generation: music_generation)
  end

  describe "#card_title" do
    let(:status) { :processing }

    it "returns formatted title with generation ID" do
      expect(component.card_title).to eq("生成リクエスト ##{music_generation.id}")
    end
  end

  describe "#formatted_created_at" do
    let(:status) { :completed }

    it "returns formatted datetime" do
      expect(component.formatted_created_at).to match(/\d{4}年\d{1,2}月\d{1,2}日 \d{1,2}:\d{2}/)
    end
  end

  describe "#has_tracks?" do
    context "when tracks exist" do
      let(:status) { :completed }

      it "returns true" do
        expect(component.has_tracks?).to be true
      end
    end

    context "when no tracks exist" do
      let(:status) { :pending }

      before do
        music_generation.tracks.destroy_all
      end

      it "returns false" do
        expect(component.has_tracks?).to be false
      end
    end
  end

  describe "#waiting_message" do
    context "when status is pending" do
      let(:status) { :pending }

      it "returns pending message" do
        expect(component.waiting_message).to eq("音楽生成の開始を待っています...")
      end
    end

    context "when status is processing" do
      let(:status) { :processing }

      it "returns processing message" do
        expect(component.waiting_message).to eq("音楽を生成中です...")
      end
    end

    context "when status is failed" do
      let(:status) { :failed }

      it "returns error message" do
        expect(component.waiting_message).to eq("生成中にエラーが発生しました")
      end
    end

    context "when status is completed" do
      let(:status) { :completed }

      it "returns nil" do
        expect(component.waiting_message).to be_nil
      end
    end
  end

  describe "rendering" do
    context "when status is completed with tracks" do
      let(:status) { :completed }

      it "renders card with tracks table" do
        render_inline(component)

        expect(page).to have_text("生成リクエスト ##{music_generation.id}")
        expect(page).to have_text("完了")
        expect(page).to have_css("table")
        expect(page).to have_text("ID")
        expect(page).to have_text("タイトル")
        expect(page).to have_text("ステータス")
      end
    end

    context "when status is processing" do
      let(:status) { :processing }

      it "renders card with waiting message" do
        render_inline(component)

        expect(page).to have_text("生成リクエスト ##{music_generation.id}")
        expect(page).to have_text("処理中")
        expect(page).to have_text("音楽を生成中です...")
        expect(page).not_to have_css("table")
      end
    end

    context "when status is failed" do
      let(:status) { :failed }

      it "renders card with error message" do
        render_inline(component)

        expect(page).to have_text("生成リクエスト ##{music_generation.id}")
        expect(page).to have_text("失敗")
        expect(page).to have_text("生成中にエラーが発生しました")
        expect(page).not_to have_css("table")
      end
    end

    context "responsive design" do
      let(:status) { :completed }

      it "has responsive classes" do
        render_inline(component)

        expect(page).to have_css(".bg-gray-800")
        expect(page).to have_css(".rounded-xl")
        expect(page).to have_css(".shadow-lg")
      end
    end

    context "dark mode styling" do
      let(:status) { :completed }

      it "has dark mode background classes" do
        render_inline(component)

        expect(page).to have_css(".bg-gray-800")
        expect(page).to have_css(".rounded-xl")
        expect(page).to have_css(".shadow-lg")
      end

      it "has dark mode text classes" do
        render_inline(component)

        expect(page).to have_css(".text-gray-100")
        expect(page).to have_css(".text-gray-300")
        expect(page).to have_css(".border-gray-700")
      end

      it "has dark mode delete button classes" do
        render_inline(component)

        expect(page).to have_css(".text-red-400")
        expect(page).to have_css(".bg-red-900\\/20")
        expect(page).to have_css(".border-red-800")
      end
    end

    context "dark mode for different states" do
      context "when processing" do
        let(:status) { :processing }

        it "has appropriate dark mode classes for processing state" do
          render_inline(component)

          expect(page).to have_css(".text-yellow-400")
          expect(page).to have_css(".text-gray-300")
        end
      end

      context "when failed" do
        let(:status) { :failed }

        it "has appropriate dark mode classes for failed state" do
          render_inline(component)

          expect(page).to have_css(".text-red-400")
        end
      end

      context "when no tracks" do
        let(:status) { :completed }

        before do
          music_generation.tracks.destroy_all
        end

        it "has appropriate dark mode classes for empty state" do
          render_inline(component)

          expect(page).to have_css(".text-gray-400")
        end
      end
    end
  end
end

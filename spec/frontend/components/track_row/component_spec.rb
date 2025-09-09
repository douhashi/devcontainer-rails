# frozen_string_literal: true

require "rails_helper"

RSpec.describe TrackRow::Component, type: :component do
  let(:track) { build(:track, id: 123, status: status, content: nil, created_at: Time.zone.parse("2025-01-15 10:30:00")) }
  let(:component) { described_class.new(track: track) }

  describe "rendering" do
    context "with pending status track" do
      let(:status) { :pending }

      it "renders track row with correct ID and hover behavior" do
        render_inline(component)

        expect(page).to have_css('tr#track_123.track.hover\\:bg-gray-700.transition-colors')
        expect(page).to have_text("#123")
        expect(page).to have_text("生成中...")
      end

      it "includes TrackStatusBadge component" do
        render_inline(component)

        expect(page).to have_text("待機中")
        expect(page).to have_css("span.bg-gray-600.text-gray-200")
      end

      it "displays formatted creation date" do
        render_inline(component)

        expect(page).to have_text("15 Jan 10:30")
      end

      it "shows placeholder for player when not completed" do
        render_inline(component)

        expect(page).to have_css('td', text: "-")
      end
    end

    context "with processing status track" do
      let(:status) { :processing }

      it "shows processing indicator in player column" do
        render_inline(component)

        expect(page).to have_text("処理中...")
        expect(page).to have_css("span.text-yellow-400")
      end
    end

    context "with completed status track" do
      let(:status) { :completed }
      let(:track) { build(:track, id: 123, status: status, content: nil, created_at: Time.zone.parse("2025-01-15 10:30:00")) }

      context "when audio is present" do
        before do
          # Mock audio attachment presence with url method
          audio_mock = double("audio", present?: true, url: "https://example.com/test.mp3")
          allow(track).to receive(:audio).and_return(audio_mock)
        end

        it "renders PlayButton component" do
          render_inline(component)

          # PlayButton::Componentがレンダリングされることを確認
          expect(page).to have_css('button[onclick]')
          expect(page).to have_css('button svg')
        end
      end

      context "when audio is not present" do
        before do
          allow(track).to receive(:audio).and_return(double("audio", present?: false))
        end

        it "shows no audio message" do
          render_inline(component)

          expect(page).to have_text("音声なし")
          expect(page).to have_css("span.text-gray-500")
        end
      end
    end

    context "with failed status track" do
      let(:status) { :failed }

      it "shows placeholder for failed tracks" do
        render_inline(component)

        expect(page).to have_css('td', text: "-")
      end
    end
  end

  describe "content handling" do
    let(:status) { :pending }
    let(:content) { create(:content, theme: "テストテーマ") }

    context "when track has content" do
      let(:track) { build(:track, id: 123, status: status, content: content, created_at: Time.zone.parse("2025-01-15 10:30:00")) }

      it "renders content link with theme" do
        render_inline(component)

        expect(page).to have_link("テストテーマ", href: "/contents/#{content.id}")
        expect(page).to have_css("a.text-blue-400.hover\\:text-blue-300.hover\\:underline")
      end
    end

    context "when track has no content" do
      let(:track) { build(:track, id: 123, status: status, content: nil, created_at: Time.zone.parse("2025-01-15 10:30:00")) }

      it "shows placeholder dash" do
        render_inline(component)

        expect(page).to have_css('td span.text-gray-500', text: "-")
      end
    end
  end

  describe "metadata handling" do
    let(:status) { :pending }

    context "when track has metadata_title" do
      let(:track) { build(:track, id: 123, status: status, content: nil, created_at: Time.zone.parse("2025-01-15 10:30:00")) }

      before do
        allow(track).to receive(:metadata_title).and_return("カスタムタイトル")
      end

      it "displays the metadata title" do
        render_inline(component)

        expect(page).to have_text("カスタムタイトル")
      end
    end

    context "when track has no metadata_title" do
      let(:track) { build(:track, id: 123, status: status, content: nil, created_at: Time.zone.parse("2025-01-15 10:30:00")) }

      before do
        allow(track).to receive(:metadata_title).and_return(nil)
      end

      it "shows generating message" do
        render_inline(component)

        expect(page).to have_text("生成中...")
      end
    end
  end

  describe "turbo frame integration" do
    let(:status) { :pending }

    it "sets correct DOM ID for turbo streams" do
      render_inline(component)

      expect(page).to have_css('tr#track_123')
    end

    it "includes necessary CSS classes for styling" do
      render_inline(component)

      expect(page).to have_css('tr.track.hover\\:bg-gray-700.transition-colors')
    end
  end

  describe "accessibility" do
    let(:status) { :pending }

    it "maintains semantic table structure" do
      render_inline(component)

      expect(page).to have_css('tr')
      expect(page).to have_css('td', count: 6) # ID, タイトル, Content, ステータス, 作成日時, プレイヤー
    end

    it "preserves text color classes for readability" do
      render_inline(component)

      expect(page).to have_css('td.text-gray-300', text: /#123/)
      expect(page).to have_css('td.text-gray-100') # Title column
      expect(page).to have_css('td.text-gray-300') # Date column
    end
  end
end

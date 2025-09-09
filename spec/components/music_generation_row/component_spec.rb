# frozen_string_literal: true

require "rails_helper"

RSpec.describe MusicGenerationRow::Component, type: :component do
  let(:content) { create(:content) }
  let(:music_generation) { create(:music_generation, content: content, status: status) }
  let(:status) { :completed }
  let(:component) { described_class.new(music_generation: music_generation) }

  describe "初期化" do
    it "music_generationが設定される" do
      expect(component.music_generation).to eq music_generation
    end
  end

  describe "レンダリング" do
    subject { rendered_content }
    let(:rendered_content) { render_inline(component) }

    context "基本的な表示" do
      it "テーブル行が表示される" do
        expect(subject).to have_css("tr#music_generation_#{music_generation.id}")
      end

      it "IDが表示される" do
        expect(subject).to have_css("td", text: "##{music_generation.id}")
      end

      it "ステータスバッジが表示される" do
        expect(subject).to have_css("td span.px-2")
      end

      it "作成日時が表示される" do
        formatted_date = I18n.l(music_generation.created_at, format: :short)
        expect(subject).to have_css("td", text: formatted_date)
      end

      it "削除ボタンが表示される" do
        expect(subject).to have_css("button[data-method='delete']")
      end
    end

    context "曲の長さ表示" do
      context "関連するTracksがある場合" do
        let!(:track1) { create(:track, music_generation: music_generation, duration_sec: 120) }
        let!(:track2) { create(:track, music_generation: music_generation, duration_sec: 180) }

        it "合計時間がMM:SS形式で表示される" do
          expect(subject).to have_css("td", text: "5:00")
        end
      end

      context "関連するTracksがない場合" do
        it "-が表示される" do
          expect(subject).to have_css("td", text: "-")
        end
      end

      context "duration_secがnilのTracksがある場合" do
        let!(:track1) { create(:track, music_generation: music_generation, duration_sec: 120) }
        let!(:track2) { create(:track, music_generation: music_generation, duration_sec: nil) }

        it "nilでないTrackのみの合計時間が表示される" do
          expect(subject).to have_css("td", text: "2:00")
        end
      end
    end

    context "Track数表示" do
      context "関連するTracksがある場合" do
        let!(:track1) { create(:track, music_generation: music_generation) }
        let!(:track2) { create(:track, music_generation: music_generation) }

        it "Track数が表示される" do
          expect(subject).to have_css("td", text: "2")
        end
      end

      context "関連するTracksがない場合" do
        it "0が表示される" do
          expect(subject).to have_css("td", text: "0")
        end
      end
    end

    context "ステータス別表示" do
      %i[pending processing completed failed].each do |test_status|
        context "ステータスが#{test_status}の場合" do
          let(:status) { test_status }

          it "ステータスバッジが表示される" do
            expect(subject).to have_css("span.px-2")
          end
        end
      end
    end

    context "削除ボタン" do
      it "正しいURLが設定される" do
        expected_path = Rails.application.routes.url_helpers.content_music_generation_path(
          music_generation.content,
          music_generation
        )
        expect(subject).to have_css("form[action='#{expected_path}']")
      end

      it "削除確認メッセージが設定される" do
        expect(subject).to have_css("button[data-turbo-confirm]")
      end

      it "Turbo Frame属性が設定される" do
        expect(subject).to have_css("form[data-turbo-frame]")
      end
    end

    context "ホバー効果" do
      it "hover効果のクラスが設定される" do
        expect(subject).to have_css("tr.hover\\:bg-gray-700")
      end
    end
  end

  describe "ヘルパーメソッド" do
    describe "#formatted_total_duration" do
      context "関連するTracksがある場合" do
        let!(:track1) { create(:track, music_generation: music_generation, duration_sec: 65) }
        let!(:track2) { create(:track, music_generation: music_generation, duration_sec: 135) }

        it "合計時間をMM:SS形式で返す" do
          expect(component.send(:formatted_total_duration)).to eq "3:20"
        end
      end

      context "関連するTracksがない場合" do
        it "-を返す" do
          expect(component.send(:formatted_total_duration)).to eq "-"
        end
      end

      context "時間が1時間を超える場合" do
        let!(:track1) { create(:track, music_generation: music_generation, duration_sec: 3665) }

        it "H:MM:SS形式で返す" do
          expect(component.send(:formatted_total_duration)).to eq "1:01:05"
        end
      end
    end

    describe "#tracks_count" do
      context "関連するTracksがある場合" do
        let!(:track1) { create(:track, music_generation: music_generation) }
        let!(:track2) { create(:track, music_generation: music_generation) }

        it "正しいTrack数を返す" do
          expect(component.send(:tracks_count)).to eq 2
        end
      end

      context "関連するTracksがない場合" do
        it "0を返す" do
          expect(component.send(:tracks_count)).to eq 0
        end
      end
    end

    describe "#dom_id" do
      it "正しいDOM IDを返す" do
        expect(component.send(:dom_id)).to eq "music_generation_#{music_generation.id}"
      end
    end

    describe "#formatted_created_at" do
      it "正しい日時形式を返す" do
        expected = I18n.l(music_generation.created_at, format: :short)
        expect(component.send(:formatted_created_at)).to eq expected
      end
    end
  end
end

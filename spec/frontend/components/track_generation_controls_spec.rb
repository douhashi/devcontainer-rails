# frozen_string_literal: true

require "rails_helper"

RSpec.describe TrackGenerationControls::Component, type: :component do
  let(:content) { create(:content) }
  let(:can_generate) { true }
  let(:component) { described_class.new(content_record: content, can_generate_more: can_generate) }

  describe "button display" do
    context "when generation is allowed" do
      let(:can_generate) { true }

      it "displays both generation buttons" do
        render_inline(component)

        expect(page).to have_css(".generation-controls")
        expect(page).to have_button("1件生成")
        expect(page).to have_button("一括生成")
        expect(page).not_to have_css("button[disabled]")
      end

      it "includes proper data attributes for single generation" do
        render_inline(component)

        single_button = page.find("button", text: "1件生成")
        expect(single_button["data-turbo-method"]).to eq("post")
      end

      it "includes proper data attributes for bulk generation" do
        render_inline(component)

        bulk_button = page.find("button", text: "一括生成")
        expect(bulk_button["data-turbo-method"]).to eq("post")
      end
    end

    context "when generation is not allowed" do
      let(:can_generate) { false }

      it "displays enabled buttons (restriction removed)" do
        render_inline(component)

        # Buttons are now always enabled, regardless of can_generate_more parameter
        expect(page).not_to have_css("button[disabled]")
        expect(page).not_to have_text("生成上限に達しました")
      end
    end
  end

  describe "button styling" do
    it "applies different styles to each button" do
      render_inline(component)

      single_button = page.find("button", text: "1件生成")
      bulk_button = page.find("button", text: "一括生成")

      expect(single_button[:class]).to include("bg-blue-600")
      expect(bulk_button[:class]).to include("bg-green-600")
    end
  end

  describe "#single_generation_path" do
    it "returns correct path for single track generation" do
      render_inline(component)
      form = page.find('form', text: '1件生成')
      expect(form['action']).to include("/contents/#{content.id}/tracks/generate_single")
    end
  end

  describe "#bulk_generation_path" do
    it "returns correct path for bulk track generation" do
      render_inline(component)
      form = page.find('form', text: '一括生成')
      expect(form['action']).to include("/contents/#{content.id}/tracks/generate_bulk")
    end
  end

  describe "#required_music_generation_count" do
    context "when duration_min is set" do
      it "calculates the correct count for 10 minutes" do
        content.update!(duration_min: 10)
        expect(component.required_music_generation_count).to eq(7) # (10/6) + 5 = 1.67 + 5 = 6.67 => 7
      end

      it "calculates the correct count for 60 minutes" do
        content.update!(duration_min: 60)
        expect(component.required_music_generation_count).to eq(15) # (60/6) + 5 = 10 + 5 = 15
      end

      it "calculates the correct count for 120 minutes" do
        content.update!(duration_min: 120)
        expect(component.required_music_generation_count).to eq(25) # (120/6) + 5 = 20 + 5 = 25
      end
    end


    context "when duration_min is 0" do
      it "returns 0" do
        content.update_column(:duration_min, 0)  # Skip validation
        expect(component.required_music_generation_count).to eq(0)
      end
    end
  end

  describe "#required_track_count" do
    context "when duration_min is set" do
      it "returns twice the music generation count" do
        content.update!(duration_min: 60)
        expect(component.required_track_count).to eq(30) # 15 * 2 = 30
      end
    end
  end

  describe "dynamic count display" do
    context "when duration_min is set" do
      before { content.update!(duration_min: 60) }

      it "displays dynamic count in bulk generation button" do
        render_inline(component)
        expect(page).to have_text("一括生成")
        expect(page).to have_text("(15件)")
      end

      it "displays dynamic count in description text" do
        render_inline(component)
        expect(page).to have_text("音楽生成を15件追加します（Track 30件が生成されます）")
      end
    end

    context "when duration_min is 0" do
      before { content.update_column(:duration_min, 0) }  # Skip validation

      it "displays appropriate message for zero count" do
        render_inline(component)
        expect(page).to have_text("一括生成")
        expect(page).to have_text("(0件)")
        expect(page).to have_text("音楽生成を0件追加します（Track 0件が生成されます）")
      end
    end
  end
end

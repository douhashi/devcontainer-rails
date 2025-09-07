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

      it "displays disabled buttons" do
        render_inline(component)

        expect(page).to have_css("button[disabled]", count: 2)
        expect(page).to have_text("生成上限に達しました")
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
end

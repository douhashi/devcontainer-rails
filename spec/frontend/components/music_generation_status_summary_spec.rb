# frozen_string_literal: true

require "rails_helper"

RSpec.describe MusicGenerationStatusSummary::Component, type: :component do
  let(:content) { create(:content, duration_min: 10) }
  let(:options) { { content_record: content } }
  let(:component) { MusicGenerationStatusSummary::Component.new(**options) }

  subject { rendered_content }

  it "renders" do
    render_inline(component)

    is_expected.to have_css "div.music-generation-status-summary"
  end

  describe "CSS classes" do
    before { render_inline(component) }

    it "does not have unnecessary background styling on wrapper" do
      is_expected.not_to have_css "div.music-generation-status-summary.bg-gray-50"
    end

    it "does not have unnecessary padding on wrapper" do
      is_expected.not_to have_css "div.music-generation-status-summary.p-4"
    end

    it "does not have unnecessary rounded corners on wrapper" do
      is_expected.not_to have_css "div.music-generation-status-summary.rounded-lg"
    end

    it "maintains proper margin on wrapper" do
      is_expected.to have_css "div.music-generation-status-summary.mt-4"
    end
  end
end

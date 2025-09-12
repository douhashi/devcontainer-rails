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
end

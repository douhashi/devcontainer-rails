# frozen_string_literal: true

require "rails_helper"

RSpec.describe VideoGenerationButton::Component, type: :component do
  include ViewComponent::TestHelpers
  include ViewComponent::SystemTestHelpers
  let(:content_record) { create(:content) }
  let(:component) { VideoGenerationButton::Component.new(content_record: content_record) }

  subject { rendered_content }

  it "renders" do
    render_inline(component)

    is_expected.to have_css "div"
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Content::Card::Component, type: :component do
  include ViewComponent::TestHelpers
  include ViewComponent::SystemTestHelpers
  let(:content) { create(:content) }
  let(:options) { { item: content } }
  let(:component) { Content::Card::Component.new(**options) }

  subject { rendered_content }

  it "renders" do
    render_inline(component)

    is_expected.to have_css "div"
  end
end

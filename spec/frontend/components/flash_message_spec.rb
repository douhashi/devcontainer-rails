# frozen_string_literal: true

require "rails_helper"

RSpec.describe FlashMessage::Component, type: :component do
  include ViewComponent::TestHelpers
  include ViewComponent::SystemTestHelpers
  let(:options) { { type: :notice, message: "Test message" } }
  let(:component) { FlashMessage::Component.new(**options) }

  subject { rendered_content }

  it "renders" do
    render_inline(component)

    is_expected.to have_css "div"
  end
end
